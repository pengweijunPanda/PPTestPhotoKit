//
//  HGImageManager.h
//  HGImagePickerController
//
//  Created by pengweijun on 2019/6/18.
//  Copyright © 2019年 彭伟军. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UIViewController+Image.h"

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import "HGAssetModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface HGImageManager : NSObject

@property (weak, nonatomic) id<UIViewControllerImagePickerDelegate> pickerDelegate;

@property (weak, nonatomic) UIViewController *weakVC;

+ (instancetype)manager ;

- (void)showAlbumList;

- (void)getAssetsFromFetchResult:(PHFetchResult *)result completion:(void (^)(NSArray<HGAssetModel *> *))completion;

- (void)getCameraRollAlbum:(BOOL)allowPickingVideo
         allowPickingImage:(BOOL)allowPickingImage
           needFetchAssets:(BOOL)needFetchAssets
                completion:(void (^)(HGAlbumModel *model))completion;

@end


@interface HGImagePickerConfig : NSObject
+ (instancetype)sharedInstance;
@property (copy,   nonatomic) NSString *preferredLanguage;
@property (assign, nonatomic) BOOL allowPickingImage;
@property (assign, nonatomic) BOOL allowPickingVideo;
@property (strong, nonatomic) NSBundle *languageBundle;
@property (assign, nonatomic) BOOL showSelectedIndex;
@property (assign, nonatomic) BOOL showPhotoCannotSelectLayer;
@property (assign, nonatomic) BOOL notScaleImage;
@property (assign, nonatomic) BOOL needFixComposition;

/// 默认是50，如果一个GIF过大，里面图片个数可能超过1000，会导致内存飙升而崩溃
@property (assign, nonatomic) NSInteger gifPreviewMaxImagesCount;
/// 【自定义GIF播放方案】为了避免内存过大，内部默认限制只播放50帧（平均取），可通过gifPreviewMaxImagesCount属性调整，若对GIF预览有更好的效果要求，可实现这个block采用FLAnimatedImage等三方库来播放，但注意FLAnimatedImage有播放速度较慢问题，自行取舍下。
//@property (nonatomic, copy) void (^gifImagePlayBlock)(TZPhotoPreviewView *view, UIImageView *imageView, NSData *gifData, NSDictionary *info);
@end

NS_ASSUME_NONNULL_END
