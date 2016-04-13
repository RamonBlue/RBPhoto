//
//  UIImage+GIFEmpExchange.m
//  Photo
//
//  Created by Ran on 16/4/8.
//  Copyright © 2016年 Justice. All rights reserved.
//

#import "NSObject+RBPhotoMethodExchange.h"
#import "YYImage.h"
#import <objc/runtime.h>
#import "SDWebImage/UIImage+GIF.h"
#import "SDWebImage/SDImageCache.h"
#import "SDWebImage/SDWebImageDownloader.h"
#import "SDWebImage/SDWebImageDownloaderOperation.h"

@implementation NSObject(RBPhotoMethodExchange)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //替换SDWebImage的NSData->Gif方法为YYImage方法
        Method orginalGifMethod = class_getClassMethod([UIImage class], @selector(sd_animatedGIFWithData:));
        Method newGifMethod = class_getClassMethod([self class], @selector(rb_newGitImpWithData:));
        method_exchangeImplementations(orginalGifMethod, newGifMethod);
        
        //屏蔽下载gif后SDWebImage对YYImage的操作
        [SDWebImageDownloader sharedDownloader].shouldDecompressImages = NO;
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored"-Wundeclared-selector"
        Method orginalScaleImageMethod = class_getInstanceMethod([SDWebImageDownloaderOperation class], @selector(scaledImageForKey:image:));
        #pragma clang diagnostic pop
        Method newScaleImageMethod = class_getInstanceMethod([self class], @selector(newScaledImageForKey:image:));
        method_exchangeImplementations(orginalScaleImageMethod, newScaleImageMethod);
        
        //屏蔽从缓存取出gif后SDWebImage对YYImage的操作
        [SDImageCache sharedImageCache].shouldDecompressImages = NO;
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored"-Wundeclared-selector"
        Method orginalCacheScaledImageMethod = class_getInstanceMethod([SDImageCache class], @selector(scaledImageForKey:image:));
        #pragma clang diagnostic pop
        Method newCacheScaledImageMethod = class_getInstanceMethod([self class], @selector(newCacheScaledImageForKey:image:));
        method_exchangeImplementations(orginalCacheScaledImageMethod, newCacheScaledImageMethod);
    });
}

+ (UIImage *)rb_newGitImpWithData: (NSData *)data
{
    return [YYImage imageWithData:data];
}

- (UIImage *)newScaledImageForKey:(NSString *)key image:(UIImage *)image
{
    if ([image isKindOfClass:[YYImage class]] && ((YYImage *)image).animatedImageType == YYImageTypeGIF){
        return image;
    }else{
        return [self newScaledImageForKey:key image:image];
    }
}

- (UIImage *)newCacheScaledImageForKey: (NSString *)key image: (UIImage *)image
{
    if ([image isKindOfClass:[YYImage class]] && ((YYImage *)image).animatedImageType == YYImageTypeGIF){
        return image;
    }else{
        return [self newCacheScaledImageForKey:key image:image];
    }
}

@end
