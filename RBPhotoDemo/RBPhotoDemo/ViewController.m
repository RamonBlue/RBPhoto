//
//  ViewController.m
//  RBPhotoDemo
//
//  Created by Ran on 16/4/13.
//  Copyright © 2016年 Justice. All rights reserved.
//

#import "ViewController.h"
#import "RBPhotoBrowser.h"
#import "Masonry/Masonry.h"
#import "SDImageCache.h"
#import "UIImageView+WebCache.h"

@interface ViewController ()<RBPhotoDelegate>

@property(nonatomic, strong)RBPhotoBrowser *photo;
@property(nonatomic, assign)RBPhotoShowStyle showStyle;
@property(nonatomic, strong)NSMutableArray *imageViews;

@property(nonatomic, strong)NSMutableArray *thumbnailURLs;
@property(nonatomic, strong)NSMutableArray *originalURLs;

@property(nonatomic, assign)NSInteger currentIndex;

@end

@implementation ViewController

#pragma mark - LifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setup];
}

- (void)didReceiveMemoryWarning
{
    [[SDImageCache sharedImageCache] clearMemory];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Private

- (void)setup
{
    self.view.backgroundColor = [UIColor whiteColor];
    //NavigationItem
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Push", @"Present", @"Zoom", @"Custom"]];
    segmentedControl.selectedSegmentIndex = 0;
    [segmentedControl addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = segmentedControl;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"clear" style:UIBarButtonItemStylePlain target:self action:@selector(clear)];
    //ImageViews
    NSArray *thumbImageUrls = self.thumbnailURLs;
    CGFloat spacing = 12;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    NSInteger columnNumber = 4;
    CGFloat imageViewWidth = (screenWidth - (columnNumber + 1) * spacing) / columnNumber;
    CGFloat imageViewHeight = imageViewWidth;
    CGFloat imageViewX = 0;
    CGFloat imageViewY = 0;
    CGFloat startY = [UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.bounds.size.height;
    NSInteger row = 0;
    NSInteger column = 0;
    for (NSInteger i = 0; i < thumbImageUrls.count; i++)
    {
        row = i / columnNumber;
        column = i % columnNumber;
        imageViewX = spacing + (imageViewWidth + spacing) * column;
        imageViewY = startY + spacing + (imageViewHeight + spacing) * row;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(imageViewX, imageViewY, imageViewWidth, imageViewHeight)];
        imageView.backgroundColor = [UIColor lightGrayColor];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.tag = i;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoImageViewTapped:)];
        imageView.userInteractionEnabled = YES;
        [imageView addGestureRecognizer:tapGesture];
        [self.view addSubview:imageView];
        [self.imageViews addObject:imageView];
        [imageView sd_setImageWithURL:[NSURL URLWithString:thumbImageUrls[i]]];
    }
}

#pragma mark - Event

- (void)segmentedControlValueChanged: (UISegmentedControl *)segmentedControl
{
    self.showStyle = (RBPhotoShowStyle)segmentedControl.selectedSegmentIndex;
}

- (void)clear
{
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:nil];
    [[SDImageCache sharedImageCache] clearMemory];
}

- (void)photoImageViewTapped: (UITapGestureRecognizer *)tapGesture
{
    UIImageView *imageView = (UIImageView *)tapGesture.view;
    self.photo = [RBPhotoBrowser new];
    RBPhotoBrowser *photo = self.photo;
    photo.photoModels = ({
        NSMutableArray *photoModesM = [NSMutableArray array];
        NSArray *photoUrls = self.originalURLs;
        for (NSInteger i = 0; i < photoUrls.count; i++)
        {
            RBPhotoModel *model = [RBPhotoModel new];
            model.placeholderImage = ((UIImageView *)self.imageViews[i]).image;
            model.imageURLString = photoUrls[i];
            [photoModesM addObject:model];
        }
        photoModesM;
    });
    photo.delegate = self;
    photo.startIndex = imageView.tag;
    photo.fromController = self;
    photo.showStyle = self.showStyle;
    
    if (self.showStyle == RBPhotoShowStyleZoom)
    {
        photo.imageViews = self.imageViews;
    }
    else if(self.showStyle == RBPhotoShowStyleCustom)
    {
        [photo showWithCustomBlock:^(RBPhotoViewController * _Nullable controller) {
            RBPhotoNavigationController *navigationController = [[RBPhotoNavigationController alloc] initWithRootViewController:controller];
            navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
            navigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
            [self presentViewController:navigationController animated:YES completion:nil];
            
        }];
        return;
    }
    self.currentIndex = -1;
    [photo showWithCustomBlock:nil];
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)selectButtonClicked: (UIButton *)button
{
    RBPhotoModel *model = self.photo.photoModels[self.currentIndex];
    model.selected = !model.isSelected;
    button.backgroundColor = model.isSelected? [UIColor orangeColor]: [UIColor clearColor];
}

#pragma mark - RBPhotoDelegate

- (void)rbPhoto: (RBPhotoBrowser *)photo didScrollToIndex:(CGFloat)index withPhotoController:(RBPhotoViewController *)controller
{
    // custom...
    NSInteger currentIndex = MIN(photo.photoModels.count - 1, MAX(0, (NSInteger)roundf(index)));
    if (self.currentIndex != currentIndex)
    {
        if (photo.showStyle != RBPhotoShowStyleZoom)
        {
            controller.title = [NSString stringWithFormat:@"%zd/%zd", currentIndex + 1, photo.photoModels.count];
            if (controller.w1 == nil)
            {
                UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                [controller.view addSubview:button];
                [button mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.right.mas_equalTo(-30);
                    make.bottom.mas_equalTo(-30);
                    make.height.width.mas_equalTo(30);
                }];
                button.backgroundColor = [UIColor clearColor];
                button.layer.cornerRadius = 15;
                button.clipsToBounds = YES;
                button.layer.borderColor = [UIColor whiteColor].CGColor;
                button.layer.borderWidth = 1;
                [button addTarget:self action:@selector(selectButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
                controller.w1 = button;
            }
            RBPhotoModel *model = photo.photoModels[currentIndex];
            UIButton *selectButton = (UIButton *)controller.w1;
            selectButton.backgroundColor = model.isSelected? [UIColor orangeColor]: [UIColor clearColor];
        }
    }
    self.currentIndex = currentIndex;
}

- (void)rbPhoto:(RBPhotoBrowser *)photo longPressGesture: (UILongPressGestureRecognizer *)gesture atPhotoView:(RBPhotoView *)photoView withPhotoController:(RBPhotoViewController *)controller
{
    if (gesture.state == UIGestureRecognizerStateBegan)
    {        
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Options" delegate:nil cancelButtonTitle:@"cancel" destructiveButtonTitle:nil otherButtonTitles:@"Save", @"Scan", @"Custom", @"balabala", nil];
        [sheet showInView:self.view];
    }
}

- (void)rbPhoto:(RBPhotoBrowser *)photo willBeginDraggingwithPhotoController:(RBPhotoViewController *)controller
{
    if (photo.showStyle != RBPhotoShowStyleZoom && controller.navigationController.navigationBarHidden == NO)
    {
        [controller.navigationController setNavigationBarHidden:YES animated:YES];
    }
}

#pragma mark - Getter

- (NSMutableArray *)imageViews
{
    if (!_imageViews)
    {
        self.imageViews = [NSMutableArray array];
    }
    return _imageViews;
}

- (NSMutableArray *)thumbnailURLs
{
    if (!_thumbnailURLs) {
        self.thumbnailURLs = [NSMutableArray arrayWithArray:
                              @[
                                //方图
                                @"http://ww1.sinaimg.cn/square/eb8fce65jw1f1fizeeu1yj21t81w0e84.jpg",
                                @"http://ww2.sinaimg.cn/square/636e521cgw1exdsva0rplj20c80eydgs.jpg",
                                @"http://ww4.sinaimg.cn/square/636e521cgw1exdsvacn8xj20c807naag.jpg",
                                //扁图
                                @"http://ww2.sinaimg.cn/thumbnail/6aa09e8fjw1f1g1od98suj20yi0d9gns.jpg",
                                //gif图
                                @"http://ww3.sinaimg.cn/thumbnail/005EbyOWjw1f1g4xcxylsg30b406b4qx.gif",
                                @"http://ww3.sinaimg.cn/thumbnail/e286b404gw1f1extwgh06g20a005mhdu.gif",
                                //长图
                                @"http://ww3.sinaimg.cn/thumbnail/771a4077gw1f10c8laym9j20ku25fdxs.jpg",
                                @"http://ww4.sinaimg.cn/thumbnail/5c4bb291jw1f1exv680mkj20ju0zkajx.jpg",
                                @"http://ww2.sinaimg.cn/thumbnail/dc8d15f5jw1f1bx9zbdalj20c84oqnpd.jpg",
                                //gif图
                                @"http://ww3.sinaimg.cn/or360/70e0a133gw1f1ykey3oqhg20bo08r4qg.gif",
                                @"http://ww1.sinaimg.cn/or360/70e0a133gw1f1ykff9szzg20b40697vy.gif",
                                @"http://ww1.sinaimg.cn/or360/70e0a133gw1f1ykf61cqwg208c04pnjk.gif",
                                @"http://ww4.sinaimg.cn/or360/70e0a133gw1f1ykgh0aklg207804rx6p.gif",
                                @"http://ww2.sinaimg.cn/or360/70e0a133gw1f1ykfvtrmdg205k05jqv5.gif",
                                @"http://ww3.sinaimg.cn/or360/70e0a133gw1f1ykgxkq6wg207i052x6p.gif",
                                @"http://ww4.sinaimg.cn/or360/70e0a133gw1f1ykhw29qzg207s04nu0x.gif",
                                @"http://ww3.sinaimg.cn/or360/70e0a133gw1f1ykhexycdg207i044x6p.gif",
                                @"http://ww1.sinaimg.cn/or360/70e0a133gw1f1ykj6y7tbg209i05sqv9.gif",
                                ]];
    }
    return _thumbnailURLs;
}

- (NSMutableArray *)originalURLs
{
    if (!_originalURLs) {
        self.originalURLs = [NSMutableArray arrayWithArray:
                             @[
                               @"http://ww1.sinaimg.cn/bmiddle/eb8fce65jw1f1fizeeu1yj21t81w0e84.jpg",
                               @"http://ww2.sinaimg.cn/bmiddle/636e521cgw1exdsva0rplj20c80eydgs.jpg",
                               @"http://ww4.sinaimg.cn/bmiddle/636e521cgw1exdsvacn8xj20c807naag.jpg",
                               @"http://ww2.sinaimg.cn/bmiddle/6aa09e8fjw1f1g1od98suj20yi0d9gns.jpg",
                               @"http://ww3.sinaimg.cn/bmiddle/005EbyOWjw1f1g4xcxylsg30b406b4qx.gif",
                               @"http://ww3.sinaimg.cn/bmiddle/e286b404gw1f1extwgh06g20a005mhdu.gif",
                               @"http://ww3.sinaimg.cn/bmiddle/771a4077gw1f10c8laym9j20ku25fdxs.jpg",
                               @"http://ww4.sinaimg.cn/bmiddle/5c4bb291jw1f1exv680mkj20ju0zkajx.jpg",
                               @"http://ww2.sinaimg.cn/bmiddle/dc8d15f5jw1f1bx9zbdalj20c84oqnpd.jpg",
                               @"http://ww3.sinaimg.cn/woriginal/70e0a133gw1f1ykey3oqhg20bo08r4qg.gif",
                               @"http://ww1.sinaimg.cn/woriginal/70e0a133gw1f1ykff9szzg20b40697vy.gif",
                               @"http://ww1.sinaimg.cn/woriginal/70e0a133gw1f1ykf61cqwg208c04pnjk.gif",
                               @"http://ww4.sinaimg.cn/woriginal/70e0a133gw1f1ykgh0aklg207804rx6p.gif",
                               @"http://ww2.sinaimg.cn/woriginal/70e0a133gw1f1ykfvtrmdg205k05jqv5.gif",
                               @"http://ww3.sinaimg.cn/woriginal/70e0a133gw1f1ykgxkq6wg207i052x6p.gif",
                               @"http://ww4.sinaimg.cn/woriginal/70e0a133gw1f1ykhw29qzg207s04nu0x.gif",
                               @"http://ww3.sinaimg.cn/woriginal/70e0a133gw1f1ykhexycdg207i044x6p.gif",
                               @"http://ww1.sinaimg.cn/woriginal/70e0a133gw1f1ykj6y7tbg209i05sqv9.gif",
                               ]];
    }
    return _originalURLs;
}

@end
