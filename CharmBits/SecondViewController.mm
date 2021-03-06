//
//  SecondViewController.m
//  CharmBits
//
//  Created by Elizabeth Lin on 12/1/14.
//  Copyright (c) 2014 Elizabeth Lin. All rights reserved.
//

#import "SecondViewController.h"

#import <opencv2/imgproc/imgproc_c.h>
#import <opencv2/objdetect/objdetect.hpp>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#import "opencv2/opencv.hpp"


using namespace std;
using namespace cv;

@implementation SecondViewController

//NO shows RGB image and highlights found circles
//YES shows threshold image
static BOOL _debug = NO;

#pragma mark - View


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupCamera];
    [self turnCameraOn];
}


- (void)viewDidUnload
{
    cameraView = nil;
    [super viewDidUnload];
}


#pragma mark - Capture


- (void)setupCamera
{
    _captureDevice = nil;
    
    if (!_captureDevice)
        _captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
}


- (void)turnCameraOn
{
    NSError *error;
    
     _session = [[AVCaptureSession alloc] init];
    [_session beginConfiguration];
    [_session setSessionPreset:AVCaptureSessionPresetMedium];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:&error];
    
    if (input == nil)
        NSLog(@"%@", error);
    
    [_session addInput:input];
    
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [output setSampleBufferDelegate:self queue:dispatch_queue_create("myQueue", NULL)];
    output.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
    output.alwaysDiscardsLateVideoFrames = YES;
    
    [_session addOutput:output];
    
    [_session commitConfiguration];
    [_session startRunning];
}


- (void)turnCameraOff
{
    [_session stopRunning];
    _session = nil;
}


- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    IplImage *iplimage;
    if (baseAddress)
    {
        iplimage = cvCreateImageHeader(cvSize(width, height), IPL_DEPTH_8U, 4);
        iplimage->imageData = (char*)baseAddress;
    }
    
    IplImage *workingCopy = cvCreateImage(cvSize(height, width), IPL_DEPTH_8U, 4);
    
    cvTranspose(iplimage, workingCopy);
    cvFlip(workingCopy, nil, 1);
    
    cvReleaseImageHeader(&iplimage);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    [self didCaptureIplImage:workingCopy];
}


#pragma mark - Image processing


static void ReleaseDataCallback(void *info, const void *data, size_t size)
{
//    IplImage *iplImage = info;
//    cvReleaseImage(&iplImage);
}


- (CGImageRef)getCGImageFromIplImage:(IplImage*)iplImage
{
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = iplImage->widthStep;
    
    size_t bitsPerPixel;
    CGColorSpaceRef space;
    
    if (iplImage->nChannels == 1)
    {
        bitsPerPixel = 8;
        space = CGColorSpaceCreateDeviceGray();
    }
    else if (iplImage->nChannels == 3)
    {
        bitsPerPixel = 24;
        space = CGColorSpaceCreateDeviceRGB();
    }
    else if (iplImage->nChannels == 4)
    {
        bitsPerPixel = 32;
        space = CGColorSpaceCreateDeviceRGB();
    }
    else
    {
        abort();
    }
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNone;
    CGDataProviderRef provider = CGDataProviderCreateWithData(iplImage,
                                                              iplImage->imageData,
                                                              0,
                                                              ReleaseDataCallback);
    const CGFloat *decode = NULL;
    bool shouldInterpolate = true;
    CGColorRenderingIntent intent = kCGRenderingIntentDefault;
    
    CGImageRef cgImageRef = CGImageCreate(iplImage->width,
                                          iplImage->height,
                                          bitsPerComponent,
                                          bitsPerPixel,
                                          bytesPerRow,
                                          space,
                                          bitmapInfo,
                                          provider,
                                          decode,
                                          shouldInterpolate,
                                          intent);
    CGColorSpaceRelease(space);
    CGDataProviderRelease(provider);
    return cgImageRef;
}


- (UIImage*)getUIImageFromIplImage:(IplImage*)iplImage
{
    CGImageRef cgImage = [self getCGImageFromIplImage:iplImage];
    UIImage *uiImage = [[UIImage alloc] initWithCGImage:cgImage
                                                  scale:1.0
                                            orientation:UIImageOrientationUp];
    
    CGImageRelease(cgImage);
    return uiImage;
}

- (void)didFinishProcessingImage:(IplImage *)iplImage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *uiImage = [self getUIImageFromIplImage:iplImage];
        cameraView.image = uiImage;
    });
}

- (void)didCaptureIplImage:(IplImage *)iplImage
{
    IplImage *rgbImage = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplImage, rgbImage, CV_BGR2RGB);
    cvReleaseImage(&iplImage);
    
    [self didFinishProcessingImage:rgbImage];
    
//    //ipl image is in BGR format, it needs to be converted to RGB for display in UIImageView
//    IplImage *imgRGB = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 3);
//    cvCvtColor(iplImage, imgRGB, CV_BGR2RGB);
//    Mat matRGB = Mat(imgRGB);
//    
//    //ipl image is also converted to HSV; hue is used to find certain color
//    IplImage *imgHSV = cvCreateImage(cvGetSize(iplImage), 8, 3);
//    cvCvtColor(iplImage, imgHSV, CV_BGR2HSV);
//    
//    IplImage *imgThreshed = cvCreateImage(cvGetSize(iplImage), 8, 1);
//    
//    //it is important to release all images EXCEPT the one that is going to be passed to
//    //the didFinishProcessingImage: method and displayed in the UIImageView
//    cvReleaseImage(&iplImage);
//    
//    //filter all pixels in defined range, everything in range will be white, everything else
//    //is going to be black
////    cvInRangeS(imgHSV, cvScalar(_min, 100, 100), cvScalar(_max, 255, 255), imgThreshed);
//        cvInRangeS(imgHSV, cvScalar(0, 100, 100), cvScalar(0, 255, 255), imgThreshed);
//    
//    cvReleaseImage(&imgHSV);
//    
//    Mat matThreshed = Mat(imgThreshed);
//    
//    //smooths edges
//    cv::GaussianBlur(matThreshed,
//                     matThreshed,
//                     cv::Size(9, 9),
//                     2,
//                     2);
    
    //debug shows threshold image, otherwise the circles are detected in the
    //threshold image and shown in the RGB image
//    if (_debug)
//    {
//        cvReleaseImage(&imgRGB);
//        [self didFinishProcessingImage:imgThreshed];
//    }
//    else
//    {
//        vector<Vec3f> circles;
//        
//        //get circles
//        HoughCircles(matThreshed,
//                     circles,
//                     CV_HOUGH_GRADIENT,
//                     2,
//                     matThreshed.rows / 4,
//                     150,
//                     75,
//                     10,
//                     150);
//        
//        for (size_t i = 0; i < circles.size(); i++)
//        {
//            cout << "Circle position x = " << (int)circles[i][0] << ", y = " << (int)circles[i][1] << ", radius = " << (int)circles[i][2] << "\n";
//            
//            cv::Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
//            
//            int radius = cvRound(circles[i][2]);
//            
//            circle(matRGB, center, 3, Scalar(0, 255, 0), -1, 8, 0);
//            circle(matRGB, center, radius, Scalar(0, 0, 255), 3, 8, 0);
//        }
//        
//        //threshed image is not needed any more and needs to be released
//        cvReleaseImage(&imgThreshed);
//        
//        //imgRGB will be released once it is not needed, the didFinishProcessingImage:
//        //method will take care of that
//        [self didFinishProcessingImage:imgRGB];
//    }
}


@end
