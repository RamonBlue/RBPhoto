//
//  RBPhoto.m
//  Photo
//
//  Created by Ran on 16/4/8.
//  Copyright © 2016年 Justice. All rights reserved.
//

#import "RBPhotoBrowser.h"
#import "UIImageView+WebCache.h"
#import "SDWebImagePrefetcher.h"
#import "MBProgressHUD.h"
#import "FLAnimatedImageView+WebCache.h"
#import "FLAnimatedImage.h"

#define RBMainScreenBounds  [UIScreen mainScreen].bounds
#define RBMainScreenSize    RBMainScreenBounds.size
#define RBMainScreenWidth   RBMainScreenSize.width
#define RBMainScreenHeight  RBMainScreenSize.height

/**RBPhotoShowStyleZoom: size = ScreenSize * factor, center = ScreenCenter*/
static const CGFloat DEFAULT_ZOOM_FACTOR = 0.1;

@interface RBPhotoBrowser()<RBPhotoViewControllerDelegate>

@property(nonatomic, weak)UIView *sourceView;
@property(nonatomic, weak)UIViewController *photoController;
@property(nonatomic, assign, getter=isFirstShow)BOOL firstShow;
@property(nonatomic, assign)UIInterfaceOrientation fromOrientation;

@end

@implementation RBPhotoBrowser

#pragma mark - Public

- (void)showWithCustomBlock:(void (^)(RBPhotoViewController * _Nullable))block
{
    if (self.photoModels.count <= 0) {
        return;
    }
    NSMutableArray *URLs = [NSMutableArray arrayWithCapacity:self.photoModels.count];
    for (RBPhotoModel *model in self.photoModels)
    {
        if (model.imageURLString.length)
        {
            [URLs addObject:[NSURL URLWithString:model.imageURLString]];
        }
    }
    [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:URLs];
    
    self.firstShow = YES;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.firstShow = NO;
    });
    RBPhotoViewController *photoController = [RBPhotoViewController new];
    self.photoController = photoController;
    photoController.imageViewClass = [FLAnimatedImageView class];
    photoController.delegate = self;
    photoController.startIndex = self.startIndex;
    
    switch (self.showStyle)
    {
        case RBPhotoShowStylePush:
        {
            [self.fromController.navigationController pushViewController:photoController animated:YES];
        }
            break;
        case RBPhotoShowStylePresent:
        {
            RBPhotoNavigationController *navigationController = [[RBPhotoNavigationController alloc] initWithRootViewController:photoController];
            photoController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
            [self.fromController presentViewController:navigationController animated:YES completion:nil];
        }
            break;
        case RBPhotoShowStyleZoom:
        {
            self.fromOrientation = self.fromController.interfaceOrientation;
            [self.keyWindow addSubview:photoController.view];
            [self.fromController.navigationController? self.fromController.navigationController: self.fromController addChildViewController:photoController];
            photoController.view.frame = RBMainScreenBounds;
        }
            break;
        case RBPhotoShowStyleCustom:
        {
            if (block) {
                block(photoController);
            }
        }
        default:
            break;
    }
}

- (void)dismiss
{
    [self.photoController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

- (UIView *)sourceImageViewAtIndex: (NSInteger)index
{
    return self.imageViews.count > index? self.imageViews[index]: nil;
}

- (CGRect)sourceImageViewFrameAtIndex: (NSInteger)index
{
    UIView *sourceView = [self sourceImageViewAtIndex:index];
    CGRect sourceFrame = sourceView? [self.keyWindow convertRect:sourceView.frame fromView:sourceView.superview]: CGRectMake(RBMainScreenWidth * (1 - DEFAULT_ZOOM_FACTOR) / 2, RBMainScreenHeight * (1 - DEFAULT_ZOOM_FACTOR) / 2, RBMainScreenWidth * DEFAULT_ZOOM_FACTOR, RBMainScreenHeight * DEFAULT_ZOOM_FACTOR);
    return sourceFrame;
}

- (void)setPhotoView: (RBPhotoView *)photoView withImage: (UIImage *)image
{
    //设置图片步骤删掉,只调整大小
    if (!image) return;
    ((FLAnimatedImageView *)photoView.imageView).runLoopMode = NSDefaultRunLoopMode;
    CGSize screenSize = RBMainScreenSize;
    CGSize imageSize = CGSizeZero;
    if (screenSize.width > screenSize.height)
    {//landscape
        imageSize.height = screenSize.height;
        imageSize.width = image.size.width * imageSize.height / image.size.height;
        photoView.maxZoomScale = MAX(2, screenSize.width / imageSize.width);
    }
    else
    {//portrait
        imageSize.width = screenSize.width;
        imageSize.height = image.size.height * imageSize.width / image.size.width;
        photoView.maxZoomScale = MAX(2, screenSize.height / imageSize.height);
    }
    photoView.imageSize = imageSize;
    [photoView resizeSubviews];
    if (self.showStyle == RBPhotoShowStyleZoom) {
        [self photoViewZoomIn:photoView];
    }
}

- (void)photoViewZoomIn: (RBPhotoView *)photoView
{
    if (self.isFirstShow)
    {
        self.firstShow = NO;
        CGRect sourceFrame = [self sourceImageViewFrameAtIndex:self.startIndex];
        CGRect destFrame = photoView.imageView.frame;
        
        photoView.imageView.frame = sourceFrame;
        photoView.imageView.contentMode = UIViewContentModeScaleAspectFill;
        photoView.imageView.clipsToBounds = YES;
        photoView.imageView.alpha = 1;
        [photoView.w1 setAlpha:0];
        
        [UIView animateWithDuration:0.3 animations:^{
            photoView.imageView.frame = destFrame;
        } completion:^(BOOL finished) {
            [photoView.w1 setAlpha:1];
        }];
        [UIView animateWithDuration:0.1 animations:^{
            self.photoController.view.backgroundColor = [UIColor blackColor];
        }];
    }
}

- (void)photoViewZoomOut: (RBPhotoView *)photoView
{
    CGFloat scrollViewZoomTime = photoView.scrollView.zoomScale == 1? 0: 0.2;
    [photoView.w1 setHidden:YES];
    photoView.w1 = nil;
    
    [UIView animateWithDuration:0.1 + scrollViewZoomTime animations:^{
        self.photoController.view.backgroundColor = [UIColor clearColor];
    }];
    [photoView.scrollView setZoomScale:1 animated:YES];
    [photoView.scrollView setContentOffset:CGPointZero];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(scrollViewZoomTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 animations:^{
            photoView.imageView.frame = [self sourceImageViewFrameAtIndex:photoView.tag];
        } completion:^(BOOL finished) {
            [self.photoController.view removeFromSuperview];
            [self.photoController removeFromParentViewController];
        }];
    });
}

- (CGFloat)maxZoomScaleWithImage: (UIImage *)image
{
    if (!image) {
        return 2;
    }
    
    CGFloat maxZoomScale = 2;
    CGSize imageSize = image.size;
    if (RBMainScreenWidth < RBMainScreenHeight)
    {
        maxZoomScale = RBMainScreenHeight / (imageSize.height * RBMainScreenWidth / imageSize.width);
    }else
    {
        maxZoomScale = RBMainScreenWidth / (imageSize.width * RBMainScreenHeight / imageSize.height);
    }
    return MAX(2, maxZoomScale);
}

#pragma mark - RBPhotoViewControllerDelegate

- (NSInteger)rbPhotoViewControllerPhotosCount:(RBPhotoViewController *)controller
{
    return self.photoModels.count;
}

- (void)rbPhotoViewController:(RBPhotoViewController *)controller willShowPhotoView:(RBPhotoView *)photoView atIndex:(NSInteger)index
{
    if(index >= self.photoModels.count)
    {
        photoView.imageView.image = nil;
        return;
    }
    photoView.reactDoubleTapZoom = YES;
    photoView.imageView.image = nil;
    [photoView.w1 setHidden:YES];
    RBPhotoModel *model = self.photoModels[index];
    if (model.image)
    {
        [self setPhotoView:photoView withImage:model.image];
    }
    else
    {
        if (!model.imageURLString )
        {
            [self setPhotoView:photoView withImage:model.placeholderImage];
        }
        else
        {
            [[SDWebImageManager sharedManager] cachedImageExistsForURL:[NSURL URLWithString:model.imageURLString] completion:^(BOOL isInCache) {
                if (!isInCache)
                {
                    photoView.w1 = photoView.w1? :[MBProgressHUD showHUDAddedTo:photoView animated:YES];
                    //knock
                    photoView.imageView.image = model.placeholderImage;
                    [self setPhotoView:photoView withImage:model.placeholderImage];
                }
            }];
            
            photoView.w1 = photoView.w1? :[MBProgressHUD showHUDAddedTo:photoView animated:YES];
            ((MBProgressHUD *)photoView.w1).label.text = nil;
            [photoView.w1 setMode:MBProgressHUDModeDeterminate];
            [photoView.w1 setHidden:NO];
            
            __weak typeof(photoView) weakPhotoView = photoView;
            __weak typeof(self) weakSelf = self;
            weakPhotoView.c1 = model.imageURLString;
            __weak NSString *imageURLString = weakPhotoView.c1;
            photoView.reactDoubleTapZoom = NO;
            
            [photoView.imageView sd_setImageWithURL:[NSURL URLWithString:model.imageURLString] placeholderImage:nil options: SDWebImageRetryFailed | SDWebImageDelayPlaceholder progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                if(weakPhotoView.c1 && imageURLString && [imageURLString isEqualToString:weakPhotoView.c1])
                {
                    [weakPhotoView.w1 setHidden:NO];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        ((MBProgressHUD *)weakPhotoView.w1).progress = 1.0 * receivedSize / expectedSize;
                    });
                }
            } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                if (weakPhotoView.c1 && imageURLString && [imageURLString isEqualToString:weakPhotoView.c1])
                {
                    if (image)
                    {
                        weakPhotoView.reactDoubleTapZoom = YES;
                        [weakPhotoView.w1 setHidden:YES];
                        [weakSelf setPhotoView:weakPhotoView withImage:image];
                    }
                    else
                    {
                        [weakPhotoView.w1 setHidden:NO];
                        [weakPhotoView.w1 setMode:MBProgressHUDModeText];
                        ((MBProgressHUD *)weakPhotoView.w1).label.text = @"X";
                    }
                }
            }];
        }
    }
}

- (void)rbPhotoViewController:(RBPhotoViewController *)controller didScrollToIndex:(CGFloat)index
{
    if ([self.delegate respondsToSelector:@selector(rbPhoto:didScrollToIndex:withPhotoController:)])
    {
        [self.delegate rbPhoto: self didScrollToIndex:index withPhotoController:controller];
    }
}

- (void)rbPhotoViewControllerWillBeginDragging:(RBPhotoViewController *)controller
{
    if ([self.delegate respondsToSelector:@selector(rbPhoto:willBeginDraggingwithPhotoController:)])
    {
        [self.delegate rbPhoto:self willBeginDraggingwithPhotoController:controller];
    }
    self.firstShow = NO;
}

- (void)rbPhotoViewController:(RBPhotoViewController *)controller singleTap:(UITapGestureRecognizer *)gesture atPhotoView:(RBPhotoView *)photoView
{
    if ([self.delegate respondsToSelector:@selector(rbPhoto:singleTapGesture:atPhotoView:withPhotoController:)])
    {
        [self.delegate rbPhoto:self singleTapGesture:gesture atPhotoView:photoView withPhotoController:controller];
    }
    if (self.showStyle == RBPhotoShowStyleZoom)
    {
        if (self.fromOrientation != self.fromController.interfaceOrientation)
        {
            [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:self.fromOrientation] forKey:@"orientation"];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self photoViewZoomOut: photoView];
        });
        
    }
    else
    {
        if (![self.delegate respondsToSelector:@selector(rbPhoto:singleTapGesture:atPhotoView:withPhotoController:)])
        {
            [self.photoController.navigationController setNavigationBarHidden:!self.photoController.navigationController.navigationBarHidden animated:YES];
        }
    }
}

- (void)rbPhotoViewController:(RBPhotoViewController *)controller doubleTap:(UITapGestureRecognizer *)gesture atPhotoView:(RBPhotoView *)photoView
{
    if ([self.delegate respondsToSelector:@selector(rbPhotoViewController:doubleTap:atPhotoView:)])
    {
        [self.delegate rbPhoto:self doubleTapGesture:gesture atPhotoView:photoView withPhotoController:controller];
    }
}

- (void)rbPhotoViewController:(RBPhotoViewController *)controller longPress:(UILongPressGestureRecognizer *)gesture atPhotoView:(RBPhotoView *)photoView
{
    if ([self.delegate respondsToSelector:@selector(rbPhoto:longPressGesture:atPhotoView:withPhotoController:)])
    {
        [self.delegate rbPhoto:self longPressGesture: gesture atPhotoView:photoView withPhotoController:controller];
    }
}

#pragma mark - Getter

- (UIWindow *)keyWindow
{
    return [[UIApplication sharedApplication].delegate window];
}

- (UIViewController *)fromController
{
    if (_fromController)
    {
        return _fromController;
    }
    else
    {
        return [UIApplication sharedApplication].keyWindow.rootViewController;
    }
}

@end
