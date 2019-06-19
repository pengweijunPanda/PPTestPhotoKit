//
//  HGGifPhotoPreviewController.m
//  HGImagePickerController
//
//  Created by pengweijun on 2019/6/18.
//  Copyright © 2019年 彭伟军. All rights reserved.
//

#import "HGGifPhotoPreviewController.h"
#import "HGImagePickerController.h"
#import "HGAssetModel.h"
#import "UIView+Layout.h"
#import "HGPhotoPreviewCell.h"
#import "HGImageManager.h"
#import <YYKit/UIImage+YYAdd.h>
#import <YYKit/UIColor+YYAdd.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface HGGifPhotoPreviewController () {
    UIView *_toolBar;
    UIButton *_doneButton;
    UIProgressView *_progress;
    
    HGPhotoPreviewView *_previewView;
    
    UIStatusBarStyle _originStatusBarStyle;
}
@end

@implementation HGGifPhotoPreviewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    HGImagePickerController *hgImagePickerVc = (HGImagePickerController *)self.navigationController;
    if (hgImagePickerVc) {
        self.navigationItem.title = [NSString stringWithFormat:@"GIF %@",hgImagePickerVc.previewBtnTitleStr];
    }
    [self configPreviewView];
    [self configBottomToolBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _originStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarStyle = _originStatusBarStyle;
}

- (void)configPreviewView {
    _previewView = [[HGPhotoPreviewView alloc] initWithFrame:CGRectZero];
    _previewView.model = self.model;
    __weak typeof(self) weakSelf = self;
    [_previewView setSingleTapGestureBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf signleTapAction];
    }];
    [self.view addSubview:_previewView];
}

- (void)configBottomToolBar {
    _toolBar = [[UIView alloc] initWithFrame:CGRectZero];
    CGFloat rgb = 34 / 255.0;
    _toolBar.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:0.7];
//    _toolBar.backgroundColor = [UIColor clearColor];
 
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_doneButton addTarget:self action:@selector(doneButtonClick) forControlEvents:UIControlEventTouchUpInside];
    HGImagePickerController *hgImagePickerVc = (HGImagePickerController *)self.navigationController;
//    if (hgImagePickerVc) {
//        [_doneButton setTitle:hgImagePickerVc.doneBtnTitleStr forState:UIControlStateNormal];
//        [_doneButton setTitleColor:hgImagePickerVc.oKButtonTitleColorNormal forState:UIControlStateNormal];
//    } else {
//        [_doneButton setTitle:[NSBundle hg_localizedStringForKey:@"Done"] forState:UIControlStateNormal];
//        [_doneButton setTitleColor:[UIColor colorWithRed:(83/255.0) green:(179/255.0) blue:(17/255.0) alpha:1.0] forState:UIControlStateNormal];
//    }
    [_doneButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithHexString:@"#FFCE00"]] forState:UIControlStateNormal];
    [_doneButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithHexString:@"#E0E0E0"]] forState:UIControlStateDisabled];
    [_doneButton setImage:[UIImage hg_imageNamedFromMyBundle:@"photo_send"] forState:UIControlStateNormal];
    
    [_toolBar addSubview:_doneButton];
    
//    UILabel *byteLabel = [[UILabel alloc] init];
//    byteLabel.textColor = [UIColor whiteColor];
//    byteLabel.font = [UIFont systemFontOfSize:13];
//    byteLabel.frame = CGRectMake(10, 0, 100, 44);
//    [[HGImageManager manager] getPhotosBytesWithArray:@[_model] completion:^(NSString *totalBytes) {
//        byteLabel.text = totalBytes;
//    }];
//    [_toolBar addSubview:byteLabel];
    
    [self.view addSubview:_toolBar];
    
    if (hgImagePickerVc.gifPreviewPageUIConfigBlock) {
        hgImagePickerVc.gifPreviewPageUIConfigBlock(_toolBar, _doneButton);
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    HGImagePickerController *HGImagePicker = (HGImagePickerController *)self.navigationController;
    if (HGImagePicker && [HGImagePicker isKindOfClass:[HGImagePickerController class]]) {
        return HGImagePicker.statusBarStyle;
    }
    return [super preferredStatusBarStyle];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    _previewView.frame = self.view.bounds;
    _previewView.scrollView.frame = self.view.bounds;
    CGFloat toolBarHeight = [HGCommonTools hg_isIPhoneX] ? 44 + (83 - 49) : 44;
    _toolBar.frame = CGRectMake(0, self.view.hg_height - toolBarHeight, self.view.hg_width, toolBarHeight);
//    _doneButton.frame = CGRectMake(self.view.hg_width - 44 - 12, 0, 44, 44);
    
    _doneButton.frame = CGRectMake(self.view.hg_width - 50 - 10, 10, 50, 30);
    _doneButton.layer.cornerRadius = 30/2;
    _doneButton.clipsToBounds = YES;
    
    HGImagePickerController *hgImagePickerVc = (HGImagePickerController *)self.navigationController;
    if (hgImagePickerVc.gifPreviewPageDidLayoutSubviewsBlock) {
        hgImagePickerVc.gifPreviewPageDidLayoutSubviewsBlock(_toolBar, _doneButton);
    }
}

#pragma mark - Click Event

- (void)signleTapAction {
    _toolBar.hidden = !_toolBar.isHidden;
    [self.navigationController setNavigationBarHidden:_toolBar.isHidden];
    HGImagePickerController *hgImagePickerVc = (HGImagePickerController *)self.navigationController;
    if (_toolBar.isHidden) {
        [UIApplication sharedApplication].statusBarHidden = YES;
    } else if (hgImagePickerVc.needShowStatusBar) {
        [UIApplication sharedApplication].statusBarHidden = NO;
    }
}

- (void)doneButtonClick {
    if (self.navigationController) {
        HGImagePickerController *imagePickerVc = (HGImagePickerController *)self.navigationController;
        if (imagePickerVc.autoDismiss) {
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                [self callDelegateMethod];
            }];
        } else {
            [self callDelegateMethod];
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            [self callDelegateMethod];
        }];
    }
}

- (void)callDelegateMethod {
    HGImagePickerController *imagePickerVc = (HGImagePickerController *)self.navigationController;
    UIImage *animatedImage = _previewView.imageView.image;
    if ([imagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingGifImage:sourceAssets:)]) {
        [imagePickerVc.pickerDelegate imagePickerController:imagePickerVc didFinishPickingGifImage:animatedImage sourceAssets:_model.asset];
    }
    if (imagePickerVc.didFinishPickingGifImageHandle) {
        imagePickerVc.didFinishPickingGifImageHandle(animatedImage,_model.asset);
    }
}

#pragma clang diagnostic pop

@end
