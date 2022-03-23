#define GLSLIFY 1
vec2 InitializeScreenSpace(vec2 fragCoord, float offset)
{
    return (fragCoord - offset * iResolution.xy) / iResolution.y;
}

// Camera Stuff:
const vec3 worldUp = vec3(0., 1., 0.);

struct Camera
{
    vec3 forward;
    vec3 right;
    vec3 up;
    vec3 pos;
    vec3 rot;
    vec3 lookAt;
    float zoom;
    float fov;
};

void InitializeCamera(inout Camera cam)
{
    cam.forward = normalize(cam.lookAt - cam.pos);
    cam.right = cross(worldUp, cam.forward);
    cam.up = cross(cam.forward, cam.right);
}

Camera SetUpCamera(vec3 p, vec3 l, float z)
{
    Camera cam;

    cam.pos = p;
    cam.lookAt = l;
    cam.zoom = z;

    InitializeCamera(cam);

    return cam;
}

void SetUpDefaultCamera(inout Camera cam)
{
    cam.pos = vec3(0., 0., 0.);
    cam.lookAt = vec3(0., 0., 0.);
    cam.zoom = 0.;

    InitializeCamera(cam);
}

void ConstructCamera(vec2 uv, inout Camera cam)
{
    cam.forward = normalize(cam.lookAt - cam.pos);
    cam.right = normalize(cross(worldUp, cam.forward));
    cam.up = cross(cam.forward, cam.right);
}

struct Ray
{
    vec3 o;
    vec3 d;
};

void ConstructRayFromCamera(Camera cam, vec2 uv, inout Ray ray)
{
    vec3 screenCentre = cam.pos + cam.forward * cam.zoom;
    vec3 screenCoord = screenCentre + uv.x * cam.right + uv.y * cam.up;
    ray.o = cam.pos;
    ray.d = normalize(screenCoord - cam.pos);
}
