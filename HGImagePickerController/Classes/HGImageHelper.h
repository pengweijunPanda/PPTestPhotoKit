//
//  HGImageHelper.h
//  HGImagePickerController
//
//  Created by pengweijun on 2019/6/18.
//  Copyright © 2019年 彭伟军. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

#import "HGAssetModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface HGImageHelper : NSObject

+ (BOOL)isCameraRollAlbum:(PHAssetCollection *)metadata;

+ (NSString *)getNewTimeFromDurationSecond:(NSInteger)duration;

+ (HGAssetModelMediaType)getAssetType:(PHAsset *)asset;

@end

NS_ASSUME_NONNULL_END
