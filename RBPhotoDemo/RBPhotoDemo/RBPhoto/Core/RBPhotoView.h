//
//  RBPhotoView.h
//  Photo
//
//  Created by Ran on 16/4/4.
//  Copyright © 2016年 Justice. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RBPhotoView;
@protocol RBPhotoViewDelegate <NSObject>
@optional
- (void)photoView: (RBPhotoView *)view singleTap: (UITapGestureRecognizer *)gesture;
- (void)photoView: (RBPhotoView *)view doubleTap:(UITapGestureRecognizer *)gesture;
- (void)photoView: (RBPhotoView *)view longPress:(UILongPressGestureRecognizer *)gesture;
@end

@interface RBPhotoView : UIView<UIScrollViewDelegate>

/**
 *  hierarchy: imageView -> scrollView -> RBPhotoView
 */
@property(nonatomic, strong)UIScrollView *scrollView;
@property(nonatomic, strong)UIImageView *imageView;

/**
 *  custom params
 */
@property(nonatomic, assign)Class imageViewClass;   /**<UIImageView.class by default*/
@property(nonatomic, assign)CGFloat minZoomScale;   /**<1.0 by default*/
@property(nonatomic, assign)CGFloat maxZoomScale;   /**<2.0 by default*/
@property(nonatomic, assign)CGSize imageSize;       /**self.imageView.image.size by default*/
@property(nonatomic, assign)BOOL reactDoubleTapZoom;/**<YES by default*/
@property(nonatomic, weak)id<RBPhotoViewDelegate>delegate;

/**
 *  adjust views frame, reset other paramas
 */
- (void)resizeSubviews;

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
