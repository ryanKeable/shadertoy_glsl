const float M_PI = 3.14159265358979323846264338327950288;
const float M_PI_2 = 6.28318530718;

float mod01(float value)
{
    return mod(value, 1.0);
}

float loopTime(float speed)
{
    return mod01(iTime * speed);
}

float loopTime(float speed, float duration)
{
    return mod(iTime * speed, duration);
}

float sinTime(float speed)
{
    return sin(iTime * speed);
}

float cosTime(float speed)
{
    return cos(iTime * speed);
}

float easeOutCubic(float value)
{
    return 1.0 - pow(1.0 - value, 3.0);
}