#include "./lib/functions-compiled.glsl"

struct Line2D
{
    vec2 pA;
    vec2 pB;
};

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Pixel color
    vec3 col = vec3(1.);

    vec2 uv;
    InitializeScreenSpace(fragCoord, uv);

    Line2D l;
    l.pA = vec2(-1.0, -2.0);
    l.pB = vec2(2.0, 3.0);
    
    float adj = dot(uv - l.pA, uv - l.pB);

    col = vec3(adj);

    fragColor = vec4(col, 1.0);
}