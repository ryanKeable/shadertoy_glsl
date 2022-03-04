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
// REF: https://www.shadertoy.com/view/4tlSzl

// Hash function. This particular one probably doesn't disperse things quite as nicely as some
// of the others around, but it's compact, and seems to work.
//
vec3 hash33(vec3 p)
{
    
    float n = sin(dot(p, vec3(7, 157, 113)));
    return fract(vec3(2097152, 262144, 32768) * n);
}

// 3D Voronoi: Obviously, this is just a rehash of IQ's original.
//
float voronoi(vec3 p)
{

    vec3 b, r, g = floor(p);
    p = fract(p); // "p -= g;" works on some GPUs, but not all, for some annoying reason.
    
    // Maximum value: I think outliers could get as high as "3," the squared diagonal length
    // of the unit cube, with the mid point being "0.75." Is that right? Either way, for this
    // example, the maximum is set to one, which would cover a good part of the range, whilst
    // dispensing with the need to clamp the final result.
    float d = 1.;
    
    // I've unrolled one of the loops. GPU architecture is a mystery to me, but I'm aware
    // they're not fond of nesting, branching, etc. My laptop GPU seems to hate everything,
    // including multiple loops. If it were a person, we wouldn't hang out.
    for (int j = -1; j <= 1; j++)
    {
        for (int i = -1; i <= 1; i++)
        {
            
            b = vec3(i, j, -1);
            r = b - p + hash33(g + b);
            d = min(d, dot(r, r));
            
            b.z = 0.0;
            r = b - p + hash33(g + b);
            d = min(d, dot(r, r));
            
            b.z = 1.;
            r = b - p + hash33(g + b);
            d = min(d, dot(r, r));
        }
    }
    
    return d; // Range: [0, 1]

}

// Standard fBm function with some time dialation to give a parallax
// kind of effect. In other words, the position and time frequencies
// are changed at different rates from layer to layer.
//
float noiseLayers(in vec3 p)
{

    // Normally, you'd just add a time vector to "p," and be done with
    // it. However, in this instance, time is added seperately so that
    // its frequency can be changed at a different rate. "p.z" is thrown
    // in there just to distort things a little more.
    vec3 t = vec3(0., 0., p.z + iTime * 1.5);

    const int iter = 5; // Just five layers is enough.
    float tot = 0., sum = 0., amp = 1.; // Total, sum, amplitude.

    for (int i = 0; i < iter; i++)
    {
        tot += voronoi(p + t) * amp; // Add the layer to the total.
        p *= 2.; // Position multiplied by two.
        t *= 1.5; // Time multiplied by less than two.
        sum += amp; // Sum of amplitudes.
        amp *= .5; // Decrease successive layer amplitude, as normal.

    }
    
    return tot / sum; // Range: [0, 1].

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
float voronoiF = 10.;
float simplexF = 5.;

vec3 col01 = vec3(5., 75., 70.) / 255.;
vec3 col02 = vec3(201., 108., 210.) / 255.;

vec2 circlePos = vec2(0.0);

void InitializeScreenSpace(vec2 fragCoord, inout vec2 uv)
{
    uv = (fragCoord - .5 * iResolution.xy) / iResolution.y;
}

/// this is not a tonemapper. it is a colour curve corrector
vec3 ColorCurves(vec3 value, float t, float s, float p)
{
    // https://www.desmos.com/calculator/fs0mfuqvbf
    // based off this function

    value = saturate(value);

    // define min max for toe, shoulder and power
    t = min(5., t);
    t = max(0.0001, t);

    s = min(1., s);
    s = max(0.0001, s);

    p = min(5., p);
    p = max(0.0001, p);

    // p: Polynomial
    vec3 p1 = pow(value, vec3(t));

    // keeps the output as 0->1
    float a = 1.0 + s;
    float b = 1.0 - s;

    vec3 p2 = pow(p1, vec3(a));
    vec3 denominator = p2 * b + s;
    
    vec3 color = p1 / denominator;
    color = pow(color, vec3(p));

    return saturate(color);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Pixel color
    vec3 col = vec3(1.);

    vec2 uv;
    InitializeScreenSpace(fragCoord, uv);

    float z = iTime;
    // noise
    vec3 coords = vec3(uv * voronoiF, z);
    float voronoiNoise = voronoi(coords);

    coords = vec3(uv * simplexF, z * .66);
    float simplexNoise = simplexNoise3d(coords);

    float noise = (voronoiNoise + simplexNoise) * 0.5;

    col = mix(col01, col02, noise) + ((voronoiNoise - simplexNoise) + 1.) * .5 * 0.75; //negative numbers but they look fucking sick

    // this is so fucking powerful and I love it!
    col = ColorCurves(col, 3.0, 0.8, 1.8);

    fragColor = vec4(col, 1.0);
}