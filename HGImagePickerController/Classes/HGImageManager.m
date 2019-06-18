//
//  HGImageManager.m
//  HGImagePickerController
//
//  Created by pengweijun on 2019/6/18.
//  Copyright © 2019年 彭伟军. All rights reserved.
//

#import "HGImageManager.h"
#import "HGImageHelper.h"
#import "HGAlbumListVC.h"

@implementation HGImageManager

static HGImageManager *manager;
static dispatch_once_t onceToken;

+ (instancetype)manager {
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
        // manager.cachingImageManager = [[PHCachingImageManager alloc] init];
        // manager.cachingImageManager.allowsCachingHighQualityImages = YES;
        
//        [manager configHGScreenWidth];
    });
    return manager;
}
- (void)showAlbumList{
    __weak __typeof(self)weakSelf = self;
    [[HGImageManager manager] getCameraRollAlbum:YES allowPickingImage:YES needFetchAssets:YES completion:^(HGAlbumModel * _Nonnull model) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        HGAlbumListVC *albumListVC = [HGAlbumListVC new];
        albumListVC.model = model;
        [strongSelf.weakVC.navigationController pushViewController:albumListVC animated:YES];
    }];
}
/// Get Album 获得相册/相册数组
- (void)getCameraRollAlbum:(BOOL)allowPickingVideo
         allowPickingImage:(BOOL)allowPickingImage
           needFetchAssets:(BOOL)needFetchAssets
                completion:(void (^)(HGAlbumModel *model))completion {
    __block HGAlbumModel *model;
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    if (!allowPickingVideo) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    if (!allowPickingImage) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
//    if (!self.sortAscendingByModificationDate) {
//        option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:self.sortAscendingByModificationDate]];
//    }
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in smartAlbums) {
        // 有可能是PHCollectionList类的的对象，过滤掉
        if (![collection isKindOfClass:[PHAssetCollection class]]) continue;
        // 过滤空相册
        if (collection.estimatedAssetCount <= 0) continue;
        if ([HGImageHelper isCameraRollAlbum:collection]) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            model = [self modelWithResult:fetchResult name:collection.localizedTitle isCameraRoll:YES needFetchAssets:needFetchAssets];
            if (completion) completion(model);
            break;
        }
    }
}


- (HGAlbumModel *)modelWithResult:(PHFetchResult *)result name:(NSString *)name isCameraRoll:(BOOL)isCameraRoll needFetchAssets:(BOOL)needFetchAssets {
    HGAlbumModel *model = [[HGAlbumModel alloc] init];
    [model setResult:result needFetchAssets:needFetchAssets];
    model.name = name;
    model.isCameraRoll = isCameraRoll;
    model.count = result.count;
    return model;
}

#pragma mark - Get Assets

/// Get Assets 获得照片数组
- (void)getAssetsFromFetchResult:(PHFetchResult *)result completion:(void (^)(NSArray<HGAssetModel *> *))completion {
    HGImagePickerConfig *config = [HGImagePickerConfig sharedInstance];
    return [self getAssetsFromFetchResult:result allowPickingVideo:config.allowPickingVideo allowPickingImage:config.allowPickingImage completion:completion];
}

- (void)getAssetsFromFetchResult:(PHFetchResult *)result allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage completion:(void (^)(NSArray<HGAssetModel *> *))completion {
    NSMutableArray *photoArr = [NSMutableArray array];
    [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop) {
        HGAssetModel *model = [self assetModelWithAsset:asset allowPickingVideo:allowPickingVideo allowPickingImage:allowPickingImage];
        if (model) {
            [photoArr addObject:model];
        }
    }];
    if (completion) completion(photoArr);
}

- (HGAssetModel *)assetModelWithAsset:(PHAsset *)asset allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage {
//    BOOL canSelect = YES;
//    if ([self.pickerDelegate respondsToSelector:@selector(isAssetCanSelect:)]) {
//        canSelect = [self.pickerDelegate isAssetCanSelect:asset];
//    }
//    if (!canSelect) return nil;
    
    HGAssetModel *model;
    HGAssetModelMediaType type = [HGImageHelper getAssetType:asset];
    if (!allowPickingVideo && type == HGAssetModelMediaTypeVideo) return nil;
    if (!allowPickingImage && type == HGAssetModelMediaTypePhoto) return nil;
    if (!allowPickingImage && type == HGAssetModelMediaTypePhotoGif) return nil;
    
    PHAsset *phAsset = (PHAsset *)asset;
//    if (self.hideWhenCanNotSelect) { // 过滤掉尺寸不满足要求的图片
//        if (![HGImageHelper isPhotoSelectableWithAsset:phAsset]) {
//            return nil;
//        }
//    }
    NSString *timeLength = type == HGAssetModelMediaTypeVideo ? [NSString stringWithFormat:@"%0.0f",phAsset.duration] : @"";
    timeLength = [HGImageHelper getNewTimeFromDurationSecond:timeLength.integerValue];
    model = [HGAssetModel modelWithAsset:asset type:type timeLength:timeLength];
    return model;
}

@end

@implementation HGImagePickerConfig

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static HGImagePickerConfig *config = nil;
    dispatch_once(&onceToken, ^{
        if (config == nil) {
            config = [[HGImagePickerConfig alloc] init];
            config.preferredLanguage = nil;
            config.gifPreviewMaxImagesCount = 50;
        }
    });
    return config;
}

- (void)setPreferredLanguage:(NSString *)preferredLanguage {
    _preferredLanguage = preferredLanguage;
    
    if (!preferredLanguage || !preferredLanguage.length) {
        preferredLanguage = [NSLocale preferredLanguages].firstObject;
    }
    if ([preferredLanguage rangeOfString:@"zh-Hans"].location != NSNotFound) {
        preferredLanguage = @"zh-Hans";
    } else if ([preferredLanguage rangeOfString:@"zh-Hant"].location != NSNotFound) {
        preferredLanguage = @"zh-Hant";
    } else if ([preferredLanguage rangeOfString:@"vi"].location != NSNotFound) {
        preferredLanguage = @"vi";
    } else {
        preferredLanguage = @"en";
    }
//    _languageBundle = [NSBundle bundleWithPath:[[NSBundle HG_imagePickerBundle] pathForResource:preferredLanguage ofType:@"lproj"]];
}

@end
