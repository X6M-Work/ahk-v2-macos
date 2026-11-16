#include <stdio.h>

int parse_float(const char *text, float *output)
{
    if (text == NULL || output == NULL)
        return -1;

    return sscanf(text, "%f", output);
}
