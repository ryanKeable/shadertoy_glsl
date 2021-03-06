#include "./lib/simplexNoise3D.glsl"
#include "./lib/CamerasAndCoordinates.glsl"
#include "./lib/Lighting.glsl"
#include "./lib/MathUtils.glsl"

#define SCENE_MAX_STEPS 3000
// #define MAX_DIST 800.
#define STEP_PRECISION 1e-3 //(0.001)

#define TimeSpeed iTime * .1
#define MAX_STEPS 300
#define MAX_DIST 30.
#define SURF_DIST .001

const vec3 sceneCentre = vec3(0., 1.5, 4.);

struct Box3D
{
    vec3 position;
    vec3 scale;
    vec3 rotation;
    vec3 normals;
    vec3 albedo;
};

float Box3DDist(vec3 p, Box3D b)
{
    // length is pythag
    // max is clamping the evaluation p
    // abs applies the mirroring
    p = MouseRotation(p - b.position, 0., 0.);
    p = abs(p);
    p -= b.scale;
    
    return length(max(p, 0.)) + min(Max3(p), 0.);
}

float GetDist(vec3 p)
{
    vec2 m = iMouse.xy / iResolution.xy;

    Box3D box;
    box.position = sceneCentre;
    box.scale = vec3(.75);

    
    float boxD = Box3DDist(p, box);
    float groundD = p.y + 0.00001;
    
    float d = min(boxD, groundD);
    return d;
}

vec2 Raymarch(Camera cam)
{
    float distanceFromOrigin = 0.0;
    float maxDist = MAX_DIST;

    for (int i = 0; i < SCENE_MAX_STEPS; i++)
    {
        vec3 p = cam.pos + distanceFromOrigin * cam.dir;
        float distanceFromSurf = GetDist(p);
        if (distanceFromSurf < maxDist) maxDist = distanceFromSurf;
        distanceFromOrigin += distanceFromSurf;

        if (distanceFromOrigin > MAX_DIST || abs(distanceFromSurf) < STEP_PRECISION)
            break;
    }

    // returns the distance from the origin and the final distance from the surface
    return vec2(distanceFromOrigin, maxDist);
}

float RaymarchDensity(vec3 p, Camera cam, float densityScalar)
{
    // so the outline is generated by the density being 0 before the first step
    float density = 0.;

    // start with an offset one precision step backwards
    // this is to help elleviate outline issues around the edge when we mask the sphere
    // do we also need to make sure we are only marching in a forward direction??
    
    for (int i = 0; i < SCENE_MAX_STEPS; i++)
    {
        p += (cam.dir * STEP_PRECISION);
        float dist = GetDist(p);

        density += (0.1 * densityScalar);

        // stop marching if we are further than when we began or if are too dense
        // what should 5. be as a relationship to the scene?
        if (dist > STEP_PRECISION || density > 5.)
        {
            break;
        }
    }

    // return density;
    return exp(-density);
}
vec3 GetNormal(vec3 p)
{
    float d = GetDist(p);
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p - e.xyy),
        GetDist(p - e.yxy),
        GetDist(p - e.yyx));
    
    return normalize(n);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 m = iMouse.xy / iResolution.xy;
    vec2 uv = InitializeScreenSpace(fragCoord, 0.5);
    vec3 col = vec3(0.0);
    
    Camera cam;
    cam.pos = vec3(0, 2., -3);


    cam.lookAt = sceneCentre;
    cam.zoom = 1.;

    ConstructCamera(uv, cam);
    
    float distance = Raymarch(cam).x;
    
    // AA?
    vec3 p = cam.pos + cam.dir * distance;

    if (distance < MAX_DIST)
    {
        vec3 n = GetNormal(p);
        float diff = DefaultLighting(n);
        float density = RaymarchDensity(p, cam, .02);

        col += diff;

        col = vec3(density);
    }

    // Output to screen
    fragColor = vec4(col, 1.0);
}