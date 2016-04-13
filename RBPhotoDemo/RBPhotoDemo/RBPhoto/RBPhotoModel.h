//
//  RBPhotoModel.h
//  Photo
//
//  Created by Ran on 16/4/8.
//  Copyright © 2016年 Justice. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RBPhotoModel : NSObject

@property(nonatomic, strong)UIImage *placeholderImage;
@property(nonatomic, strong)UIImage *image;
@property(nonatomic, copy)NSString *imageURLString;

@property(nonatomic, assign, getter=isSelected)BOOL selected;

@end
