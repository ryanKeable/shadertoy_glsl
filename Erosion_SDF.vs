#include "./lib/simplexNoise3D.glsl"
#include "./lib/SDF_2D.glsl"
#include "./lib/functions.glsl"
#include "./lib/animation.glsl"

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
    float noiseSpeed = iTime * 1.;
    
    // noise
    float noise = simplexNoise3d(uv, noiseFreq, noiseSpeed);

    //circle
    float circle_xPos = circlePos.x + sinTime(timeSpeed) * 0.25;
    vec2 animatedCirclePos = vec2(circle_xPos, circlePos.y);
    
    float circle = SDF_2D_Circle(circleRadius, circleFade * noise, circlePos, uv);

    // i only want noise on the edges...
    // lets work this out next!

    noise -= circle;
    noise = saturate(noise);
    // final color
    col = saturate(vec3(noise));

    fragColor = vec4(col, 1.0);
}