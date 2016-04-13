//
//  RBPhotoView.m
//  Photo
//
//  Created by Ran on 16/4/4.
//  Copyright © 2016年 Justice. All rights reserved.
//

#import "RBPhotoView.h"

@implementation RBPhotoView

#pragma mark - System

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        self.minZoomScale = 1;
        self.maxZoomScale = 2;
        self.reactDoubleTapZoom = YES;
        self.imageSize = CGSizeZero;
        self.imageViewClass = [UIImageView class];
        [self addGestureRecognizer];
    }
    return self;
}

#pragma mark - Private

- (void)addGestureRecognizer
{
    UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGesture:)];
    [self addGestureRecognizer:singleTapGesture];
    
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGesture:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTapGesture];
    [singleTapGesture requireGestureRecognizerToFail:doubleTapGesture];

    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesture:)];
    [self addGestureRecognizer:longPressGesture];
}

#pragma mark - Public

- (void)resizeSubviews
{
    if (CGSizeEqualToSize(self.imageSize, CGSizeZero))
    {
        self.imageSize = self.imageView.image.size;
        if (CGSizeEqualToSize(self.imageSize, CGSizeZero))
        {
            return;
        }
    }
    self.scrollView.frame = self.bounds;
    self.scrollView.zoomScale = 1;
    self.scrollView.contentOffset = CGPointZero;
    self.scrollView.minimumZoomScale = self.minZoomScale;
    self.scrollView.maximumZoomScale = self.maxZoomScale;
    
    self.imageView.frame = ({
        CGRect frame;
        CGSize fullSize = self.scrollView.frame.size;
        if (fullSize.width > fullSize.height)
        {
            frame.size.height = fullSize.height;
            frame.size.width = frame.size.height * self.imageSize.width / self.imageSize.height;
            frame.origin.y = 0;
            frame.origin.x = MAX(fullSize.width / 2 - frame.size.width / 2, 0);
        }else
        {
            frame.size.width = fullSize.width;
            frame.size.height = fullSize.width * self.imageSize.height / self.imageSize.width;
            frame.origin.x = 0;
            frame.origin.y = MAX(fullSize.height / 2 - frame.size.height / 2, 0);
        }
        frame;
    });
    self.scrollView.contentSize = self.imageView.frame.size;
}

#pragma mark - Event

- (void)singleTapGesture: (UITapGestureRecognizer *)gesture
{
    if ([self.delegate respondsToSelector:@selector(photoView:singleTap:)])
    {
        [self.delegate photoView:self singleTap:gesture];
    }
}

- (void)doubleTapGesture: (UITapGestureRecognizer *)gesture
{
    if ([self.delegate respondsToSelector:@selector(photoView:doubleTap:)])
    {
        [self.delegate photoView:self doubleTap:gesture];
    }
    
    if (self.scrollView.zoomScale > 1 && self.reactDoubleTapZoom)
    {
        [self.scrollView setZoomScale:1 animated:YES];
    }else if(self.reactDoubleTapZoom)
    {
        CGPoint tapPoint = [gesture locationInView:self.imageView];
        CGFloat width = self.scrollView.frame.size.width / self.maxZoomScale;
        CGFloat height = self.scrollView.frame.size.height / self.maxZoomScale;
        CGRect frame = CGRectMake(tapPoint.x - width / 2, tapPoint.y - height / 2, width, height);
        [self.scrollView zoomToRect:frame animated:YES];
    }
}

- (void)longPressGesture: (UILongPressGestureRecognizer *)gesture
{
    if ([self.delegate respondsToSelector:@selector(photoView:longPress:)])
    {
        [self.delegate photoView:self longPress:gesture];
    }
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    if (scrollView.zoomScale <= 1)
    {
        CGRect frame = self.imageView.frame;
        if (frame.size.width / frame.size.height > scrollView.frame.size.width / scrollView.frame.size.height)
        {
            frame.origin.y = scrollView.frame.size.height / 2 - frame.size.height / 2;
        }else
        {
            frame.origin.x = scrollView.frame.size.width / 2 - frame.size.width / 2;
        }
        self.imageView.frame = frame;
    }else
    {
        CGRect frame = self.imageView.frame;
        if (frame.size.width / frame.size.height > scrollView.frame.size.width / scrollView.frame.size.height && self.bounds.size.height > self.bounds.size.width)
        {
            frame.origin.y = MAX(0, self.scrollView.frame.size.height / 2 - frame.size.height / 2);
        }
        else if(frame.size.width / frame.size.height < scrollView.frame.size.width / scrollView.frame.size.height && self.bounds.size.height < self.bounds.size.width)
        {
            frame.origin.x = MAX(0, self.scrollView.frame.size.width / 2 - frame.size.width / 2);
        }
        self.imageView.frame = frame;
    }
}

#pragma mark - Getter

- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        self.scrollView = ({
            UIScrollView *scrollView = [[UIScrollView alloc] init];
            scrollView.delegate = self;
            scrollView.showsHorizontalScrollIndicator = NO;
            scrollView.showsVerticalScrollIndicator = NO;
            scrollView.backgroundColor = [UIColor clearColor];
            [self addSubview:scrollView];
            scrollView;
        });
    }
    return _scrollView;
}

- (UIImageView *)imageView
{
    if (!_imageView) {
        self.imageView = ({
            UIImageView *imageView = [[self.imageViewClass alloc] init];
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            imageView.clipsToBounds = YES;
            imageView.backgroundColor = [UIColor clearColor];
            [self.scrollView addSubview:imageView];
            imageView;
        });
    }
    return _imageView;
}

@end
