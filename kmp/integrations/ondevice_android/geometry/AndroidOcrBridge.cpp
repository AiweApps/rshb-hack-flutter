// PaddleX DBPostProcess/CropByPolys quad semantics, with real OpenCV + Clipper.
// No model, network or image ownership beyond explicitly returned crop buffers.
// Algorithm attribution: PaddlePaddle/PaddleX (Apache-2.0).
#include "AndroidOcrBridge.h"
#include "clipper/clipper.hpp"
#include <opencv2/core.hpp>
#include <opencv2/imgproc.hpp>
#include <algorithm>
#include <array>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <stdexcept>
#include <string>
#include <vector>

#define API extern "C" __attribute__((visibility("default")))
static thread_local std::string ocr_failure;
static void check(bool condition, const char *message) {
    if (!condition) throw std::invalid_argument(message);
}
static void dimensions(int w, int h) {
    check(w > 0 && h > 0 && int64_t(w) * h <= 24000000, "Invalid OCR image dimensions");
}
using Quad = std::array<cv::Point2f, 4>;
static Quad mini_box(const cv::Mat &contour, float &side) {
    auto rect = cv::minAreaRect(contour);
    cv::Mat output;
    // boxPoints uses the same implementation as cv2.boxPoints, including rounding.
    cv::boxPoints(rect, output);
    Quad p;
    std::copy_n(output.ptr<cv::Point2f>(), 4, p.begin());
    std::stable_sort(p.begin(), p.end(), [](auto a, auto b) { return a.x < b.x; });
    int a=0, b=1, c=2, d=3;
    if (p[1].y > p[0].y) { a=0; d=1; } else { a=1; d=0; }
    if (p[3].y > p[2].y) { b=2; c=3; } else { b=3; c=2; }
    side = std::min(rect.size.width, rect.size.height);
    return {p[a], p[b], p[c], p[d]};
}
static double score_fast(const cv::Mat &prob, const Quad &box) {
    float xmin=box[0].x, xmax=xmin, ymin=box[0].y, ymax=ymin;
    for (auto p: box) { xmin=std::min(xmin,p.x); xmax=std::max(xmax,p.x);
        ymin=std::min(ymin,p.y); ymax=std::max(ymax,p.y); }
    int x0=std::clamp(int(std::floor(xmin)),0,prob.cols-1);
    int x1=std::clamp(int(std::ceil(xmax)),0,prob.cols-1);
    int y0=std::clamp(int(std::floor(ymin)),0,prob.rows-1);
    int y1=std::clamp(int(std::ceil(ymax)),0,prob.rows-1);
    cv::Mat mask=cv::Mat::zeros(y1-y0+1,x1-x0+1,CV_8U);
    std::vector<cv::Point> integer;
    // NumPy astype(int32) truncates toward zero, rather than cv::Point rounding.
    for (auto p: box) integer.emplace_back(int(p.x-x0),int(p.y-y0));
    cv::fillPoly(mask,std::vector<std::vector<cv::Point>>{integer},cv::Scalar(1));
    return cv::mean(prob(cv::Rect(x0,y0,x1-x0+1,y1-y0+1)),mask)[0];
}
API const char *wine_ocr_error() { return ocr_failure.c_str(); }
API void wine_ocr_free(void *value) { std::free(value); }
API int wine_ocr_db_boxes(const float *data,int h,int w,int src_w,int src_h,
    double threshold,double box_threshold,double ratio,int max_candidates,float *out,int capacity) {
    try {
        dimensions(w,h); dimensions(src_w,src_h);
        check(data && out && max_candidates>0 && max_candidates<=3000 && capacity>=max_candidates,
            "Invalid DB buffers or finite candidate bound");
        check(std::isfinite(threshold) && threshold>=0 && threshold<=1 &&
            std::isfinite(box_threshold) && box_threshold>=0 && box_threshold<=1 &&
            std::isfinite(ratio) && ratio>0 && ratio<=10,"Invalid DB parameters");
        cv::Mat prob(h,w,CV_32F,const_cast<float *>(data)), bitmap;
        cv::compare(prob,threshold,bitmap,cv::CMP_GT);
        std::vector<std::vector<cv::Point>> contours;
        cv::findContours(bitmap,contours,cv::RETR_LIST,cv::CHAIN_APPROX_SIMPLE);
        int count=0;
        const double width_scale=double(src_w)/w, height_scale=double(src_h)/h;
        for (int i=0;i<std::min(int(contours.size()),max_candidates);i++) {
            float side;
            Quad box=mini_box(cv::Mat(contours[i]),side);
            if (side<3 || score_fast(prob,box)<double(box_threshold)) continue;
            cv::Mat box_mat(4,1,CV_32FC2,box.data());
            double perimeter=cv::arcLength(box_mat,true);
            if (perimeter<=0) continue;
            double distance=cv::contourArea(box_mat)*double(ratio)/perimeter;
            ClipperLib::Path path;
            for (auto p:box) path.emplace_back(ClipperLib::cInt(p.x),ClipperLib::cInt(p.y));
            ClipperLib::ClipperOffset offset;
            offset.AddPath(path,ClipperLib::jtRound,ClipperLib::etClosedPolygon);
            ClipperLib::Paths expanded;
            offset.Execute(expanded,distance);
            if (expanded.empty()) continue;
            // PaddleX flattens equal-size paths; on ragged output it uses path zero.
            bool rectangular=true;
            for (const auto &p:expanded) rectangular &= p.size()==expanded[0].size();
            std::vector<cv::Point2f> points;
            for (size_t j=0;j<(rectangular?expanded.size():1);j++)
                for (auto p:expanded[j]) points.emplace_back(float(p.X),float(p.Y));
            box=mini_box(cv::Mat(points),side);
            if (side<5) continue;
            for (int j=0;j<4;j++) {
                // Python round(float32 * Python scale) uses ties-to-even.
                out[count*8+j*2]=float(std::clamp(std::nearbyint(double(box[j].x)*width_scale),0.0,double(src_w)));
                out[count*8+j*2+1]=float(std::clamp(std::nearbyint(double(box[j].y)*height_scale),0.0,double(src_h)));
            }
            count++;
        }
        return count;
    } catch (const std::exception &error) { ocr_failure=error.what(); return -1; }
}
API int wine_ocr_warp_rgb(const uint8_t *rgb,int w,int h,const float *quad,
    uint8_t **out,int *out_w,int *out_h) {
    if (out) *out=nullptr;
    try {
        dimensions(w,h); check(rgb && quad && out && out_w && out_h,"Missing crop buffer");
        std::vector<cv::Point> integer;
        for (int i=0;i<4;i++) {
            check(std::isfinite(quad[i*2]) && std::isfinite(quad[i*2+1]) &&
                std::abs(quad[i*2])<=100000 && std::abs(quad[i*2+1])<=100000,"Invalid crop quad");
            integer.emplace_back(int(quad[2*i]),int(quad[2*i+1]));
        }
        float side; Quad points=mini_box(cv::Mat(integer),side);
        auto norm=[](cv::Point2f a,cv::Point2f b) { auto d=a-b; return std::sqrt(d.x*d.x+d.y*d.y); };
        int cw=int(std::max(norm(points[0],points[1]),norm(points[2],points[3])));
        int ch=int(std::max(norm(points[0],points[3]),norm(points[1],points[2])));
        dimensions(cw,ch);
        Quad target={cv::Point2f(0,0),cv::Point2f(float(cw),0),cv::Point2f(float(cw),float(ch)),cv::Point2f(0,float(ch))};
        auto matrix=cv::getPerspectiveTransform(points.data(),target.data());
        cv::Mat source(h,w,CV_8UC3,const_cast<uint8_t *>(rgb)),crop;
        cv::warpPerspective(source,crop,matrix,cv::Size(cw,ch),cv::INTER_CUBIC,cv::BORDER_REPLICATE);
        if (double(ch)/cw>=1.5) cv::rotate(crop,crop,cv::ROTATE_90_COUNTERCLOCKWISE);
        size_t bytes=crop.total()*crop.elemSize();
        auto buffer=static_cast<uint8_t *>(std::malloc(bytes));
        if (!buffer) throw std::bad_alloc();
        std::memcpy(buffer,crop.data,bytes);
        *out=buffer; *out_w=crop.cols; *out_h=crop.rows; return 1;
    } catch (const std::exception &error) { ocr_failure=error.what(); return -1; }
}
API int wine_ocr_resize_rgb(const uint8_t *rgb,int w,int h,int out_w,int out_h,uint8_t *out) {
    try {
        dimensions(w,h); dimensions(out_w,out_h); check(rgb && out,"Missing resize buffer");
        cv::Mat source(h,w,CV_8UC3,const_cast<uint8_t *>(rgb)),target(out_h,out_w,CV_8UC3,out);
        cv::resize(source,target,cv::Size(out_w,out_h),0,0,cv::INTER_LINEAR); return 1;
    } catch (const std::exception &error) { ocr_failure=error.what(); return -1; }
}
