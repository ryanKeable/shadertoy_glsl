#define GLSLIFY 1
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

float simplexNoise3d(vec2 uv, float freq, float z)
{
    // NOISE
    float f = simplex3d(vec3(uv * freq, z));
    f = 0.5 * f + 0.5;

    return f;
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
float vec2Length(vec2 value)
{
    return sqrt(dot(value, value));
}

float SDF_2D_Circle(float radius, float fade, vec2 pos, vec2 coord)
{
    vec2 vecToCentre = coord - pos;
    float dist = vec2Length(vecToCentre);
    float min = radius - fade;
    float max = radius + fade;
    float circle = smoothstep(min, max, dist);

    return circle;
}

float SDF_2D_Line(vec2 p, vec2 a, vec2 b)
{
    vec2 da = p - a;
    vec2 db = p - b;

    return 0.0;
}
#define GLSLIFY 1
vec3 cubeGrid[27] = vec3[27]
(
    vec3(-1, -1, -1),
    vec3(0, -1, -1),
    vec3(1, -1, -1),
    vec3(-1, 0, -1),
    vec3(0, 0, -1),
    vec3(1, 0, -1),
    vec3(-1, 1, -1),
    vec3(0, 1, -1),
    vec3(1, 1, -1),
    vec3(-1, -1, 0),
    vec3(0, -1, 0),
    vec3(1, -1, 0),
    vec3(-1, 0, 0),
    vec3(0, 0, 0),
    vec3(1, 0, 0),
    vec3(-1, 1, 0),
    vec3(0, 1, 0),
    vec3(1, 1, 0),
    vec3(-1, -1, 1),
    vec3(0, -1, 1),
    vec3(1, -1, 1),
    vec3(-1, 0, 1),
    vec3(0, 0, 1),
    vec3(1, 0, 1),
    vec3(-1, 1, 1),
    vec3(0, 1, 1),
    vec3(1, 1, 1)
);

struct Disc
{
    vec3 p;
    float s;
};

struct Ray
{
    vec3 o;
    vec3 d;
    vec3 invD;
    int sign[3];
};

struct Sphere
{
    bool hit;
    vec3 pos;
    vec3 albedo;
    float radius;
    float specularity;
};

struct Box
{
    bool hit;
    vec3 pos;
    vec3 albedo;
    vec3 scale;
    vec3 rotation;
    vec3 hitPos;
    vec3 normal;
    float specularity;
};

struct Light
{
    vec3 pos;
    vec3 col;
    float attenuation;
    float intensity;
};

void InitializeScreenSpace(vec2 fragCoord, inout vec2 uv)
{
    uv = (fragCoord - .5 * iResolution.xy) / iResolution.y;
}

float DistLine(vec3 ro, vec3 rd, vec3 p)
{
    vec3 rop = (p - ro);
    return length(cross(rop, rd)) / length(rd);
}

float DrawDisc(Disc d, Ray r)
{
    float radius = 1. - DistLine(r.o, r.d, d.p) / d.s;
    return smoothstep(0.0, .05, radius);
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

void InitializeSphere(inout Sphere sphere)
{

}
#define GLSLIFY 1
const float M_PI = 3.14159265358979323846264338327950288;
const float M_PI_2 = 6.28318530718;

float mod01(float value)
{
    return mod(value, 1.0);
}

float loopTime(float speed)
{
    return mod01(iTime * speed);
}

float loopTime(float speed, float duration)
{
    return mod(iTime * speed, duration);
}

float sinTime(float speed)
{
    return sin(iTime * speed);
}

float cosTime(float speed)
{
    return cos(iTime * speed);
}

float easeOutCubic(float value)
{
    return 1.0 - pow(1.0 - value, 3.0);
}

float timeSpeed = .75;
float timeDuration = 6.0;
float circleRadius = 0.23;
float circleFade = .2;
float noiseFreq = 6.;
vec2 circlePos = vec2(0.0);

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Pixel color
    vec3 col = vec3(1.);

    vec2 uv;
    InitializeScreenSpace(fragCoord, uv);
    
    // time
    float loopedTime = loopTime(timeSpeed * .5, M_PI_2);
    
    // noise
    float noise = simplexNoise3d(uv, noiseFreq, loopedTime);

    //circle
    float circle_xPos = circlePos.x + sinTime(timeSpeed) * 0.25;
    vec2 animatedCirclePos = vec2(circle_xPos, circlePos.y);
    float circle = SDF_2D_Circle(circleRadius, circleFade, animatedCirclePos, uv);
    circle *= 2.;

    // i only want noise on the edges...
    // lets work this out next!

    noise -= circle;
    noise *= 1.2;
    noise = saturate(noise);
    // final color
    col = saturate(vec3(noise));

    fragColor = vec4(col, 1.0);
}