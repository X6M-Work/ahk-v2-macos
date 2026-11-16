#include <stdint.h>

float sum_spilled_args(
    int32_t i0, int32_t i1, int32_t i2, int32_t i3,
    int32_t i4, int32_t i5, int32_t i6, int32_t i7,
    int32_t i8, int16_t s9, int8_t c10, uint8_t u11,
    float f0, float f1, float f2, float f3,
    float f4, float f5, float f6, float f7,
    float f8, double d9,
    int64_t (*cb)(
        int32_t, int32_t, int32_t, int32_t,
        int32_t, int32_t, int32_t, int32_t,
        int32_t, int16_t, int8_t, uint8_t),
    int64_t *out_cb_ret)
{
    if (cb != 0 && out_cb_ret != 0)
        *out_cb_ret = cb(i0, i1, i2, i3, i4, i5, i6, i7, i8, s9, c10, u11);

    int32_t isum = i0 + i1 + i2 + i3 + i4 + i5 + i6 + i7 + i8 + (int32_t)s9 + (int32_t)c10 + (int32_t)u11;
    double fsum = (double)f0 + (double)f1 + (double)f2 + (double)f3 + (double)f4 + (double)f5 + (double)f6 + (double)f7 + (double)f8 + d9;
    return (float)((double)isum + fsum);
}
