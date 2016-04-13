//
//  RBPhotoViewController.m
//  Photo
//
//  Created by Ran on 16/4/4.
//  Copyright © 2016年 Justice. All rights reserved.
//

#import "RBPhotoViewController.h"

@interface RBPhotoViewController ()<UIScrollViewDelegate, RBPhotoViewDelegate>

@property(nonatomic, strong)NSMutableArray *displayViews;
@property(nonatomic, strong)NSMutableArray *reuseViews;

@property(nonatomic, assign)NSInteger minIndex;
@property(nonatomic, assign)NSInteger maxIndex;

@property(nonatomic, assign)BOOL scrolling;
@property(nonatomic, strong)UIScrollView *scrollView;

@end

@implementation RBPhotoViewController

#pragma mark - LifeCycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.startIndex = 0;
        self.marginBetweenPhotos = 40.0;
        self.interfaceOrientationMask = UIInterfaceOrientationMaskAllButUpsideDown;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    [self resizeScrollView];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if ([self.delegate respondsToSelector:@selector(rbPhotoViewController:willAnimateRotationToInterfaceOrientation:duration:)])
    {
        [self.delegate rbPhotoViewController:self willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
    [self resizeScrollView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)dealloc
{
    NSLog(@"photoviewcontrollerdealloc");
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return self.interfaceOrientationMask;
}

#pragma mark - Private

- (void)setup
{
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor blackColor];
    self.view.clipsToBounds = YES;
    self.minIndex = self.startIndex;
    self.maxIndex = self.startIndex;
}

- (void)resizeScrollView
{
    self.scrolling = NO;
    CGRect frame = [UIScreen mainScreen].bounds;
    self.scrollView.frame = CGRectMake(- self.marginBetweenPhotos, 0, frame.size.width + self.marginBetweenPhotos, frame.size.height);
    self.scrollView.contentSize = CGSizeMake((frame.size.width + self.marginBetweenPhotos)* [self.delegate rbPhotoViewControllerPhotosCount:self], frame.size.height);
    [self scrollToPhotoAtIndex:self.minIndex animated:NO];
    if ([self.delegate respondsToSelector:@selector(rbPhotoViewController:didScrollToIndex:)])
    {
        [self.delegate rbPhotoViewController:self didScrollToIndex:self.scrollView.contentOffset.x / (self.view.bounds.size.width + self.marginBetweenPhotos)];
    }
    [self showPhotoAtIndex:self.minIndex reset:YES];
    if (self.minIndex != self.maxIndex)
    {
        [self showPhotoAtIndex:self.maxIndex reset:YES];
    }
    self.scrolling = YES;
}

- (void)resizePhotoViews
{
    CGFloat contentOffsetX = self.scrollView.contentOffset.x;
    CGFloat index = contentOffsetX / (self.view.bounds.size.width + self.marginBetweenPhotos);
    NSInteger maxIndex = MIN([self.delegate rbPhotoViewControllerPhotosCount:self] - 1, (NSInteger)ceilf(index));
    NSInteger minIndex = MAX(0, (NSInteger)floorf(index));
    [self removePhotoAtIndex:maxIndex + 1];
    [self removePhotoAtIndex:minIndex - 1];
    [self showPhotoAtIndex:minIndex reset:NO];
    if(minIndex != maxIndex)
    {
        [self showPhotoAtIndex: maxIndex reset:NO];
    }
    self.minIndex = minIndex;
    self.maxIndex = maxIndex;
}

- (void)scrollToPhotoAtIndex: (NSInteger)index animated: (BOOL)animated
{
    [self.scrollView setContentOffset:CGPointMake((self.view.bounds.size.width + self.marginBetweenPhotos) * index, 0) animated:animated];
}

- (void)showPhotoAtIndex: (NSInteger)index reset: (BOOL)reset
{
    if (index < 0 || index >= [self.delegate rbPhotoViewControllerPhotosCount:self]) {
        return;
    }
    for (RBPhotoView *photoView in self.displayViews)
    {
        if (photoView.tag == index)
        {
            if (reset)
            {
                photoView.frame = CGRectMake((self.view.frame.size.width + self.marginBetweenPhotos) * index + self.marginBetweenPhotos, 0, self.view.frame.size.width, self.view.frame.size.height);
                photoView.scrollView.scrollEnabled = YES;
                [self.delegate rbPhotoViewController:self willShowPhotoView:photoView atIndex:index];
            }
            return;
        }
    }
    RBPhotoView *photoView = self.reuseViews.lastObject;
    [self.scrollView addSubview:photoView];
    [self.displayViews addObject:photoView];
    [self.reuseViews removeObject:photoView];
    photoView.frame = CGRectMake((self.view.frame.size.width + self.marginBetweenPhotos) * index + self.marginBetweenPhotos, 0, self.view.frame.size.width, self.view.frame.size.height);
    photoView.tag = index;
    photoView.scrollView.scrollEnabled = YES;
    if ([self.delegate respondsToSelector:@selector(rbPhotoViewController:willShowPhotoView:atIndex:)])
    {
        [self.delegate rbPhotoViewController:self willShowPhotoView:photoView atIndex:index];
    }
}

- (void)removePhotoAtIndex: (NSInteger)index
{
    if (index < 0 || index >= [self.delegate rbPhotoViewControllerPhotosCount:self])
    {
        return;
    }
    for (NSInteger i = 0; i < self.displayViews.count; i++)
    {
        RBPhotoView *photoView = self.displayViews[i];
        if (photoView.tag == index)
        {
            [photoView removeFromSuperview];
            [self.displayViews removeObject:photoView];
            [self.reuseViews addObject:photoView];
            return;
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.scrolling = YES;
    if ([self.delegate respondsToSelector:@selector(rbPhotoViewControllerWillBeginDragging:)])
    {
        [self.delegate rbPhotoViewControllerWillBeginDragging:self];
    }
    for (RBPhotoView *photoView in self.displayViews)
    {
        photoView.scrollView.scrollEnabled = NO;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.scrolling = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.scrolling)
    {
        [self resizePhotoViews];
    }
    if ([self.delegate respondsToSelector:@selector(rbPhotoViewController:didScrollToIndex:)])
    {
        [self.delegate rbPhotoViewController:self didScrollToIndex:scrollView.contentOffset.x / (self.view.bounds.size.width + self.marginBetweenPhotos)];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    for (RBPhotoView *photoView in self.displayViews)
    {
        photoView.scrollView.scrollEnabled = YES;
    }
}

#pragma mark - RBPhotoViewDelegate

- (void)photoView:(RBPhotoView *)view singleTap:(UITapGestureRecognizer *)gesture
{
    if ([self.delegate respondsToSelector:@selector(rbPhotoViewController:singleTap:atPhotoView:)])
    {
        [self.delegate rbPhotoViewController:self singleTap:gesture atPhotoView:view];
    }
}

- (void)photoView:(RBPhotoView *)view doubleTap:(UITapGestureRecognizer *)gesture
{
    if ([self.delegate respondsToSelector:@selector(rbPhotoViewController:doubleTap:atPhotoView:)])
    {
        [self.delegate rbPhotoViewController:self doubleTap:gesture atPhotoView:view];
    }
}

- (void)photoView:(RBPhotoView *)view longPress:(UILongPressGestureRecognizer *)gesture
{
    if ([self.delegate respondsToSelector:@selector(rbPhotoViewController:longPress:atPhotoView:)])
    {
        [self.delegate rbPhotoViewController:self longPress:gesture atPhotoView:view];
    }
}

#pragma mark - Getter

- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        self.scrollView = ({
            UIScrollView *scrollView = [[UIScrollView alloc] init];
            scrollView.delegate = self;
            scrollView.pagingEnabled = YES;
            scrollView.backgroundColor = [UIColor clearColor];
            scrollView.scrollsToTop = NO;
            scrollView.showsHorizontalScrollIndicator = NO;
            scrollView.showsVerticalScrollIndicator = NO;
            [self.view addSubview:scrollView];
            scrollView;
        });
    }
    return _scrollView;
}

- (NSMutableArray *)displayViews
{
    if (!_displayViews) {
        self.displayViews = [NSMutableArray array];
    }
    return _displayViews;
}

- (NSMutableArray *)reuseViews
{
    if (!_reuseViews) {
        self.reuseViews = [NSMutableArray array];
    }
    while(_reuseViews.count > 2)
    {
        [_reuseViews removeLastObject];
    }
    while (_reuseViews.count <= 0)
    {
        [_reuseViews addObject:({
            RBPhotoView *photoView = [[RBPhotoView alloc] init];
            photoView.imageViewClass = self.imageViewClass;
            photoView.delegate = self;
            photoView;
        })];
    }
    return _reuseViews;
}

@end
