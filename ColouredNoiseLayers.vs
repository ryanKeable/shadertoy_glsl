#include "./lib/simplexNoise3D.glsl"
#include "./lib/voronoiNoise.glsl"
#include "./lib/SDF_2D.glsl"
#include "./lib/animation.glsl"

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