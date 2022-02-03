float vec2Length(vec2 value)
{
    return sqrt(dot(value, value));
}

float SDF_2D_Circle(float radius, float fade, vec2 pos, vec2 coord)
{
    vec2 vecToCentre = coord - pos;
    float dist = vec2Length(vecToCentre);
    float min = radius - fade;
    float max = radius + fade;
    float circle = smoothstep(min, max, dist);

    return circle;
}

float SDF_2D_Line(vec2 p, vec2 a, vec2 b)
{
    vec2 da = p - a;
    vec2 db = p - b;

    return 0.0;
}