
#include "./lib/functions-compiled.glsl"
#define AA 2.

float NoiseDisplacement(vec2 uv)
{
    return sin(noise(uv + noise(uv) * 3.5 * iTime) * 3.5 * iTime) * 0.085;
}

vec4 DiscSDF(Disc d, vec2 uv)
{
    uv += NoiseDisplacement(uv);
    float dst = d.r / length(uv - vec2(d.p.x, d.p.y));

    vec2 p = translate(uv, vec2(d.p.x, d.p.y));
    // dst = length(p) - d.r;


    return vec4(d.c * dst, dst);
}

vec3 renderMetaBall(vec2 uv)
{
    Disc  mbr, mbg, mbb;
    mbr.p = 0.3 * sin(iTime * .8 + vec3(4.0, 0.5, 0) + 6.0); mbr.r = 0.2; mbr.c = vec3(1., 0., 0.);
    mbg.p = 0.4 * sin(iTime * .7 + vec3(1.0, 3., 0) + 2.0); mbg.r = 0.6; mbg.c = vec3(0., 1., 0.);
    mbb.p = 0.5 * sin(iTime * .5 + vec3(3.0, 1.2, 0) + 4.0); mbb.r = 0.35; mbb.c = vec3(0., 0., 1.);
    
    vec4 ballr = DiscSDF(mbr, uv);
    vec4 ballg = DiscSDF(mbg, uv);
    vec4 ballb = DiscSDF(mbb, uv);
    
    float total = ballr.a + ballg.a + ballb.a;
    float threshold = total > 4.5 ? 1. : 0.;
    vec3 color = (ballr.rgb + ballg.rgb + ballb.rgb) / total;
    color *= threshold;
    return color;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // frame coords
    vec2 uv;
    InitializeScreenSpace(fragCoord, uv);

    vec3 col = vec3(0);
    int gridResolution = 8;
    
    vec2 gv = fract(uv * float(gridResolution));


    Disc d;
    d.p = vec3(0);
    d.c = vec3(1., .5, 0);
    d.r = .5;



    // so the idea is to draw any f(x)
    // divide the screen into a grid
    // iterate through each square
    // determine the corners of each grid
    // determine if the f(x) contour is within our square

    // col = vec3(gv.x, gv.y, 0);

    vec4 metaDisc = vec4(0);

    float uvs = 1. / max(iResolution.x, iResolution.y);
    
    #ifdef AA
        for (float i = -AA; i < AA; ++i)
        {
            for (float j = -AA; j < AA; ++j)
            {
                col += renderMetaBall(uv + vec2(i, j) * (uvs / AA)) / (4. * AA * AA);
            }
        }
    #else
        col = renderMetaBall(uv);
        #endif /* AA */

        // Output to screen
        fragColor = vec4(col, 1.0);
    }