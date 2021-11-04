const vec3 worldUp = vec3(0., 1. , 0.);


struct Ray {
    vec3 o;
    vec3 d;
};

struct Sphere {
    vec3 pos;
    vec3 albedo;
    float radius;
    float shininess; // exponent
    float metallic;
};

struct Light {
    vec3 dir;
    vec3 col;
};

void InitializeScreenSpace(vec2 fragCoord, inout vec2 uv)
{
    uv = (fragCoord - .5*iResolution.xy) / iResolution.y;
}

float Remap01(float a, float b, float t){
    // if t == a return 0 if t == b return 1
    return (t-a) / (b-a);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // frame coords
    vec2 uv;
    InitializeScreenSpace(fragCoord, uv);

    vec3 col = vec3(0);    
    vec3 ambient = vec3(.035, .002,.07);
    
    Sphere sphere;
    sphere.pos = vec3(0., 0., 0.);
    sphere.radius = 2.;
    sphere.albedo = vec3(.8,.7,.6);
    sphere.shininess = 10.; 
    sphere.metallic = .3;

    Ray ray;
    ray.o = vec3(0,0,-8.);
    ray.d = normalize(vec3(uv.x, uv.y, 1));

    Light light;
    light.dir = vec3(.75, -.5, .55);
    light.col = vec3(.8, .33, .05);

    float t = dot(sphere.pos - ray.o, ray.d);
    vec3 p = ray.o + ray.d * t;

    float y = length(sphere.pos - p);
    if(y<sphere.radius)
    {
        float x = sqrt(sphere.radius*sphere.radius - y*y);
        float t1 = t-x;
        float t2 = t+x;

        float c = Remap01(sphere.pos.z, sphere.pos.z - sphere.radius, t1);

        vec3 i = ray.o + ray.d * t1;
        vec3 normal = normalize(sphere.pos - i);

        float nDotl = max(dot(normal, light.dir), 0.0001);
        vec3 lambert = sphere.albedo * nDotl * light.col;

        vec3 reflection = 2. * dot(normal, light.dir) * normal - light.dir;
        vec3 eyeDir = ray.o - i;

        reflection = -normalize(reflection);
        eyeDir = normalize(eyeDir);

        float rDotE = max(dot(reflection, eyeDir), 0.0001);
        float specFactor = pow(rDotE, sphere.shininess);
        vec3 specColor = light.col * specFactor;

        vec3 sphereColour =  lambert + specColor + ambient * sphere.albedo;

        col = vec3(sphereColour);
    }



    // Output to screen
    fragColor = vec4(col,1.0);


}