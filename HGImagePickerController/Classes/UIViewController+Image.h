//
//  UIViewController+Image.h
//  HGImagePickerController
//
//  Created by pengweijun on 2019/6/18.
//  Copyright © 2019年 彭伟军. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol UIViewControllerImagePickerDelegate <NSObject>

@optional
/**
 * 从相册挑选图片取消
 */
- (void)hg_imagePickerControllerDidCancel:(UIViewController *)imagePickerController;
/**
 * 从相机选择图片
 */
- (void)hg_imagePickerController:(UIViewController *)viewController cameraDidFinishPickingMediaWithImage:(UIImage *)image;

- (void)hg_imagePickerController:(UIViewController *)viewController cameraDidFinishPickingMediaWithImage:(UIImage *)image isGif:(BOOL)isGif;

- (void)hg_imagePickerController:(UIViewController *)viewController cameraDidFinishPickingMediaWithImage:(UIImage *)image imageSize:(long long)imageSize;
/**
 * 从相机选择视频
 */
- (void)hg_imagePickerController:(UIViewController *)viewController cameraDidFinishPickingMediaWithAssetUrl:(NSURL *)asseturl;

@end


@interface UIViewController (Image)<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic, assign, readonly) float compressRate;

- (void)setCompressRate:(float)compressRate;

/**
 * 首先要设置代理模式 第一步
 */
- (void)setImagePickDelegate:(id)delegate;

- (void)cancelUIViewControllerCameraDelegate;

- (void)presentCameraViewControllerWithAnimated: (BOOL)flag completion:(void (^)(void))completion;

- (void)presentAblumViewControllerWithAnimated: (BOOL)flag completion:(void (^)(void))completionx;

- (void)presentPhotosAlbumViewControllerWithAnimated: (BOOL)flag completion:(void (^)(void))completion;

- (void)presentVideosAlbumViewControllerWithAnimated: (BOOL)flag completion:(void (^)(void))completion;


@end

NS_ASSUME_NONNULL_END
