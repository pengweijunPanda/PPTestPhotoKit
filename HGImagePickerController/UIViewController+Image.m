//
//  UIViewController+Image.m
//  HGImagePickerController
//
//  Created by pengweijun on 2019/6/18.
//  Copyright © 2019年 彭伟军. All rights reserved.
//

#import "UIViewController+Image.h"

#import <objc/runtime.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Photos/PHPhotoLibrary.h>


#define KEY_OBJECT_DISMISSBLOCKER @"HBImagePickerController.Camera"
#define KEY_methodName @"delegate"

const char *OperationKey = "OperationKey";
const char *compressRateKey = "compressRateKey";


@implementation UIViewController (Image)

- (void)setImagePickDelegate:(id)delegate
{
    objc_setAssociatedObject(self, &OperationKey,delegate, OBJC_ASSOCIATION_ASSIGN);
}
- (void)cancelUIViewControllerCameraDelegate
{
    //取消该关联变量，置空
    objc_setAssociatedObject(self, &OperationKey, nil, OBJC_ASSOCIATION_ASSIGN);
    //    //取消全部关联变量
    //    objc_removeAssociatedObjects(arr);
}


- (id)getUIViewControllerImagePickerDelegate
{
    return objc_getAssociatedObject(self, &OperationKey);
}

- (void)setCompressRate:(float)compressRate
{
    
    objc_setAssociatedObject(self, &compressRateKey,[NSNumber numberWithBool:compressRate],OBJC_ASSOCIATION_ASSIGN);
}
- (float)compressRate
{
    
    NSNumber *obj = objc_getAssociatedObject(self, &compressRateKey);
    if (!obj) {
        obj = @(0.5);
    }
    return obj.floatValue;
}

#pragma mark - present ablum
- (void)presentAblumViewControllerWithAnimated: (BOOL)flag completion:(void (^)(void))completionx
{
    __weak __typeof(self)weakSelf = self;
    switch ([PHPhotoLibrary authorizationStatus]) {
        case PHAuthorizationStatusAuthorized:{
            UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
            mediaUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            mediaUI.delegate = self;
            [self presntMediaUIViewController:mediaUI];
        }
            break;
        default:{
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                if (status == PHAuthorizationStatusAuthorized) {
                    
                    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
                    mediaUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                    mediaUI.delegate = self;
                    [strongSelf presntMediaUIViewController:mediaUI];
                    
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self showAlertWithTitle:@"没开相册权限"];
                    });
                }
            }];
        }
            break;
    }
}

- (void)presentPhotosAlbumViewControllerWithAnimated: (BOOL)flag completion:(void (^)(void))completion
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [self showAlertWithTitle:@"device not support Ablum"];
        return;
    }

    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary; 
    mediaUI.delegate = self;
    [self presntMediaUIViewController:mediaUI];
}
#pragma mark - 选择视频
- (void)presentVideosAlbumViewControllerWithAnimated: (BOOL)flag completion:(void (^)(void))completion
{
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.mediaTypes = [NSArray arrayWithObjects:@"public.movie", nil];
    mediaUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    mediaUI.allowsEditing = NO;
    mediaUI.delegate = self;
    mediaUI.videoQuality = UIImagePickerControllerQualityTypeHigh;
    [self presntMediaUIViewController:mediaUI];
}


- (void)presntMediaUIViewController:(UIViewController *)mediaUI
{
    [self presentViewController:mediaUI animated:YES completion:nil];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - 相机相关

- (void)presentCameraViewControllerWithAnimated: (BOOL)flag completion:(void (^)(void))completion
{
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self showAlertWithTitle:@"device not support camera"];
        return;
    }
    UIImagePickerController *m_imagePicker = [[UIImagePickerController alloc] init];
    [m_imagePicker setDelegate:self];
    [m_imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
    [self presntMediaUIViewController:m_imagePicker];
}

static NSDictionary * infoDic;

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
        if ([mediaType isEqualToString:@"public.image"]) {
            infoDic =[NSDictionary dictionaryWithDictionary:info];
            __weak __typeof(self)weakSelf = self;
            [self dismissViewControllerAnimated:YES completion:^{
                infoDic = [NSDictionary dictionaryWithDictionary:info];
                [weakSelf handleCamera:info];
            }];
        }
    }
    else {
        
        [self dismissViewControllerAnimated:YES completion:^{
            infoDic = [NSDictionary dictionaryWithDictionary:info];
            
            __weak typeof(self) weakSelf = self;
            NSString *type = [infoDic objectForKey:UIImagePickerControllerMediaType];
            if ([type isEqual: @"public.movie"]) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                id delegate = [strongSelf getUIViewControllerImagePickerDelegate];
                NSURL *url = info[UIImagePickerControllerMediaURL];
                NSURL *assetUrl = info[UIImagePickerControllerReferenceURL];
                if (delegate && [delegate respondsToSelector:@selector(hg_imagePickerController:cameraDidFinishPickingMediaWithAssetUrl:)]) {
                    [delegate hg_imagePickerController:strongSelf cameraDidFinishPickingMediaWithAssetUrl:assetUrl];
                }
            }
            else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
                [lib assetForURL:[infoDic objectForKey:UIImagePickerControllerReferenceURL] resultBlock:^(ALAsset *asset) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    ALAssetRepresentation *representation = [asset defaultRepresentation];
                    id delegate = [strongSelf getUIViewControllerImagePickerDelegate];
                    [strongSelf handleAblumInfo:info imageblock:^(UIImage *image) {
                        if (delegate && [delegate respondsToSelector:@selector(hg_imagePickerController:cameraDidFinishPickingMediaWithImage:)]) {
                            [delegate hg_imagePickerController:strongSelf cameraDidFinishPickingMediaWithImage:image];
                        }
                        //区分是否GIF
                        if (delegate && [delegate respondsToSelector:@selector(hg_imagePickerController:cameraDidFinishPickingMediaWithImage:isGif:)]) {
                            [delegate hg_imagePickerController:strongSelf cameraDidFinishPickingMediaWithImage:image isGif:[strongSelf isGifFromPickerWhendidFinishPickingMediaWithInfo:info]];
                        }
                        //
                        if (delegate && [delegate respondsToSelector:@selector(hg_imagePickerController:cameraDidFinishPickingMediaWithImage:imageSize:)]) {
                            [delegate hg_imagePickerController:strongSelf cameraDidFinishPickingMediaWithImage:image imageSize:[representation size]];
                        }
                        
                    }];
                    
                }  failureBlock:^(NSError *error) {
                    
                }];
#pragma clang diagnostic pop
            }
            
            
        }];
        
    }
}

- (BOOL)isGifFromPickerWhendidFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *assetString = [[info objectForKey:UIImagePickerControllerReferenceURL] absoluteString];
    if ([assetString.uppercaseString hasSuffix:@"GIF"]) {
        //这个图片是GIF图片
        return YES;
    } else {
        return NO;
    }
}

- (void)handleCamera:(NSDictionary *)info
{
    UIImage *image = [self handleCanmearInfo:info];
    id delegate = [self getUIViewControllerImagePickerDelegate];
    if (delegate && [delegate respondsToSelector:@selector(hg_imagePickerController:cameraDidFinishPickingMediaWithImage:isGif:)]) {
        [delegate hg_imagePickerController:self cameraDidFinishPickingMediaWithImage:image isGif:[self isGifFromPickerWhendidFinishPickingMediaWithInfo:info]];
    }
    else if (delegate && [delegate respondsToSelector:@selector(hg_imagePickerController:cameraDidFinishPickingMediaWithImage:)]) {
        [delegate hg_imagePickerController:self cameraDidFinishPickingMediaWithImage:image];
    }
}
- (UIImage *)handleCanmearInfo:(NSDictionary *)info
{
    NSData *data;
    //切忌不可直接使用originImage，因为这是没有经过格式化的图片数据，可能会导致选择的图片颠倒或是失真等现象的发生，从UIImagePickerControllerOriginalImage中的Origin可以看出，很原始，
    //    NSValue *cropRectValue =  [info objectForKey:UIImagePickerControllerCropRect];
    //    CGRect cropRect = cropRectValue.CGRectValue;
    //UIImagePickerControllerOriginalImage
    UIImage *EditedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    //图片压缩，因为原图都是很大的，不必要传原图
    float scalerat = [self compressRate];
    UIImage *scaleImage  = [self scaleImage:EditedImage toScale:scalerat];
    //以下这两步都是比较耗时的操作，最好开一个HUD提示用户，这样体验会好些，不至于阻塞界面
    if (UIImagePNGRepresentation(scaleImage) == nil) {
        //将图片转换为JPG格式的二进制数据
        data = UIImageJPEGRepresentation(scaleImage, scalerat);
        //        fileName = [NSString stringWithFormat:@"ios_dz%dp_%@.jpg",2,@"ddd"];
    } else {
        //将图片转换为PNG格式的二进制数据
        data = UIImagePNGRepresentation(scaleImage);
    } //将二进制数据生成UIImage
    UIImage *image = [UIImage imageWithData:data];
    return image;
    
}


- (void)handleAblumInfo:(NSDictionary *)info imageblock:(void(^)(UIImage * image))imageblock
{
    NSURL *imageURL = [info objectForKey:UIImagePickerControllerReferenceURL];
    
    //    NSURL *imageURL = [info valueForKey:UIImagePickerControllerEditedImage];
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset) {
        ALAssetRepresentation *representation = [myasset defaultRepresentation];
        UIImage *image=[UIImage imageWithCGImage:myasset.defaultRepresentation.fullScreenImage];
        //                    UIImageJPEGRepresentation(image, 0.5);
        CGImageRef iref = [representation fullResolutionImage];
        //        NSString *fileName = representation.filename;
        
        imageblock(image);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (iref) {
                
            }
        });
    };
    ALAssetsLibrary *assetslibrary = [[ALAssetsLibrary alloc] init];
    [assetslibrary assetForURL:imageURL
                   resultBlock:resultblock
                  failureBlock:nil];
    
}


- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;
{
    
}

#pragma mark - Helper

- (UIImage *)scaleImage:(UIImage *)image toScale:(float)scaleSize
{
    UIGraphicsBeginImageContext(CGSizeMake(image.size.width*scaleSize,image.size.height*scaleSize));
    [image drawInRect:CGRectMake(0, 0, image.size.width * scaleSize, image.size.height *scaleSize)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

- (UIAlertController *)showAlertWithTitle:(NSString *)title
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
    return alertController;
}


@end
