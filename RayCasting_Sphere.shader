// randomize sphere surface height with noise
// calculate correct backwards path tracing
// rectify additive blending
// add brdf lighting model
// - spec
// - surface shadowing
// - fresnel

// add shadow penumbras
// add multiple lights
// add reflectivity
// add refraction
// add SSS
// add ground surface
// add and sample ambient background
// add other geometric shapdes

struct Ray
{
    vec3 o;
    vec3 d;
};

struct Sphere
{
    bool hit;
    vec3 pos;
    vec3 albedo;
    float radius;
    float shininess; // exponent
    float metallic;
};

struct Light
{
    vec3 pos;
    vec3 col;
    float intensity;
};

void InitializeScreenSpace(vec2 fragCoord, inout vec2 uv)
{
    uv = (fragCoord - .5 * iResolution.xy) / iResolution.y;
}

float Remap01(float a, float b, float value)
{
    // if compare == a return 0 if compare == b return 1
    return(value - a) / (b - a);
}

vec3 LightTrace(vec3 normal, vec3 intersection, Light light)
{
    Ray r;
    r.o = intersection;
    r.d = normalize(light.pos - r.o); //

    float nDotL = dot(normal, r.d);
    vec3 lambert = nDotL * light.col;

    return vec3(lambert);
}

bool SphereInterection(Ray r, Sphere s, inout vec3 hit, inout vec3 normal)
{
    float t = dot(s.pos - r.o, r.d);
    if (t < 0.)  return false; // make sure we are not using casts in the opposite direction

    vec3 p = r.o + r.d * t;

    float y = length(s.pos - p);
    if (y < s.radius)
    {
        float x = sqrt(s.radius * s.radius - y * y);
        float t1 = t - x;
        float t2 = t + x;

        hit = r.o + r.d * t1;
        normal = normalize(hit - s.pos);

        return true;
    }
}

const int sphereCount = 2;
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // frame coords
    vec2 uv;
    InitializeScreenSpace(fragCoord, uv);

    vec3 col = vec3(0);
    float depth = 0.;
    
    vec3 ambient = vec3(.035, .002, .07);
    
    Sphere sphere[sphereCount];

    sphere[0].pos = vec3(0., -1., 0.);
    sphere[0].radius = 1.;
    sphere[0].albedo = vec3(.2, .7, .1);
    sphere[0].shininess = 30.;
    sphere[0].metallic = .3;
    sphere[0].hit = false;

    sphere[1].pos = vec3( - .65, 1.25, 0.);
    sphere[1].radius = .5;
    sphere[1].albedo = vec3(.2, .7, .8);
    sphere[1].shininess = 5.;
    sphere[0].hit = false;

    Ray pRay; // Primary Ray
    pRay.o = vec3(0, 0, -8.);
    pRay.d = normalize(vec3(uv.x, uv.y, 1));

    Light light;
    light.pos = vec3( - .2, 1., 0) * 100.;
    light.col = vec3(1., .87, .66);
    light.intensity = 1.4;
    light.col *= pow(light.intensity, 2.0);

    // do intersection test per frag
    // if we hit, do not test for any other intersections

    float minDist = 10000.;
    vec3 pHit; // primary hit
    vec3 nHit; // normal at primary hit

    Sphere hitSphere;
    bool shadow = false;

    for (int i; i < sphereCount; i++)
    {

        if (SphereInterection(pRay, sphere[i], pHit, nHit))
        {
            // we have hit a sphere
            // make sure we are the closest sphere
            sphere[i].hit = true;
            float dist = distance(pRay.o, pHit);
            if (dist < minDist)
            {
                hitSphere = sphere[i];
                minDist = dist;
            }
        }
    }

    if (hitSphere.hit == true)
    {
        Ray rToL;
        rToL.o = pHit + nHit * 0.0001;
        rToL.d = normalize(light.pos - rToL.o);

        vec3 sHit; // primary hit
        vec3 nSHit; // normal at primary hit

        col = rToL.d;

        for (int j; j < sphereCount; j++)
        {
            if (SphereInterection(rToL, sphere[j], sHit, nSHit))
            {
                if (hitSphere.pos == sphere[j].pos) break;
                shadow = true;
                break;
            }
        }

        if (!shadow)
        {
            col = hitSphere.albedo * LightTrace(nHit, pHit, light);
        }
        else
        {
            col = vec3(0);
        }

        // vec4 sphereOutput01 = DrawSphere(ray, sphere[0], light);

    }

    // vec4 sphereOutput02 = DrawSphere(ray, sphere[1], light);

    // // additive blending is not correct!
    // col += sphereOutput01.xyz;
    // col += sphereOutput02.xyz;


    // Output to screen
    fragColor = vec4(col, 1.0);
}