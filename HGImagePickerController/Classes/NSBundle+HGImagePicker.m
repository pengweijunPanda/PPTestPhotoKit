//
//  NSBundle+HGImagePicker.m
//  HGImagePickerController
//
//  Created by pengweijun on 2019/6/18.
//  Copyright © 2019年 彭伟军. All rights reserved.
//

#import "NSBundle+HGImagePicker.h"
#import "HGImagePickerController.h"

@implementation NSBundle (HGImagePicker)

+ (NSBundle *)hg_imagePickerBundle {
    NSBundle *bundle = [NSBundle bundleForClass:[HGImagePickerController class]];
    NSURL *url = [bundle URLForResource:@"HGImagePickerController" withExtension:@"bundle"];
    bundle = [NSBundle bundleWithURL:url];
    return bundle;
}

+ (NSString *)hg_localizedStringForKey:(NSString *)key {
    return [self hg_localizedStringForKey:key value:@""];
}

+ (NSString *)hg_localizedStringForKey:(NSString *)key value:(NSString *)value {
    NSBundle *bundle = [HGImagePickerConfig sharedInstance].languageBundle;
    NSString *value1 = [bundle localizedStringForKey:key value:value table:nil];
    return value1;
}

@end
