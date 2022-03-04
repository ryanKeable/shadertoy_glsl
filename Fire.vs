#include "./lib/simplexNoise3D.glsl"
#include "./lib/voronoiNoise.glsl"
#include "./lib/SDF_2D.glsl"
#include "./lib/animation.glsl"
#include "./lib/CamerasAndCoordinates.glsl"

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