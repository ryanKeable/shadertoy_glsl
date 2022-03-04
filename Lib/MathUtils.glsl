const float M_PI = 3.14159265358979323846264338327950288;
const float M_PI_2 = 6.28318530718;

vec3 Vec3Max0(vec3 v)
{
    v.x = max(v.x, 0.0);
    v.y = max(v.y, 0.0);
    v.z = max(v.z, 0.0);

    return v;
}

float Max3(vec3 v)
{
    return max(v.x, max(v.y, v.z));
}

vec2 Vec2Max0(vec2 v)
{
    v.x = max(v.x, 0.0);
    v.y = max(v.y, 0.0);

    return v;
}

float Saturate(float v)
{
    return clamp(v, 0.0, 1.0);
}

mat2 Rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

vec3 MouseRotation(vec3 p, float x, float y)
{
    vec2 m = iMouse.xy / iResolution.xy;

    p.yz *= Rot(-m.y * M_PI + iTime * y);
    p.xz *= Rot(-m.x * M_PI + iTime * x);

    return p;
}


