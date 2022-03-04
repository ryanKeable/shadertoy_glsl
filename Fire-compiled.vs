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
#define GLSLIFY 1
vec2 InitializeScreenSpace(vec2 fragCoord, float offset)
{
    return(fragCoord - offset * iResolution.xy) / iResolution.y;
}

#define pixelToTexelRatio (iResolution.xy / fragCoord.xy)

float timeSpeed = .65;
float timeDuration = 6.0;
float circleRadius = 0.23;
float circleFade = .2;
float voronoiF = 10.;
float simplexF = 2.;
float bumpF = 40.;

vec3 col01 = vec3(71., 4., 46.) / 255.;
vec3 col02 = vec3(179., 25., 50.) / 255.;
vec3 col03 = vec3(244., 89., 145.) / 255.;
vec3 col04 = vec3(199., 40., 140.) / 255.;
vec3 col05 = vec3(153., 14., 50.) / 255.;

vec3 veinsPulse01 = vec3(36., 66., 218.) / 255.;
vec3 veinsPulse02 = vec3(78., 78., 247.) / 255.;

vec2 circlePos = vec2(0.0);

/// this is not a tonemapper. it is a colour curve corrector
vec3 ColorCurves(vec3 value, float toe, float shoulder, float compression)
{
    value = saturate(value);

    // define min max for toe, shoulder and power
    toe = min(5., toe);
    toe = max(0.0001, toe);

    shoulder = min(1., shoulder);
    shoulder = max(0.0001, shoulder);

    compression = min(5., compression);
    compression = max(0.0001, compression);

    // toe controls the speed of the contrast
    vec3 contrast = pow(value, vec3(toe));

    // using shoulder in this manner keeps the output anchored as 0->1
    float shoulderCompressionSpeed = 1.0 + shoulder;
    float peak = 1.0 - shoulder;

    // defines the shoulder compression
    vec3 shoulderCompression = pow(contrast, vec3(shoulderCompressionSpeed));
    vec3 smoothShoulder = shoulderCompression * peak + shoulder;
    
    vec3 result = contrast / smoothShoulder;
    result = pow(result, vec3(compression));
    

    return saturate(result);
}

vec3 calcVoronoiNormal(in vec3 p) // for function f(p)

{
    const float eps = 0.0001; // or some other value
    const vec2 h = vec2(eps, 0);
    return normalize(vec3(voronoi(p + h.xyy) - voronoi(p - h.xyy),
    voronoi(p + h.yxy) - voronoi(p - h.yxy),
    voronoi(p + h.yyx) - voronoi(p - h.yyx)));
}

vec3 calcSimplexNormals01(in vec3 p) // for function f(p)

{
    const float h = .1; // replace by an appropriate value
    const vec2 k = vec2(1, -1);
    return normalize(k.xyy * simplexNoise3d(p + k.xyy * h) +
    k.yyx * simplexNoise3d(p + k.yyx * h) +
    k.yxy * simplexNoise3d(p + k.yxy * h) +
    k.xxx * simplexNoise3d(p + k.xxx * h));
}

vec3 calcSimplexNormals02(in vec3 p) // for function f(p)

{
    const float h = 0.0001; // replace by an appropriate value
    const vec2 k = vec2(1, -1);
    return normalize(k.xyy * simplexNoise3d(p + k.xyy * h) +
    k.yyx * simplexNoise3d(p + k.yyx * h) +
    k.yxy * simplexNoise3d(p + k.yxy * h) +
    k.xxx * simplexNoise3d(p + k.xxx * h));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Pixel color
    vec3 col = vec3(1.);

    vec2 uv = InitializeScreenSpace(fragCoord, 0.5);

    float z = iTime * timeSpeed;

    vec3 coords = vec3(uv * simplexF, 1.0);
    float simplexNoise = simplexNoise3d(coords);
    float depth = 1.0 - (simplexNoise * 1.5 - .25);
    depth += depth;
    
    vec3 normals = calcSimplexNormals01(coords);
    col = normals;

    vec3 lightPos = normalize(vec3(sin(iTime * 2. + 10.), 0., 10.));
    vec3 lightDir = normalize(lightPos - coords); //

    col = vec3(dot(lightDir, normals));

    // col = vec3(simplexNoise);

    // noise
    // float vfo = (simplexNoise) * 2.; // voronoi freq offset
    // float vz = (sin(simplexNoise * 1.5 + 60.) * 15.) + .5; // this his how that dude popped eyes out -- use this as a mask
    // coords = vec3(uv * (voronoiF + vfo), vz);
    // float cells = 1.0 - voronoi(coords);
    

    // vec3 cellNormals = calcVNormal(coords);
    // // to find the normals I have to samplethe noise with offsets...

    // // find the normals of the cells and input this into the x/y
    // vec3 bumpCoords = vec3(uv * bumpF * vfo * 0.5, cells + vz * vfo);
    // coords = vec3(cells);
    // // coords.y = cells;
    // float bumps = 1.0 - simplexNoise3d(bumpCoords);
    // bumps = smoothstep(.75, 1., bumps) * .35;
    

    // // we need to add depth to this...
    // float cont = (cells + simplexNoise + bumps) * 0.33;
    // float result = cont * depth;

    // come back to colour...

    // vec3 flesh = mix(col01, col02, 1. - noise);  //negative numbers but they look fucking sick
    // float lerp = saturate(sin(simplexNoise * 2.5));
    // lerp = pow(lerp, 4.);
    // vec3 veins = mix(veinsPulse01, veinsPulse02, pow(voronoiNoise, 2.));
    // vec3 highlights = mix(col03, col04, pow(voronoiNoise, 2.));
    // col = mix(highlights, flesh, lerp);
    // vec3 washColor = mix(col05, col03, (1.0 - lerp)) * (1.0 - lerp);
    // // col = mix(col, washColor * 2., (1.0 - lerp));

    // col = ColorCurves(col, 1.0, 0.8, 1.2);
    // // col = highlights *);
    // col = vec3(result);

    // vec3 light = normalize(vec3(0.0, 0.0, 1.0));
    // col = vec3(dot(light, cellNormals));
    // col.x = cellNormals.x;
    // col.y = cellNormals.y;
    // col = cellNormals;

    fragColor = vec4(col, 1.0);
}