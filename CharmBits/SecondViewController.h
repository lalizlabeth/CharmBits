//
//  SecondViewController.h
//  CharmBits
//
//  Created by Elizabeth Lin on 12/1/14.
//  Copyright (c) 2014 Elizabeth Lin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <opencv2/imgproc/imgproc_c.h>

@interface SecondViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>
{

    __weak IBOutlet UIImageView *cameraView;
    __weak IBOutlet UISlider *_slider;
    
    AVCaptureSession *_session;
    AVCaptureDevice *_captureDevice;
}

//@property (weak, nonatomic) IBOutlet UIImageView *cameraView;

- (UIImage*)getUIImageFromIplImage:(IplImage *)iplImage;
- (void)didCaptureIplImage:(IplImage *)iplImage;
- (void)didFinishProcessingImage:(IplImage *)iplImage;

- (IBAction)takePhoto:(id)sender;
- (IBAction)selectPhoto:(id)sender;


@end