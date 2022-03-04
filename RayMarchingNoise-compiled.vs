#define GLSLIFY 1
#define GLSLIFY 1
vec2 hash(vec2 p) // replace this by something better

{
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(in vec2 p)
{
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;

    vec2  i = floor(p + (p.x + p.y) * K1);
    vec2  a = p - i + (i.x + i.y) * K2;
    float m = step(a.y, a.x);
    vec2  o = vec2(m, 1.0 - m);
    vec2  b = a - o + K2;
    vec2  c = a - 1.0 + 2.0 * K2;
    vec3  h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
    vec3  n = h * h * h * h * vec3(dot(a, hash(i + 0.0)), dot(b, hash(i + o)), dot(c, hash(i + 1.0)));
    return dot(n, vec3(70.0));
}

/* discontinuous pseudorandom uniformly distributed in [-0.5, +0.5]^3 */
vec3 random3(vec3 c)
{
    float j = 4096.0 * sin(dot(c, vec3(17.0, 59.4, 15.0)));
    vec3 r;
    r.z = fract(512.0 * j);
    j *= .125;
    r.x = fract(512.0 * j);
    j *= .125;
    r.y = fract(512.0 * j);
    return r - 0.5;
}

/* skew constants for 3d simplex functions */
const float F3 = 0.3333333;
const float G3 = 0.1666667;

/* 3d simplex noise */
float simplex3d(vec3 p)
{
    /* 1. find current tetrahedron T and it's four vertices */
    /* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
    /* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/
    
    /* calculate s and x */
    vec3 s = floor(p + dot(p, vec3(F3)));
    vec3 x = p - s + dot(s, vec3(G3));
    
    /* calculate i1 and i2 */
    vec3 e = step(vec3(0.0), x - x.yzx);
    vec3 i1 = e * (1.0 - e.zxy);
    vec3 i2 = 1.0 - e.zxy * (1.0 - e);
    
    /* x1, x2, x3 */
    vec3 x1 = x - i1 + G3;
    vec3 x2 = x - i2 + 2.0 * G3;
    vec3 x3 = x - 1.0 + 3.0 * G3;
    
    /* 2. find four surflets and store them in d */
    vec4 w, d;
    
    /* calculate surflet weights */
    w.x = dot(x, x);
    w.y = dot(x1, x1);
    w.z = dot(x2, x2);
    w.w = dot(x3, x3);
    
    /* w fades from 0.6 at the center of the surflet to 0.0 at the margin */
    w = max(0.6 - w, 0.0);
    
    /* calculate surflet components */
    d.x = dot(random3(s), x);
    d.y = dot(random3(s + i1), x1);
    d.z = dot(random3(s + i2), x2);
    d.w = dot(random3(s + 1.0), x3);
    
    /* multiply d by w^4 */
    w *= w;
    w *= w;
    d *= w;
    
    /* 3. return the sum of the four surflets */
    return dot(d, vec4(52.0));
}

float simplexNoise3d(vec3 uvz)
{
    // NOISE
    float f = simplex3d(uvz);
    f = 0.5 * f + 0.5;
    // f = (f + 1.) * .5;
    f = smoothstep(0., 1., f);

    return f;
}

float simplexNoise3d(vec2 uv, float freq, float z)
{
    // NOISE
    vec3 uvz = vec3(uv * freq, z);

    return simplexNoise3d(uvz);
}

/* const matrices for 3d rotation */
const mat3 rot1 = mat3(-0.37, 0.36, 0.85, -0.14, -0.93, 0.34, 0.92, 0.01, 0.4);
const mat3 rot2 = mat3(-0.55, -0.39, 0.74, 0.33, -0.91, -0.24, 0.77, 0.12, 0.63);
const mat3 rot3 = mat3(-0.71, 0.52, -0.47, -0.08, -0.72, -0.68, -0.7, -0.45, 0.56);

/* directional artifacts can be reduced by rotating each octave */
float simplex3d_fractal(vec3 m)
{
    return 0.5333333 * simplex3d(m * rot1)
    + 0.2666667 * simplex3d(2.0 * m * rot2)
    + 0.1333333 * simplex3d(4.0 * m * rot3)
    + 0.0666667 * simplex3d(8.0 * m);
}
#define GLSLIFY 1
vec2 InitializeScreenSpace(vec2 fragCoord, float offset)
{
    return(fragCoord - offset * iResolution.xy) / iResolution.y;
}

// Camera Stuff:
const vec3 worldUp = vec3(0., 1., 0.);

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

void InitializeCamera(inout Camera cam)
{
    cam.f = normalize(cam.lookAt - cam.pos);
    cam.r = cross(worldUp, cam.f);
    cam.u = cross(cam.f, cam.r);
}

struct Ray
{
    vec3 o;
    vec3 d;
};

void ConstructRay(Camera cam, vec2 uv, inout Ray ray)
{
    vec3 screenCentre = cam.pos + cam.f * cam.zoom;
    vec3 i = screenCentre + uv.x * cam.r + uv.y * cam.u;
    ray.o = cam.pos;
    ray.d = normalize(i - cam.pos);
}

#define SCENE_MAX_STEPS 500
#define DENSITY_MAX_STEPS 1000
#define MAX_DIST 800.
#define STEP_PRECISION 1e-3 //(0.001)

float densityScale = .05;

// so in order to evaluate positions and rotations we must transform our space first
// i guess we do this per object?

struct Sphere
{
    vec3 centre;
    vec3 albedo;
    float radius;
};

struct Light
{
    vec3 pos;
    vec3 direction;
    vec3 color;
    float intensity;
    float attenuation;
};

float SphereDist(vec3 p, vec3 spherePos, float radius)
{
    // this is the scene or object within the box
    // return distance(p, spherePos) - radius;
    return length(p - spherePos) - radius; // sphere

}

/*
2D Box:
we use s.x/2 and s.y/2 and incorporate symetry into our function
we query the top right quadrant (0->1 cartesian coords) and reflect it for other quadtrants

3 Areas, 3 functions:
Let b.x = s.x/2 and b.y = s.y/2
A) right edge: d = p.x - b.x
B) top edge: d = p.y - b.y
C) corner: lenth(p.xy - b.xy) or √((a)^2 + (b)^2)

single expression:
p.x = max(0, p.x)
p.y = max(0, p.y)
a = p.x - r.x (this now returns negative)
a = Max(0, a)?
d = √((a)^2 + (p.y - r.y)^2)
*/

// this function get us to the surface
// find the closest distance to the SCENE from the camera pos to the scene (sphere)
// each subsequent loop retargets the origin to our last known position along the ray
// we then find the distance from that point to the scene (sphere)
// loop through this until the distance is so small we count it as a hit
// what is occuring when we are trying to find our way INSIDE then??

vec3 RaymarchToScene(Ray ray, Sphere sphere, out float alpha)
{
    float distanceFromOrigin = 0.0;
    float distanceFromSurf = 0.0;

    float density = 0.;

    vec3 marchPos;

    float f = 5.;
    float t = sin(iTime * 0.65);

    // gradually increasing the frequency rather than animating through it
    // we need 4D noise
    vec3 noiseF = vec3(f + t);

    for (int i = 0; i < SCENE_MAX_STEPS; i++)
    {
        marchPos = ray.o + distanceFromOrigin * ray.d;
        distanceFromSurf = SphereDist(marchPos, sphere.centre, sphere.radius);

        float noise = simplexNoise3d(marchPos * vec3(noiseF));
        noise *= (0.05);
        distanceFromSurf = distanceFromSurf * noise;

        distanceFromOrigin += distanceFromSurf;

        if (distanceFromSurf < STEP_PRECISION || distanceFromOrigin > MAX_DIST)
            break;
    }

    alpha = 1.0 - saturate(distanceFromSurf);

    return marchPos;
}

// constructred normal
vec3 GetSphereNormal(vec3 p, Sphere s)
{
    vec2 epsilon = vec2(1e-2, 0);

    vec3 normal = SphereDist(p, s.centre, s.radius) - vec3(
        SphereDist(p - epsilon.xyy, s.centre, s.radius),
        SphereDist(p - epsilon.yxy, s.centre, s.radius),
        SphereDist(p - epsilon.yyx, s.centre, s.radius));

    return normalize(normal);
}

/// working out whats next:
/*
- build a density field inside the sphere
- raymarch from a point inside the sphere towards the light
-- only do this when under a density threshold
-- determine when the lightMarch is outside the sphere
--- find the dist from the sample point to the centre
--- if greater than the radius we are out?
--- do not increment by the distance check?

-- determine the density of the points along the lightMarch
--- we known the density of the sphere as we raymarch inside
--- the density along the lightMarch needs to be re-calculated
--- this should be determined by the distance of the point to the centre?
-- determine the accumulation and transmittance of the light along the lightMarch
--
*/

// this function looks inside the surface as the ray's origin is the previously found hitPos
// this needs linear incremental steps to determine the density inside the sphere
float RaymarchDensity(Ray ray, Sphere sphere, Light light, float densityScalar, out float alpha)
{
    // so the outline is generated by the density being 0 before the first step
    float density = 0.;
    float transmittance = 0.;

    // start with an offset one precision step backwards
    // this is to help elleviate outline issues around the edge when we mask the sphere
    // do we also need to make sure we are only marching in a forward direction??
    vec3 rayMarchPos = ray.o; // - (ray.d * STEP_PRECISION); // start with an offset??

    for (int i = 0; i < DENSITY_MAX_STEPS; i++)
    {
        rayMarchPos += (ray.d * STEP_PRECISION);
        float dist = SphereDist(rayMarchPos, sphere.centre, sphere.radius);

        density += (0.1 * densityScalar);

        // stop marching if we are further than when we began

        if (dist > STEP_PRECISION)
        {
            break;
        }

        // if (density < 0.1) // only points with a low density should transmit light?

        // {

        // int steps = 0;
        // float density02 = density;
        // Ray rayToLight;
        // rayToLight.o = rayMarchPos;
        // rayToLight.d = normalize(light.pos - rayMarchPos);

        // for (int j = 0; j < DENSITY_MAX_STEPS; j++)
        // {
        //     rayToLight.o += (rayToLight.d * STEP_PRECISION);
        //     float dist = SphereDist(rayMarchPos, sphere.centre, sphere.radius);

        //     if (dist > STEP_PRECISION)
        //     {
        //         // discard if the distance from the sample to the centre > radius -- we have exitted the sphere
        //         // discard if the length of our lightMarch is greater than the radius -- we are too dense
        //         break;
        //     }
        //     else
        //     {
        //         // this only works if we are getting less dense along the path
        //         // when sampling in the other hemisphere from the light the path would get more dense
        //         density02 -= (1.0 * densityScalar);
        //         transmittance += .1 * densityScalar;
        //         steps++;
        //     }
        // }
        // density = transmittance;
        //     // transmittance /= float(steps);

    }

    alpha = saturate(density);
    // return density;
    return exp(-density);
}

Camera SetUpCamera()
{
    Camera cam;

    // vec2 mouse = 2. * (iMouse.xy / iResolution.xy) - 1.;
    cam.pos = vec3(0., 0.0, -1.25);
    cam.lookAt = vec3(0.0, 0.0, 0.0);
    cam.zoom = 1.;

    InitializeCamera(cam);

    return cam;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // frame coords
    vec2 uv = InitializeScreenSpace(fragCoord, 0.5);

    Camera cam = SetUpCamera();

    Sphere sphere;
    sphere.centre = vec3(0.0, 0.0, 0.0);
    sphere.radius = 0.5;
    sphere.albedo = vec3(0.5, 0.8, 0.4);

    Ray ray;
    ConstructRay(cam, uv, ray);

    vec3 ambient = vec3(0.05, 0.02, 0.12);
    Light light;
    light.color = vec3(.96, 1.0, .94);
    light.pos = vec3(0.0, 1.0, -1.0) * 100000.0;

    // our alpha results are different to the sss results -- this creates an undesired outline
    float alpha;
    vec3 surface = RaymarchToScene(ray, sphere, alpha);

    ray.o = surface;
    vec3 normals = normalize(GetSphereNormal(ray.o, sphere));

    float sss_alpha;
    // vec3 sss = RaymarchDensity(ray, sphere, light, densityScale, sss_alpha) * light.color;

    vec3 dirTolight = normalize(light.pos - surface);
    float lightV = saturate(dot(dirTolight, normals));
    vec3 diffuse = lightV * light.color;
    diffuse *= sphere.albedo;
    diffuse += ambient;
    // diffuse = sss;
    diffuse *= alpha;
    // Debug Color output
    vec3 col = vec3(diffuse);

    // Output to screen
    fragColor = vec4(col, 1.0);
}