#define GLSLIFY 1
// lighting functions
// add structs for lights and further light calcs

float DefaultLighting(vec3 n)
{
    float diff = dot(n, normalize(vec3(1,2,3))) * .5 + .5;
    return clamp(diff, 0., 1.);
}