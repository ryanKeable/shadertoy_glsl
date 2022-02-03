#define GLSLIFY 1
vec3 gridColor = vec3(0.2, 0.2, 0.5);
float SCALE = .02;

float minLines = 0.001;

// convert fragment space to point space
vec2 frag2point(in vec2 frag)
{
    return SCALE * (frag - 0.5 * iResolution.xy);
}

float sfrac2(float x)
{
    return fract(.5 * x);
}// half-density

// calculate stroke intensity from number of positive samples
float samples2stroke(float ratio)
{
    return smoothstep(0.0, 0.5, ratio) * smoothstep(1.0, 0.5, ratio);
}

vec2 frag2point(in vec2 frag, float scale)
{
    return scale * (frag - 0.5 * iResolution.xy);
}

float GridLines(float x, float ratio, float thickness)
{
    x = sfrac2(x);
    x -= thickness;
    return clamp(x / fwidth(x), 0., 1.);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Pixel color
    vec3 col = vec3(1.);

    // draw grid
    // col = mix(col, gridColor, samples2stroke(sGrid/total));

    vec2 uv = frag2point(fragCoord.xy, SCALE);

    float lineSize = minLines;
    // if(uv.x > 0.005 || uv.x < -0.005) lineSize = minLines;
    
    float grid = GridLines(uv.x, iResolution.y, lineSize) * GridLines(uv.y, iResolution.x, lineSize);
    col = vec3(grid);
    
    fragColor = vec4(col, 1.0);
}