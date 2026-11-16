#include <stddef.h>
#include <stdint.h>
#include <string.h>

double mix_and_invoke(
    int64_t a,
    double b,
    float c,
    const char *label,
    int32_t d,
    double e,
    int64_t *out_sum,
    double *out_prod,
    double (*cb)(int64_t, double, float, int32_t))
{
    if (label == NULL || out_sum == NULL || out_prod == NULL || cb == NULL)
        return -1.0;

    int64_t len = (int64_t)strlen(label);
    *out_sum = a + (int64_t)d + len;
    *out_prod = b * e + (double)c;
    double cb_ret = cb(a + len, b + e, c + 0.5f, d + 1);
    return cb_ret + 0.25;
}
