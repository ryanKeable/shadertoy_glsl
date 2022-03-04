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
