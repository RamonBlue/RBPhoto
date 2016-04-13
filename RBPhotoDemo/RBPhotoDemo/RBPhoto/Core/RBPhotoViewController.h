//
//  RBPhotoViewController.h
//  Photo
//
//  Created by Ran on 16/4/4.
//  Copyright © 2016年 Justice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RBPhotoView.h"

@class RBPhotoViewController;
@protocol RBPhotoViewControllerDelegate <NSObject>

- (NSInteger)rbPhotoViewControllerPhotosCount: (RBPhotoViewController *)controller;

- (void)rbPhotoViewController: (RBPhotoViewController *)controller willShowPhotoView: (RBPhotoView *)photoView atIndex: (NSInteger)index;

@optional

- (void)rbPhotoViewController: (RBPhotoViewController *)controller didScrollToIndex: (CGFloat)index;

- (void)rbPhotoViewController: (RBPhotoViewController *)controller willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;

- (void)rbPhotoViewControllerWillBeginDragging:(RBPhotoViewController *)controller;

- (void)rbPhotoViewController: (RBPhotoViewController *)controller singleTap: (UITapGestureRecognizer *)gesture atPhotoView: (RBPhotoView *)photoView;

- (void)rbPhotoViewController: (RBPhotoViewController *)controller doubleTap: (UITapGestureRecognizer *)gesture atPhotoView: (RBPhotoView *)photoView;

- (void)rbPhotoViewController: (RBPhotoViewController *)controller longPress: (UILongPressGestureRecognizer *)gesture atPhotoView: (RBPhotoView *)photoView;

@end

@interface RBPhotoViewController : UIViewController

/**
*  0 by default
*/
@property(nonatomic, assign)NSInteger startIndex;
/**
 *  40.0 by default
 */
@property(nonatomic, assign)CGFloat marginBetweenPhotos;
/**
 *  UIInterfaceOrientationMaskAllButUpsideDown by default
 */
@property(nonatomic, assign)UIInterfaceOrientationMask interfaceOrientationMask;
@property(nonatomic, assign)Class imageViewClass;
@property(nonatomic, weak)id<RBPhotoViewControllerDelegate>delegate;

/**
 *  extension
 */
@property(nonatomic, strong)id s1;
@property(nonatomic, strong)id s2;
@property(nonatomic, weak)id w1;
@property(nonatomic, weak)id w2;
@property(nonatomic, copy)id c1;
@property(nonatomic, copy)id c2;

@end
