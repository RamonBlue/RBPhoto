//
//  RBPhotoNavigationController.m
//  GCPhotoPicker
//
//  Created by Ran on 16/4/12.
//  Copyright © 2016年 Justice. All rights reserved.
//

#import "RBPhotoNavigationController.h"

@implementation RBPhotoNavigationController

#pragma mark - Rotation

- (BOOL)shouldAutorotate
{
    return self.topViewController.shouldAutorotate;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.topViewController supportedInterfaceOrientations];
}

@end
