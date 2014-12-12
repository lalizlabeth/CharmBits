//
//  FirstViewController.m
//  CharmBits
//
//  Created by Elizabeth Lin on 12/1/14.
//  Copyright (c) 2014 Elizabeth Lin. All rights reserved.
//

#import "FirstViewController.h"
#import "SecondViewController.h"

@interface FirstViewController ()

@end

@implementation FirstViewController
@synthesize imageView;

- (IBAction)lesson1 {
//    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Clicked button 1"
//                                                   message: @"Alert Message here"
//                                                  delegate: self
//                                         cancelButtonTitle:@"Cancel"
//                                         otherButtonTitles:@"OK",nil];
//    
//    [alert setTag:1];
//    [alert show];
//    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (BOOL)hidesBottomBarWhenPushed {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end