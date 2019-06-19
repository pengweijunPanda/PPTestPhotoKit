//
//  NSBundle+HGImagePicker.h
//  HGImagePickerController
//
//  Created by pengweijun on 2019/6/18.
//  Copyright © 2019年 彭伟军. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSBundle (HGImagePicker)

+ (NSBundle *)hg_imagePickerBundle;

+ (NSString *)hg_localizedStringForKey:(NSString *)key value:(NSString *)value;
+ (NSString *)hg_localizedStringForKey:(NSString *)key;

@end

