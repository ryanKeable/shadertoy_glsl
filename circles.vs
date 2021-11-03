const float M_PI = 3.14159265358979323846264338327950288;

float myLength(vec2 value)
{
    return sqrt(dot(value, value));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    vec2 uv = 2. * (fragCoord/iResolution.xy) - 1.;
    uv.x *= iResolution.x / iResolution.y;

    float angle = atan(uv.y, uv.x); // this is the same as hlsl atan2 as it takes two params
    float radial = abs(angle / (2. * M_PI) + .5); // smooths out the seam
    
    float radius = 1.0;
    float dist = 1. - myLength(uv / radius);


    // Debug Color output
    vec3 col = vec3(dist, radial, 0);

    // Output to screen
    fragColor = vec4(col,1.0);
}