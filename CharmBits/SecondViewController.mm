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


using namespace std;
using namespace cv;

@implementation SecondViewController

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
//    AVCaptureVideoOrientation orientation;

    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
//    
//    for (AVCaptureDevice *device in videoDevices)
//    {
//        if (device.orientation == AVCaptureVideoOrientationLandscapeRight)
//        {
//            _captureDevice = device;
//            break;
//        }
//    }

    
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
#pragma unused(data)
#pragma unused(size)
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


#pragma mark - Captured Ipl Image


- (void)didCaptureIplImage:(IplImage *)iplImage
{
    IplImage *rgbImage = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplImage, rgbImage, CV_BGR2RGB);
    cvReleaseImage(&iplImage);
    
    [self didFinishProcessingImage:rgbImage];
}


#pragma mark - didFinishProcessingImage


- (void)didFinishProcessingImage:(IplImage *)iplImage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *uiImage = [self getUIImageFromIplImage:iplImage];
        cameraView.image = uiImage;
    });
}


- (IBAction)takePhoto:(id)sender {
//    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
//    picker.delegate = self;
//    picker.allowsEditing = YES;
//    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
//    
//    [self presentViewController:picker animated:YES completion:NULL];
}

- (IBAction)selectPhoto:(id)sender {
}

@end
