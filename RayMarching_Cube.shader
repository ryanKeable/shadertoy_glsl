
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

const float bias = 0.001;

bool BoxIntersection(Ray r, inout Box b)
{
    // need to acertain my box's bounds
    // then test against the "rays" of the parallel planes of those bounds
    vec3 bounds[2];

    bounds[0] = b.pos - b.scale * .5;
    bounds[1] = b.pos + b.scale * .5;

    float tmin, tmax, tymin, tymax, tzmin, tzmax;
    
    tmin = (bounds[r.sign[0]].x - r.o.x) * r.invD.x;
    tmax = (bounds[1 - r.sign[0]].x - r.o.x) * r.invD.x;
    tymin = (bounds[r.sign[1]].y - r.o.y) * r.invD.y;
    tymax = (bounds[1 - r.sign[1]].y - r.o.y) * r.invD.y;
    
    if ((tmin > tymax) || (tymin > tmax))
        return false;

    tzmin = (bounds[r.sign[2]].z - r.o.z) * r.invD.z;
    tzmax = (bounds[1 - r.sign[2]].z - r.o.z) * r.invD.z;

    vec3 vmin = vec3(tmin, tymin, tzmin);
    vec3 vmax = vec3(tmax, tymax, tzmax);

    if (tymin > tmin)
        tmin = tymin;
    if (tymax < tmax)
        tmax = tymax;
    
    if ((tmin > tzmax) || (tzmin > tmax))
        return false;

    if (tzmin > tmin)
        tmin = tzmin;

    if (tzmax < tmax)
        tmax = tzmax;

    b.hitPos = r.o + r.d * tmin;
    vec3 maxHitPos = r.o + r.d * tmax;


    // centre of our two hit points
    
    // origin to hit

    vec3 aabbc = (b.hitPos + maxHitPos) * 0.5;
    vec3 p = b.hitPos - aabbc;
    vec3 d = (maxHitPos - b.hitPos) * 0.5;
    d = (d) * 1.000001; // absolute * bias

    vec3 h = ((maxHitPos + b.hitPos) * .5) - b.pos;
    // h *= 2.00001;

    float xNormal = float(int(h.x));
    float yNormal = float(int(h.y));
    float zNormal = float(int(h.y));


    b.normal = normalize(vec3(xNormal, yNormal, zNormal));//, bounds[0].y + bounds[1].y, bounds[0].z + bounds[1].z));
    
    b.normal = h;
    // b.normal = vec3(xNormal, yNormal, zNormal);
    return true;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // frame coords
    vec2 uv;
    InitializeScreenSpace(fragCoord, uv);

    vec3 col = vec3(.1);
    float depth = 0.;
    
    vec3 ambient = vec3(.035, .002, .07);
    
    Box box;
    box.pos = vec3(1.5, 1., 2.);
    box.pos = vec3(0, -1., 0);
    box.albedo = vec3(.8, .6, .4);
    box.scale = vec3(1, .5, 1);


    Ray pRay; // Primary Ray
    pRay.o = vec3(0, 0, -4.);
    pRay.d = normalize(vec3(uv.x, uv.y, 1));
    pRay.invD = 1. / pRay.d;
    pRay.sign[0] = int(pRay.invD.x < 0.);
    pRay.sign[1] = int(pRay.invD.y < 0.);
    pRay.sign[2] = int(pRay.invD.z < 0.);


    Light light;
    light.pos = vec3(.25, 1., - .5) * 100.;
    light.col = vec3(1., .87, .66);
    light.intensity = 1.4;
    light.col *= pow(light.intensity, 2.0);


    // this branching is causing threading issues with my render layering!!!
    if (BoxIntersection(pRay, box))
    {
        // Disc d;
        // d.p = box.pos;
        // d.s = 0.5;
        // float debugDisc = DrawDisc(d, pRay);
        // vec3 debugDiscCol = vec3(debugDisc, 0, 0);
        
        // col = mix(vec3(1), debugDiscCol, debugDisc);

        col = box.normal;
    }


    
    // Output to screen
    fragColor = vec4(col, 1.0);
}