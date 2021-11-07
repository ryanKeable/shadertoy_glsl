
float Remap01(float a, float b, float value)
{
    // if compare == a return 0 if compare == b return 1
    return(value - a) / (b - a);
}
