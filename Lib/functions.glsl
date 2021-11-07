vec3 cubeGrid[27] = vec3[27]
(
    vec3(-1, -1, -1),
    vec3(0, -1, -1),
    vec3(1, -1, -1),
    vec3(-1, 0, -1),
    vec3(0, 0, -1),
    vec3(1, 0, -1),
    vec3(-1, 1, -1),
    vec3(0, 1, -1),
    vec3(1, 1, -1),
    vec3(-1, -1, 0),
    vec3(0, -1, 0),
    vec3(1, -1, 0),
    vec3(-1, 0, 0),
    vec3(0, 0, 0),
    vec3(1, 0, 0),
    vec3(-1, 1, 0),
    vec3(0, 1, 0),
    vec3(1, 1, 0),
    vec3(-1, -1, 1),
    vec3(0, -1, 1),
    vec3(1, -1, 1),
    vec3(-1, 0, 1),
    vec3(0, 0, 1),
    vec3(1, 0, 1),
    vec3(-1, 1, 1),
    vec3(0, 1, 1),
    vec3(1, 1, 1)
);

struct Disc {
    vec3 p;
    float s;
};

struct Ray
{
    vec3 o;
    vec3 d;
    vec3 invD;
    int sign[3];
};

struct Sphere
{
    bool hit;
    vec3 pos;
    vec3 albedo;
    float radius;
    float specularity;
};

struct Box
{
    bool hit;
    vec3 pos;
    vec3 albedo;
    vec3 scale;
    vec3 rotation;
    vec3 hitPos;
    vec3 normal;
    float specularity;
};

struct Light
{
    vec3 pos;
    vec3 col;
    float attenuation;
    float intensity;
};

void InitializeScreenSpace(vec2 fragCoord, inout vec2 uv)
{
    uv = (fragCoord - .5 * iResolution.xy) / iResolution.y;
}

float DistLine(vec3 ro, vec3 rd, vec3 p)
{
    vec3 rop = (p - ro);
    return length(cross(rop, rd)) / length(rd);
}

float DrawDisc(Disc d, Ray r)
{
    float radius = 1. - DistLine(r.o, r.d, d.p) / d.s;
    return smoothstep(0.0,.05,radius);
}

vec3 LightTrace(vec3 normal, vec3 intersection, Light light)
{
    Ray r;
    r.o = intersection;
    r.d = normalize(light.pos - r.o); //

    float nDotL = dot(normal, r.d);
    vec3 lambert = nDotL * light.col;

    return vec3(lambert);
}

bool SphereInterection(Ray r, Sphere s, inout vec3 hit, inout vec3 normal)
{
    float t = dot(s.pos - r.o, r.d);
    if (t < 0.)  return false; // make sure we are not using casts in the opposite direction

    vec3 p = r.o + r.d * t;

    float y = length(s.pos - p);
    if (y < s.radius)
    {
        float x = sqrt(s.radius * s.radius - y * y);
        float t1 = t - x;
        float t2 = t + x;

        hit = r.o + r.d * t1;
        normal = normalize(hit - s.pos);

        return true;
    }
}


void InitializeSphere(inout Sphere sphere)
{

}