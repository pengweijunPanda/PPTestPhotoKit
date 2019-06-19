//
//  HGVideoPlayerController.m
//  HGImagePickerController
//
//  Created by pengweijun on 2019/6/18.
//  Copyright © 2019年 彭伟军. All rights reserved.
//

#import "HGVideoPlayerController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "UIView+Layout.h"
#import "HGImageManager.h"
#import "HGAssetModel.h"
#import "HGImagePickerController.h"
#import "HGPhotoPreviewController.h"

#import <YYKit/UIImage+YYAdd.h>
#import <YYKit/UIColor+YYAdd.h>

@interface HGVideoPlayerController () {
    AVPlayer *_player;
    AVPlayerLayer *_playerLayer;
    UIButton *_playButton;
    UIImage *_cover;
    
    UIView *_toolBar;
    UIButton *_doneButton;
    UIProgressView *_progress;
    
    UIStatusBarStyle _originStatusBarStyle;
}
@property (assign, nonatomic) BOOL needShowStatusBar;
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation HGVideoPlayerController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.needShowStatusBar = ![UIApplication sharedApplication].statusBarHidden;
    self.view.backgroundColor = [UIColor blackColor];
    HGImagePickerController *hgImagePickerVc = (HGImagePickerController *)self.navigationController;
    if (hgImagePickerVc) {
        self.navigationItem.title = hgImagePickerVc.previewBtnTitleStr;
    }
    [self configMoviePlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pausePlayerAndShowNaviBar) name:UIApplicationWillResignActiveNotification object:nil];
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

- (void)configMoviePlayer {
    [[HGImageManager manager] getPhotoWithAsset:_model.asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        if (!isDegraded && photo) {
            self->_cover = photo;
            self->_doneButton.enabled = YES;
        }
    }];
    [[HGImageManager manager] getVideoWithAsset:_model.asset completion:^(AVPlayerItem *playerItem, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_player = [AVPlayer playerWithPlayerItem:playerItem];
            self->_playerLayer = [AVPlayerLayer playerLayerWithPlayer:self->_player];
            self->_playerLayer.frame = self.view.bounds;
            [self.view.layer addSublayer:self->_playerLayer];
            [self addProgressObserver];
            [self configPlayButton];
            [self configBottomToolBar];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pausePlayerAndShowNaviBar) name:AVPlayerItemDidPlayToEndTimeNotification object:self->_player.currentItem];
        });
    }];
}

/// Show progress，do it next time / 给播放器添加进度更新,下次加上
- (void)addProgressObserver{
    AVPlayerItem *playerItem = _player.currentItem;
    UIProgressView *progress = _progress;
    [_player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current = CMTimeGetSeconds(time);
        float total = CMTimeGetSeconds([playerItem duration]);
        if (current) {
            [progress setProgress:(current/total) animated:YES];
        }
    }];
}

- (void)configPlayButton {
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_playButton setImage:[UIImage hg_imageNamedFromMyBundle:@"MMVideoPreviewPlay"] forState:UIControlStateNormal];
    [_playButton setImage:[UIImage hg_imageNamedFromMyBundle:@"MMVideoPreviewPlayHL"] forState:UIControlStateHighlighted];
    [_playButton addTarget:self action:@selector(playButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_playButton];
}

- (void)configBottomToolBar {
    _toolBar = [[UIView alloc] initWithFrame:CGRectZero];
    CGFloat rgb = 34 / 255.0;
    _toolBar.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:0.7];
//    _toolBar.backgroundColor = [UIColor clearColor];

    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.titleLabel.font = [UIFont systemFontOfSize:16];
    if (!_cover) {
        _doneButton.enabled = NO;
    }
    [_doneButton addTarget:self action:@selector(doneButtonClick) forControlEvents:UIControlEventTouchUpInside];
    HGImagePickerController *hgImagePickerVc = (HGImagePickerController *)self.navigationController;
    
    [_doneButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithHexString:@"#FFCE00"]] forState:UIControlStateNormal];
    [_doneButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithHexString:@"#E0E0E0"]] forState:UIControlStateDisabled];
    [_doneButton setImage:[UIImage hg_imageNamedFromMyBundle:@"photo_send"] forState:UIControlStateNormal];

//    if (hgImagePickerVc) {
//        [_doneButton setTitle:hgImagePickerVc.doneBtnTitleStr forState:UIControlStateNormal];
//        [_doneButton setTitleColor:hgImagePickerVc.oKButtonTitleColorNormal forState:UIControlStateNormal];
//    } else {
//        [_doneButton setTitle:[NSBundle hg_localizedStringForKey:@"Done"] forState:UIControlStateNormal];
//        [_doneButton setTitleColor:[UIColor colorWithRed:(83/255.0) green:(179/255.0) blue:(17/255.0) alpha:1.0] forState:UIControlStateNormal];
//    }
//    [_doneButton setTitleColor:hgImagePickerVc.oKButtonTitleColorDisabled forState:UIControlStateDisabled];
    [_toolBar addSubview:_doneButton];
    [self.view addSubview:_toolBar];
    
    if (hgImagePickerVc.videoPreviewPageUIConfigBlock) {
        hgImagePickerVc.videoPreviewPageUIConfigBlock(_playButton, _toolBar, _doneButton);
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
    
    CGFloat statusBarHeight = [HGCommonTools hg_statusBarHeight];
    CGFloat statusBarAndNaviBarHeight = statusBarHeight + self.navigationController.navigationBar.hg_height;
    _playerLayer.frame = self.view.bounds;
    CGFloat toolBarHeight = [HGCommonTools hg_isIPhoneX] ? 44 + (83 - 49) : 44;
    _toolBar.frame = CGRectMake(0, self.view.hg_height - toolBarHeight, self.view.hg_width, toolBarHeight);
//    _doneButton.frame = CGRectMake(self.view.hg_width - 44 - 12, 0, 44, 44);
    
    _doneButton.frame = CGRectMake(self.view.hg_width - 50 - 10, 10, 50, 30);
    _doneButton.layer.cornerRadius = 30/2;
    _doneButton.clipsToBounds = YES;
    
    _playButton.frame = CGRectMake(0, statusBarAndNaviBarHeight, self.view.hg_width, self.view.hg_height - statusBarAndNaviBarHeight - toolBarHeight);
    
    HGImagePickerController *hgImagePickerVc = (HGImagePickerController *)self.navigationController;
    if (hgImagePickerVc.videoPreviewPageDidLayoutSubviewsBlock) {
        hgImagePickerVc.videoPreviewPageDidLayoutSubviewsBlock(_playButton, _toolBar, _doneButton);
    }
}

#pragma mark - Click Event

- (void)playButtonClick {
    CMTime currentTime = _player.currentItem.currentTime;
    CMTime durationTime = _player.currentItem.duration;
    if (_player.rate == 0.0f) {
        if (currentTime.value == durationTime.value) [_player.currentItem seekToTime:CMTimeMake(0, 1)];
        [_player play];
        [self.navigationController setNavigationBarHidden:YES];
        _toolBar.hidden = YES;
        [_playButton setImage:nil forState:UIControlStateNormal];
        [UIApplication sharedApplication].statusBarHidden = YES;
    } else {
        [self pausePlayerAndShowNaviBar];
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
    if ([imagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingVideo:sourceAssets:)]) {
        [imagePickerVc.pickerDelegate imagePickerController:imagePickerVc didFinishPickingVideo:_cover sourceAssets:_model.asset];
    }
    if (imagePickerVc.didFinishPickingVideoHandle) {
        imagePickerVc.didFinishPickingVideoHandle(_cover,_model.asset);
    }
}

#pragma mark - Notification Method

- (void)pausePlayerAndShowNaviBar {
    [_player pause];
    _toolBar.hidden = NO;
    [self.navigationController setNavigationBarHidden:NO];
    [_playButton setImage:[UIImage hg_imageNamedFromMyBundle:@"MMVideoPreviewPlay"] forState:UIControlStateNormal];
    
    if (self.needShowStatusBar) {
        [UIApplication sharedApplication].statusBarHidden = NO;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma clang diagnostic pop

@end
