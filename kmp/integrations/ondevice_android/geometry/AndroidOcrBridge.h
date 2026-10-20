#pragma once
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
// DB output is capacity quads, each (top-left, top-right, bottom-right, bottom-left),
// 8 float values in source-image pixels. Returns quad count or -1 on error.
int wine_ocr_db_boxes(const float *prob, int h, int w, int src_w, int src_h,
    double bitmap_threshold, double box_threshold, double unclip_ratio,
    int max_candidates, float *out_quads, int capacity);
// CropByPolys(quad): integer minAreaRect, cubic/replicate warp, portrait rot90.
// RGB and BGR are both supported: channels are preserved. Caller frees *out.
int wine_ocr_warp_rgb(const uint8_t *rgb, int w, int h, const float *quad,
    uint8_t **out, int *out_w, int *out_h);
// OpenCV INTER_LINEAR; caller owns out_w*out_h*3 bytes.
int wine_ocr_resize_rgb(const uint8_t *rgb, int w, int h, int out_w, int out_h,
    uint8_t *out);
const char *wine_ocr_error(void);
void wine_ocr_free(void *value);
#ifdef __cplusplus
}
#endif
