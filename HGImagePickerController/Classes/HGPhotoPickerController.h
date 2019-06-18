//
//  TZPhotoPickerController.h
//  HGImagePickerController
//
//  Created by pengweijun on 2019/6/18.
//  Copyright © 2019年 彭伟军. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HGAlbumModel;
@interface HGPhotoPickerController : UIViewController

@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, assign) NSInteger columnNumber;
@property (nonatomic, strong) HGAlbumModel *model;
@end


@interface HGCollectionView : UICollectionView

@end
