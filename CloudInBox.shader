#include "./lib/simplexNoise3D.glsl"
#include "./lib/CamerasAndCoordinates.glsl"
#include "./lib/Lighting.glsl"
#include "./lib/MathUtils.glsl"
#include "./lib/voronoiNoise.glsl"

#iChannel0 "file://cubemap/StPetersBasilica/StPetersBasilica_{}.jpg"
#iChannel0::Type "CubeMap"
#iChannel0::MinFilter "LinearMipMapLinear"

#define SCENE_MAX_STEPS 10000
// #define MAX_DIST 800.
#define STEP_PRECISION 1e-4 //(0.001)

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
    float roundness;
};

float Box3DDist(vec3 p, Box3D b)
{
    // length is pythag
    // max is clamping the evaluation p
    // abs applies the mirroring
    // p = MouseRotation(p - b.position, 0.0, 0.0);
    // p = p - b.position;
    p = abs(p);
    p -= b.scale;
    
    return length(max(p, 0.)) + min(Max3(p), 0.) - b.roundness;
}

float GetDist(vec3 p)
{

    Box3D box;
    box.position = sceneCentre;
    box.scale = vec3(.75, 0.75, .75);
    box.roundness = 0.05;

    p = MouseRotation(p - box.position, 0.2, 0.5);
    float boxD = Box3DDist(p, box);
    
    float d = boxD; //min(boxD, groundD);
    return d;
}

float GetInternalDist(vec3 p)
{
    Box3D internalBox;
    internalBox.position = sceneCentre;
    internalBox.scale = vec3(.65, 0.65, .65);
    internalBox.roundness = 0.025;

    p = MouseRotation(p - internalBox.position, 0.2, 0.5);
    float internalBoxD = Box3DDist(p, internalBox);
    
    float d = internalBoxD; //min(boxD, groundD);
    return d;
}

vec2 Raymarch(Ray ray, float side)
{
    float distanceFromOrigin = 0.0;
    float maxDist = MAX_DIST;

    for (int i = 0; i < SCENE_MAX_STEPS; i++)
    {
        vec3 p = ray.o + distanceFromOrigin * ray.d;
        float distanceFromSurf = GetDist(p)*side; // need a negative distance when inside the object??
        if (distanceFromSurf < maxDist) maxDist = distanceFromSurf;
        distanceFromOrigin += distanceFromSurf;

        if (distanceFromOrigin > MAX_DIST || abs(distanceFromSurf) < STEP_PRECISION)
            break;
    }

    // returns the distance from the origin and the final distance from the surface
    return vec2(distanceFromOrigin, maxDist);
}

vec2 InternalRaymarch(Ray ray, float side)
{
    float distanceFromOrigin = 0.0;
    float maxDist = MAX_DIST;

    for (int i = 0; i < SCENE_MAX_STEPS; i++)
    {
        vec3 p = ray.o + distanceFromOrigin * ray.d;
        float distanceFromSurf = GetInternalDist(p)*side; // need a negative distance when inside the object??
        if (distanceFromSurf < maxDist) maxDist = distanceFromSurf;
        distanceFromOrigin += distanceFromSurf;

        if (distanceFromOrigin > MAX_DIST || abs(distanceFromSurf) < STEP_PRECISION)
            break;
    }

    // returns the distance from the origin and the final distance from the surface
    return vec2(distanceFromOrigin, maxDist);
}

float RaymarchDensity(vec3 p, Ray ray, float densityScalar)
{
    // so the outline is generated by the density being 0 before the first step
    float density = 0.;

    // start with an offset one precision step backwards
    // this is to help elleviate outline issues around the edge when we mask the sphere
    // do we also need to make sure we are only marching in a forward direction??
    
    for (int i = 0; i < SCENE_MAX_STEPS; i++)
    {
        p += (ray.d * STEP_PRECISION);
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

vec3 SkyBox(vec3 samplePos)
{
    float noiseF = 10.;
    return texture(iChannel0, samplePos).rgb;
    return vec3(voronoi(samplePos * noiseF));
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

    Ray ray;
    ConstructRayFromCamera(cam, uv, ray);
    
    col = SkyBox(ray.d);// this is not spherized

    float distance = Raymarch(ray, 1.).x; // outside of object
    vec3 p = ray.o + ray.d * distance;

    if (distance < MAX_DIST)
    {
        vec3 n = GetNormal(p);
        float diff = DefaultLighting(n);

        vec3 albedo = diff * vec3(.7, .2, .3);

        vec3 reflection = reflect(normalize(ray.d), n);
        
        float IOR = 1.1;
        vec3 refraction = refract(normalize(ray.d), n, 1. / IOR);
        
        // we need to find our internal normals again
        Ray internalRay;
        internalRay.o = p - n * STEP_PRECISION*3.;
        internalRay.d = ray.d;

        float internalDistance = InternalRaymarch(internalRay, 1.).x;
        vec3 internalP = internalRay.o + internalRay.d * internalDistance;
        
        vec3 exitP;
        vec3 exitN;
        float exitDistance;

        if (internalDistance < MAX_DIST)
        {
            vec3 internalN = GetNormal(internalP);
            

            Ray hollowRay;
            hollowRay.o = internalP - n * STEP_PRECISION*3.;
            hollowRay.d = refraction;

            float distanceInside = InternalRaymarch(hollowRay, -1.).x; // inside of object

            exitP = internalRay.o + internalRay.d * distanceInside;
            exitN = -GetNormal(exitP);

            reflection += reflect(normalize(hollowRay.d), exitN); // this probably needs to be refreacted out too

            vec3 exitRefraction = refract(normalize(internalRay.d), exitN, 1./IOR);
            if(dot(exitRefraction, exitRefraction)==0.) exitRefraction = reflect(ray.d, exitN);
            
            internalRay.o = exitP - exitN * STEP_PRECISION*3.;
            internalRay.d = exitRefraction;
        }
        
        exitDistance = Raymarch(internalRay, -1.).x; // inside of object

        exitP = internalRay.o + internalRay.d * exitDistance;
        exitN = -GetNormal(exitP);

            vec3 exitRefraction = refract(normalize(internalRay.d), exitN, IOR);
            if(dot(exitRefraction, exitRefraction)==0.) exitRefraction = reflect(ray.d, exitN);

        col = exitRefraction;
        // vec3 exitRefraction = refract(normalize(internalRay.d), exitN, IOR);
        // if(dot(exitRefraction, exitRefraction)==0.) exitRefraction = reflect(ray.d, exitN);
        
        // col = exitN;

        // float density = RaymarchDensity(p, ray, 0.0125);

        // do we need to do this if we do not hit the internalbox??
        // should we just be raymarching internally against a new box rather than a subtracted dist??

        col = SkyBox(normalize(exitRefraction));
        col += SkyBox(normalize( reflection));
        // col /= 2.;
        col += diff;

        // col = mix(col, albedo, .8);

    }

    // Output to screen
    fragColor = vec4(col, 1.0);
}