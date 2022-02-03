#define GLSLIFY 1
const float M_PI = 3.14159265358979323846264338327950288;

float myLength(vec2 value)
{
    return sqrt(dot(value, value));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{

    float time01 = mod(iTime, 1.0);
    float easeOut = 1.0 - pow(1.0 - time01 , 3.0);

    // Debug Color output
    vec3 col = vec3(easeOut);

    // Output to screen
    fragColor = vec4(col,1.0);
}