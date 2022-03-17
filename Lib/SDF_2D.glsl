
struct Box2D
{
    vec2 position;
    vec2 scale;
    vec2 rotation;
    vec2 normals;
    vec2 albedo;
};

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

vec2 Vec2Max0(vec2 v)
{
    v.x = max(v.x, 0.0);
    v.y = max(v.y, 0.0);

    return v;
}

// this can just take the camera position cant it?? I dont actually have to march to it?
float Box2DDist(vec2 p, Box2D b)
{
    // we need to convert form box origin to edge data:
    // we take our centre pos, add half the scale to it
    vec2 boxEdge = b.position + b.scale * 0.5;

    // length is pythag
    // max is clamping the evaluation p
    // abs applies the mirroring
    vec2 qPoint = abs(p) - boxEdge;
    float dist = length(Vec2Max0(qPoint));

    // what is maxComp?
    dist += min(max(qPoint.x, qPoint.y), 0.);

    return dist;

    // it would also be handy to know the distance inside??
}
