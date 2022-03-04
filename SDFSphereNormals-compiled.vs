#define GLSLIFY 1
const vec3 worldUp = vec3(0., 1., 0.);

struct Ray
{
    vec3 o;
    vec3 d;
};

struct Sphere
{
    vec3 pos;
    float radius;
    float fallOff;
};

struct Camera
{
    vec3 f;
    vec3 r;
    vec3 u;
    vec3 pos;
    vec3 rot;
    vec3 lookAt;
    float zoom;
    float fov;
};

float vec3Length(vec3 value)
{
    return sqrt(dot(value, value));
}

float SDF_3D_Sphere(Sphere sphere, vec3 rayOrigin)
{
    vec3 vecToCentre = rayOrigin - sphere.pos;
    float dist = vec3Length(vecToCentre);
    float min = sphere.radius - sphere.fallOff;
    float max = sphere.radius + sphere.fallOff;
    float circle = smoothstep(min, max, dist);

    return circle;
}

float DistLine(vec3 ro, vec3 rd, vec3 p)
{
    vec3 rop = (p - ro);
    return length(cross(rop, rd)) / length(rd);
}

float DrawDisc(Sphere s, Ray r)
{
    float radius = 1. - DistLine(r.o, r.d, s.pos) / (s.radius * 0.5);
    return smoothstep(0.0, 1., radius);
}

void InitializeCamera(vec2 uv, vec3 pos, inout Camera cam)
{
    cam.zoom = 1.;
    cam.pos = pos; // we are just animating the position, we are not truly rotating the camera
    cam.lookAt = vec3(1.);
    cam.f = normalize(cam.lookAt - cam.pos);
    cam.r = cross(worldUp, cam.f);
    cam.u = cross(cam.f, cam.r);
}

void ConstructRay(Camera cam, vec2 uv, inout Ray ray)
{
    vec3 screenCentre = cam.pos + cam.f * cam.zoom;
    vec3 i = screenCentre + uv.x * cam.r + uv.y * cam.u;
    ray.o = cam.pos;
    ray.d = i - cam.pos;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // frame coords
    vec2 uv = (fragCoord / iResolution.xy) - .5;
    uv.x *= iResolution.x / iResolution.y;

    float time = iGlobalTime;
    vec3 worldUp = vec3(0., 1., 0.);

    Camera cam;
    vec2 mouse = (iMouse.xy / iResolution.xy);
    vec3 camPos = vec3(mouse.x, mouse.y, -10.);
    InitializeCamera(uv, camPos, cam);

    Ray ray;
    ConstructRay(cam, uv, ray);

    float d = 0.;
    Sphere sphere;
    sphere.radius = 1.0;
    sphere.fallOff = 0.9;
    sphere.pos = vec3(1.0, 1.0, 0.0);

// in order to find where the light hits the object per frag we either need to raymarch or ray cast to hactually have a point
// sdfs do NOT have positional data

    d = DrawDisc(sphere, ray);
    vec3 col = vec3(d);

    // Output to screen
    fragColor = vec4(col, 1.0);
}