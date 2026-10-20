// Real OpenCV 4.14 C ABI for the unchanged Python layout verifier on iOS.
// No image/network/model ownership. Each returned buffer has an explicit owner.
#include <opencv2/core.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/features2d.hpp>
#include <opencv2/calib3d.hpp>
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>
#include <memory>
#include <string>
#include <vector>

#define API extern "C" __attribute__((visibility("default")))
static thread_local std::string failure;
struct Features { int count; float *xy; float *descriptors; float *metadata; };
struct Matches { int count; int queries; int *offsets; int *query; int *train; float *distance; };

static void require(bool value, const char *message) {
    if (!value) throw std::invalid_argument(message);
}
static cv::Mat points(const float *data, int count) {
    require(count >= 0 && count <= 50000 && (data || !count), "Invalid point buffer");
    return cv::Mat(count, 1, CV_32FC2, const_cast<float *>(data));
}
API const char *wg_version() { return CV_VERSION; }
API int wg_abi() { return 2; }
API const char *wg_error() { return failure.c_str(); }
API void wg_initialize() { cv::setNumThreads(1); }
API void wg_seed(int value) { cv::setRNGSeed(value); }
API int wg_gray(const uint8_t *rgb, int width, int height, uint8_t *gray) {
    try {
        require(rgb && gray && width > 0 && height > 0 && int64_t(width)*height <= 4000000, "Invalid RGB buffer");
        cv::Mat source(height,width,CV_8UC3,const_cast<uint8_t *>(rgb));
        cv::Mat output(height,width,CV_8UC1,gray);
        cv::cvtColor(source,output,cv::COLOR_RGB2GRAY); return 1;
    } catch (const std::exception &error) { failure=error.what(); return -1; }
}
API Features *wg_sift(const uint8_t *gray, int width, int height, int limit) {
    try {
        require(gray && width>0 && height>0 && int64_t(width)*height<=4000000 && limit>0 && limit<=10000,"Invalid SIFT input");
        cv::Mat image(height,width,CV_8UC1,const_cast<uint8_t *>(gray)), descriptors;
        std::vector<cv::KeyPoint> keypoints;
        cv::SIFT::create(limit)->detectAndCompute(image,cv::noArray(),keypoints,descriptors);
        require(keypoints.size()<=50000,"SIFT output exceeded the finite buffer bound");
        auto out=std::make_unique<Features>(); out->count=int(keypoints.size());
        auto xy=std::make_unique<float[]>(out->count*2);
        auto values=std::make_unique<float[]>(out->count*128);
        auto metadata=std::make_unique<float[]>(out->count*4);
        for (int i=0;i<out->count;i++) {
            xy[2*i]=keypoints[i].pt.x; xy[2*i+1]=keypoints[i].pt.y;
            metadata[4*i]=keypoints[i].size; metadata[4*i+1]=keypoints[i].angle;
            metadata[4*i+2]=keypoints[i].response; metadata[4*i+3]=float(keypoints[i].octave);
        }
        if (out->count) {
            require(descriptors.type()==CV_32F && descriptors.cols==128 && descriptors.rows==out->count,"Unexpected SIFT descriptor shape");
            for (int row=0;row<out->count;row++) std::copy_n(descriptors.ptr<float>(row),128,values.get()+row*128);
        }
        out->xy=xy.release(); out->descriptors=values.release(); out->metadata=metadata.release(); return out.release();
    } catch (const std::exception &error) { failure=error.what(); return nullptr; }
}
API void wg_free_features(Features *value) {
    if (value) { delete[] value->xy; delete[] value->descriptors; delete[] value->metadata; delete value; }
}
API Matches *wg_match(const float *query,int nq,const float *reference,int nr,int k) {
    try {
        require(nq>=0 && nr>=0 && nq<=50000 && nr<=50000 && k==2 && (query||!nq) && (reference||!nr),"Invalid descriptor buffers");
        cv::Mat q(nq,128,CV_32F,const_cast<float *>(query)),r(nr,128,CV_32F,const_cast<float *>(reference));
        std::vector<std::vector<cv::DMatch>> rows;
        cv::BFMatcher(cv::NORM_L2,false).knnMatch(q,r,rows,k);
        auto out=std::make_unique<Matches>(); out->queries=int(rows.size());out->count=0;
        for (const auto &row:rows) out->count+=int(row.size());
        auto offsets=std::make_unique<int[]>(rows.size()+1),qs=std::make_unique<int[]>(out->count),rs=std::make_unique<int[]>(out->count);
        auto distances=std::make_unique<float[]>(out->count); int cursor=0;
        for (int i=0;i<out->queries;i++) {
            offsets[i]=cursor;
            for (const auto &match:rows[i]) { qs[cursor]=match.queryIdx;rs[cursor]=match.trainIdx;distances[cursor]=match.distance;cursor++; }
        }
        offsets[out->queries]=cursor;out->offsets=offsets.release();out->query=qs.release();out->train=rs.release();out->distance=distances.release();return out.release();
    } catch (const std::exception &error) { failure=error.what(); return nullptr; }
}
API void wg_free_matches(Matches *value) {
    if (value) { delete[] value->offsets;delete[] value->query;delete[] value->train;delete[] value->distance;delete value; }
}
API int wg_homography(const float *source,const float *destination,int count,int method,double reprojection,double *h,uint8_t *mask) {
    try {
        require(h && mask && method==cv::RANSAC && std::isfinite(reprojection) && reprojection>0,"Invalid homography request");
        cv::Mat inliers;
        auto matrix=cv::findHomography(points(source,count),points(destination,count),method,reprojection,inliers);
        if (matrix.empty()) return 0;
        require(matrix.type()==CV_64F && matrix.total()==9 && inliers.total()==size_t(count),"Unexpected homography output");
        std::copy_n(matrix.ptr<double>(),9,h);std::copy_n(inliers.ptr<uint8_t>(),count,mask);return 1;
    } catch (const std::exception &error) { failure=error.what();return -1; }
}
API int wg_hull(const float *source,int count,float *out,int *length) {
    try {
        require(out && length,"Missing hull output buffer");cv::Mat result;
        cv::convexHull(points(source,count),result);
        *length=int(result.total());if (*length) std::copy_n(result.ptr<float>(),*length*2,out);return 1;
    } catch (const std::exception &error) { failure=error.what();return -1; }
}
API double wg_area(const float *source,int count) {
    try { return cv::contourArea(points(source,count)); }
    catch (const std::exception &error) { failure=error.what();return std::numeric_limits<double>::quiet_NaN(); }
}
API int wg_convex(const float *source,int count) {
    try { return cv::isContourConvex(points(source,count))?1:0; }
    catch (const std::exception &error) { failure=error.what();return -1; }
}
API int wg_perspective(const float *source,int count,const double *h,float *out) {
    try {
        require(h && out,"Missing perspective matrix/output buffer");
        cv::Mat matrix(3,3,CV_64F,const_cast<double *>(h)),destination(count,1,CV_32FC2,out);
        cv::perspectiveTransform(points(source,count),destination,matrix);return 1;
    } catch (const std::exception &error) { failure=error.what();return -1; }
}
