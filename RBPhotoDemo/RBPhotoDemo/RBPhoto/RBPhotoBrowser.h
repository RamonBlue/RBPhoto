//
//  RBPhoto.h
//  Photo
//
//  Created by Ran on 16/4/8.
//  Copyright © 2016年 Justice. All rights reserved.

#import <UIKit/UIKit.h>
#import "RBPhotoModel.h"
#import "RBPhotoViewController.h"
#import "RBPhotoNavigationController.h"

typedef enum{
    RBPhotoShowStylePush,
    RBPhotoShowStylePresent,
    RBPhotoShowStyleZoom,
    RBPhotoShowStyleCustom
} RBPhotoShowStyle;

@class RBPhotoBrowser;
@protocol RBPhotoDelegate <NSObject>
- (void)rbPhoto:(nonnull RBPhotoBrowser *)photo didScrollToIndex:(CGFloat)index withPhotoController: (nonnull RBPhotoViewController *)controller;
- (void)rbPhoto:(nonnull RBPhotoBrowser *)photo willBeginDraggingwithPhotoController: (nonnull RBPhotoViewController *)controller;
- (void)rbPhoto: (nonnull RBPhotoBrowser *)photo longPressGesture: (nullable UILongPressGestureRecognizer *)gesture atPhotoView: (nonnull RBPhotoView *)photoView withPhotoController: (nonnull RBPhotoViewController *)controller;
@end

@interface RBPhotoBrowser : NSObject

@property(nonatomic, strong, nullable)NSArray<UIImageView *> *imageViews;
@property(nonatomic, strong, nonnull)NSArray<RBPhotoModel *> *photoModels;
@property(nonatomic, assign)NSInteger startIndex;
@property(nonatomic, assign)RBPhotoShowStyle showStyle;
@property(nonatomic, strong, nullable)UIViewController *fromController;
@property(nonatomic, weak)id<RBPhotoDelegate>delegate;

/**
 *  show photo browser
 *
 *  @param block: set nil except RBPhotoShowStyleCustom
 */
- (void)showWithCustomBlock: (void(^ __nullable)( RBPhotoViewController * _Nullable controller))block;

@end
