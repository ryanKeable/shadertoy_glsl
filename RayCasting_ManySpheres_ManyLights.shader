
#include "./lib/functions-compiled.glsl"
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

const int sphereCount = 27;
const float m = .75;
const float bias = 0.001;

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // frame coords
    vec2 uv;
    InitializeScreenSpace(fragCoord, uv);

    vec3 col = vec3(.1);
    float depth = 0.;
    
    vec3 ambient = vec3(.035, .002, .07);
    
    Sphere sphere[sphereCount];

    for (int i = 0; i < sphereCount; i++)
    {
        sphere[i].hit = false;
        sphere[i].pos = cubeGrid[i] * vec3(m);// * vec3(m, 2. * m, 3. * m);
        sphere[i].radius = .05 + float(i) * .005;
        sphere[i].albedo = vec3((.1 + float(i)) / float(sphereCount), .5, 0);
    }

    Ray pRay; // Primary Ray
    pRay.o = vec3(0, 0, -4.);
    pRay.d = normalize(vec3(uv.x, uv.y, 1));

    Light light;
    light.pos = vec3(0., 1., - .5) * 100.;
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
            sphere[i].hit = true;
            float dist = distance(pRay.o, pHit);
            if (dist < minDist)
            {
                hitSphere = sphere[i];
                minDist = dist;
            }
            col = hitSphere.albedo;
        }
    }

    if (hitSphere.hit == true)
    {
        Ray rToL;
        rToL.o = pHit + nHit * bias;
        rToL.d = normalize(light.pos - rToL.o);

        vec3 sHit; // primary hit
        vec3 nSHit; // normal at primary hit

        for (int j; j < sphereCount; j++)
        {
            if (SphereInterection(rToL, sphere[j], sHit, nSHit))
            {
                if (hitSphere.pos == sphere[j].pos) break;
                shadow = true;

                col = hitSphere.albedo;
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
    }

    // Output to screen
    fragColor = vec4(col, 1.0);
}