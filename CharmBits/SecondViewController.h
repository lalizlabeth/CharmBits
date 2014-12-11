//
//  SecondViewController.h
//  CharmBits
//
//  Created by Elizabeth Lin on 12/1/14.
//  Copyright (c) 2014 Elizabeth Lin. All r ights reserved.
//

#import <UIKit/UIKit.h>

@interface SecondViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{

}

@property (weak, nonatomic) IBOutlet UIImageView *cameraView;

- (IBAction)takePhoto:(id)sender;
- (IBAction)selectPhoto:(id)sender;

@end

