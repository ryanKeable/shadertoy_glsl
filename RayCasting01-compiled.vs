#define GLSLIFY 1
const vec3 worldUp = vec3(0., 1. , 0.);

struct Ray {
    vec3 o;
    vec3 d;
};

struct Disc {
    vec3 p;
    float s;
};

struct Camera {
    vec3 f;
    vec3 r;
    vec3 u;
    vec3 pos;
    vec3 rot;
    vec3 lookAt;
    float zoom;
    float fov;
};

float DistLine(vec3 ro, vec3 rd, vec3 p)
{
    vec3 rop = (p - ro);
    return length(cross(rop, rd)) / length(rd);
}

float DrawDisc(Disc d, Ray r)
{
    float radius = 1. - DistLine(r.o, r.d, d.p) / d.s;
    return smoothstep(0.0,.05,radius);
}

void InitializeCamera(vec2 uv, vec3 pos, float time, inout Camera cam)
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

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // frame coords
    vec2 uv = 2. * (fragCoord/iResolution.xy) - 1.;
    uv.x *= iResolution.x / iResolution.y;

    float time = iGlobalTime;
    vec3 worldUp = vec3(0.,1.,0.);

    Camera cam;
    vec2 mouse = 2. * (iMouse.xy/iResolution.xy) - 1.;
    vec3 camPos = vec3(mouse.x, mouse.y, -5.);
    InitializeCamera(uv, camPos, iGlobalTime, cam);

    Ray ray;
    ConstructRay(cam, uv, ray);

    float d = 0.;
    Disc disc[8];

    for (int i = 0; i < 8; i++)
    {   
        float x = floor(float(i*2/8)); // returns floor of 0.0-> 1.75 (2 * 7 / 8) 
        float y = mod(float(i / 2), 2.); // alternates between 1 and 0 across 2 iterations
        float z = mod(float(i),2.); // alternates between 1 and 0

        disc[i].p = vec3(x, y, z);
        disc[i].p *= 4.;
        disc[i].p -= vec3(1., 1., 0.);
        disc[i].s = 0.1;
        d += DrawDisc(disc[i], ray);
    }

    // Debug Color output
    vec3 col = vec3(d);

    // Output to screen
    fragColor = vec4(col,1.0);

    // disc[0].p = vec3(0., 0., 0.);
    // disc[1].p = vec3(0., 0., 1.);
    // disc[2].p = vec3(0., 1., 0.);
    // disc[3].p = vec3(0., 1., 1.);
    // disc[4].p = vec3(1., 0., 0.);
    // disc[5].p = vec3(1., 0., 1.);
    // disc[6].p = vec3(1., 1., 0.);
    // disc[7].p = vec3(1., 1., 1.);
}