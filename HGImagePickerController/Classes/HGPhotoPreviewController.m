//
//  HGPhotoPreviewController.m
//  HGImagePickerController
//
//  Created by pengweijun on 2019/6/18.
//  Copyright © 2019年 彭伟军. All rights reserved.
//

#import "HGPhotoPreviewController.h"
#import "HGPhotoPreviewCell.h"
#import "HGAssetModel.h"
#import "UIView+Layout.h"
#import "HGImagePickerController.h"
#import "HGImageManager.h"
#import "HGImageCropManager.h"
#import <YYKit/UIImage+YYAdd.h>
#import <YYKit/UIColor+YYAdd.h>

@interface HGPhotoPreviewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIScrollViewDelegate> {
    UICollectionView *_collectionView;
    UICollectionViewFlowLayout *_layout;
    NSArray *_photosTemp;
    NSArray *_assetsTemp;
    
    UIView *_naviBar;
    UIButton *_backButton;
    UIButton *_selectButton;
    UILabel *_indexLabel;
    
    UIView *_toolBar;
    UIButton *_doneButton;
    UIImageView *_numberImageView;
    UILabel *_numberLabel;
    UIButton *_originalPhotoButton;
    UILabel *_originalPhotoLabel;
    
    CGFloat _offsetItemCount;
    
    BOOL _didSetIsSelectOriginalPhoto;
}
@property (nonatomic, assign) BOOL isHideNaviBar;
@property (nonatomic, strong) UIView *cropBgView;
@property (nonatomic, strong) UIView *cropView;

@property (nonatomic, assign) double progress;
@property (strong, nonatomic) UIAlertController *alertView;
@end

@implementation HGPhotoPreviewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [HGImageManager manager].shouldFixOrientation = YES;
    HGImagePickerController *_hgImagePickerVc = (HGImagePickerController *)self.navigationController;
    if (!_didSetIsSelectOriginalPhoto) {
        _isSelectOriginalPhoto = _hgImagePickerVc.isSelectOriginalPhoto;
    }
    if (!self.models.count) {
        self.models = [NSMutableArray arrayWithArray:_hgImagePickerVc.selectedModels];
        _assetsTemp = [NSMutableArray arrayWithArray:_hgImagePickerVc.selectedAssets];
    }
    [self configCollectionView];
    [self configCustomNaviBar];
    [self configBottomToolBar];
    self.view.clipsToBounds = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeStatusBarOrientationNotification:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)setIsSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
    _isSelectOriginalPhoto = isSelectOriginalPhoto;
    _didSetIsSelectOriginalPhoto = YES;
}

- (void)setPhotos:(NSMutableArray *)photos {
    _photos = photos;
    _photosTemp = [NSArray arrayWithArray:photos];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [UIApplication sharedApplication].statusBarHidden = YES;
    if (_currentIndex) {
        [_collectionView setContentOffset:CGPointMake((self.view.hg_width + 20) * self.currentIndex, 0) animated:NO];
    }
    [self refreshNaviBarAndBottomBarState];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    HGImagePickerController *hgImagePickerVc = (HGImagePickerController *)self.navigationController;
    if (hgImagePickerVc.needShowStatusBar) {
        [UIApplication sharedApplication].statusBarHidden = NO;
    }
    [HGImageManager manager].shouldFixOrientation = NO;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)configCustomNaviBar {
    HGImagePickerController *hgImagePickerVc = (HGImagePickerController *)self.navigationController;
    
    _naviBar = [[UIView alloc] initWithFrame:CGRectZero];
    _naviBar.backgroundColor = [UIColor colorWithRed:(34/255.0) green:(34/255.0)  blue:(34/255.0) alpha:0.7];
    
    _backButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_backButton setImage:[UIImage hg_imageNamedFromMyBundle:@"navi_back"] forState:UIControlStateNormal];
    [_backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_backButton addTarget:self action:@selector(backButtonClick) forControlEvents:UIControlEventTouchUpInside];
    
    _selectButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_selectButton setImage:hgImagePickerVc.photoDefImage forState:UIControlStateNormal];
    [_selectButton setImage:hgImagePickerVc.photoSelImage forState:UIControlStateSelected];
    _selectButton.imageView.clipsToBounds = YES;
    _selectButton.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 0);
    _selectButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [_selectButton addTarget:self action:@selector(select:) forControlEvents:UIControlEventTouchUpInside];
    _selectButton.hidden = !hgImagePickerVc.showSelectBtn;
    
    _indexLabel = [[UILabel alloc] init];
    _indexLabel.font = [UIFont systemFontOfSize:14];
    _indexLabel.textColor = [UIColor whiteColor];
    _indexLabel.textAlignment = NSTextAlignmentCenter;
    
    [_naviBar addSubview:_selectButton];
    [_naviBar addSubview:_indexLabel];
    [_naviBar addSubview:_backButton];
    [self.view addSubview:_naviBar];
}

- (void)configBottomToolBar {
    _toolBar = [[UIView alloc] initWithFrame:CGRectZero];
    static CGFloat rgb = 34 / 255.0;
    _toolBar.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:0.7];
//    _toolBar.backgroundColor = [UIColor clearColor];

    HGImagePickerController *_hgImagePickerVc = (HGImagePickerController *)self.navigationController;
    if (_hgImagePickerVc.allowPickingOriginalPhoto) {
        _originalPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _originalPhotoButton.imageEdgeInsets = UIEdgeInsetsMake(0, [HGCommonTools hg_isRightToLeftLayout] ? 10 : -10, 0, 0);
        _originalPhotoButton.backgroundColor = [UIColor clearColor];
        [_originalPhotoButton addTarget:self action:@selector(originalPhotoButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _originalPhotoButton.titleLabel.font = [UIFont systemFontOfSize:13];
        [_originalPhotoButton setTitle:_hgImagePickerVc.fullImageBtnTitleStr forState:UIControlStateNormal];
        [_originalPhotoButton setTitle:_hgImagePickerVc.fullImageBtnTitleStr forState:UIControlStateSelected];
        [_originalPhotoButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [_originalPhotoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [_originalPhotoButton setImage:_hgImagePickerVc.photoPreviewOriginDefImage forState:UIControlStateNormal];
        [_originalPhotoButton setImage:_hgImagePickerVc.photoOriginSelImage forState:UIControlStateSelected];
        
        _originalPhotoLabel = [[UILabel alloc] init];
        _originalPhotoLabel.textAlignment = NSTextAlignmentLeft;
        _originalPhotoLabel.font = [UIFont systemFontOfSize:13];
        _originalPhotoLabel.textColor = [UIColor whiteColor];
        _originalPhotoLabel.backgroundColor = [UIColor clearColor];
        if (_isSelectOriginalPhoto) [self showPhotoBytes];
    }
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_doneButton addTarget:self action:@selector(doneButtonClick) forControlEvents:UIControlEventTouchUpInside];
//    [_doneButton setTitle:_hgImagePickerVc.doneBtnTitleStr forState:UIControlStateNormal];
//    [_doneButton setTitleColor:_hgImagePickerVc.oKButtonTitleColorNormal forState:UIControlStateNormal];
    [_doneButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithHexString:@"#FFCE00"]] forState:UIControlStateNormal];
    [_doneButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithHexString:@"#E0E0E0"]] forState:UIControlStateDisabled];
    [_doneButton setImage:[UIImage hg_imageNamedFromMyBundle:@"photo_send"] forState:UIControlStateNormal];

//    _numberImageView = [[UIImageView alloc] initWithImage:_hgImagePickerVc.photoNumberIconImage];
//    _numberImageView.backgroundColor = [UIColor clearColor];
//    _numberImageView.clipsToBounds = YES;
//    _numberImageView.contentMode = UIViewContentModeScaleAspectFit;
//    _numberImageView.hidden = _hgImagePickerVc.selectedModels.count <= 0;
    
//    _numberLabel = [[UILabel alloc] init];
//    _numberLabel.font = [UIFont systemFontOfSize:15];
//    _numberLabel.textColor = [UIColor whiteColor];
//    _numberLabel.textAlignment = NSTextAlignmentCenter;
//    _numberLabel.text = [NSString stringWithFormat:@"%zd",_hgImagePickerVc.selectedModels.count];
//    _numberLabel.hidden = _hgImagePickerVc.selectedModels.count <= 0;
//    _numberLabel.backgroundColor = [UIColor clearColor];
    
    [_originalPhotoButton addSubview:_originalPhotoLabel];
    [_toolBar addSubview:_doneButton];
    [_toolBar addSubview:_originalPhotoButton];
//    [_toolBar addSubview:_numberImageView];
//    [_toolBar addSubview:_numberLabel];
    [self.view addSubview:_toolBar];
    
    if (_hgImagePickerVc.photoPreviewPageUIConfigBlock) {
        _hgImagePickerVc.photoPreviewPageUIConfigBlock(_collectionView, _naviBar, _backButton, _selectButton, _indexLabel, _toolBar, _originalPhotoButton, _originalPhotoLabel, _doneButton, _numberImageView, _numberLabel);
    }
}

- (void)configCollectionView {
    _layout = [[UICollectionViewFlowLayout alloc] init];
    _layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_layout];
    _collectionView.backgroundColor = [UIColor blackColor];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.pagingEnabled = YES;
    _collectionView.scrollsToTop = NO;
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.contentOffset = CGPointMake(0, 0);
    _collectionView.contentSize = CGSizeMake(self.models.count * (self.view.hg_width + 20), 0);
    [self.view addSubview:_collectionView];
    [_collectionView registerClass:[HGPhotoPreviewCell class] forCellWithReuseIdentifier:@"HGPhotoPreviewCell"];
    [_collectionView registerClass:[HGVideoPreviewCell class] forCellWithReuseIdentifier:@"HGVideoPreviewCell"];
    [_collectionView registerClass:[HGGifPreviewCell class] forCellWithReuseIdentifier:@"HGGifPreviewCell"];
}

- (void)configCropView {
    HGImagePickerController *_hgImagePickerVc = (HGImagePickerController *)self.navigationController;
    if (_hgImagePickerVc.maxImagesCount <= 1 && _hgImagePickerVc.allowCrop && _hgImagePickerVc.allowPickingImage) {
        [_cropView removeFromSuperview];
        [_cropBgView removeFromSuperview];
        
        _cropBgView = [UIView new];
        _cropBgView.userInteractionEnabled = NO;
        _cropBgView.frame = self.view.bounds;
        _cropBgView.backgroundColor = [UIColor clearColor];
        [self.view addSubview:_cropBgView];
        [HGImageCropManager overlayClippingWithView:_cropBgView cropRect:_hgImagePickerVc.cropRect containerView:self.view needCircleCrop:_hgImagePickerVc.needCircleCrop];
        
        _cropView = [UIView new];
        _cropView.userInteractionEnabled = NO;
        _cropView.frame = _hgImagePickerVc.cropRect;
        _cropView.backgroundColor = [UIColor clearColor];
        _cropView.layer.borderColor = [UIColor whiteColor].CGColor;
        _cropView.layer.borderWidth = 1.0;
        if (_hgImagePickerVc.needCircleCrop) {
            _cropView.layer.cornerRadius = _hgImagePickerVc.cropRect.size.width / 2;
            _cropView.clipsToBounds = YES;
        }
        [self.view addSubview:_cropView];
        if (_hgImagePickerVc.cropViewSettingBlock) {
            _hgImagePickerVc.cropViewSettingBlock(_cropView);
        }
        
        [self.view bringSubviewToFront:_naviBar];
        [self.view bringSubviewToFront:_toolBar];
    }
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    HGImagePickerController *_hgImagePickerVc = (HGImagePickerController *)self.navigationController;
    
    CGFloat statusBarHeight = [HGCommonTools hg_statusBarHeight];
    CGFloat statusBarHeightInterval = statusBarHeight - 20;
    CGFloat naviBarHeight = statusBarHeight + _hgImagePickerVc.navigationBar.hg_height;
    _naviBar.frame = CGRectMake(0, 0, self.view.hg_width, naviBarHeight);
    _backButton.frame = CGRectMake(10, 10 + statusBarHeightInterval, 44, 44);
    _selectButton.frame = CGRectMake(self.view.hg_width - 56, 10 + statusBarHeightInterval, 44, 44);
    _indexLabel.frame = _selectButton.frame;
    
    _layout.itemSize = CGSizeMake(self.view.hg_width + 20, self.view.hg_height);
    _layout.minimumInteritemSpacing = 0;
    _layout.minimumLineSpacing = 0;
    _collectionView.frame = CGRectMake(-10, 0, self.view.hg_width + 20, self.view.hg_height);
    [_collectionView setCollectionViewLayout:_layout];
    if (_offsetItemCount > 0) {
        CGFloat offsetX = _offsetItemCount * _layout.itemSize.width;
        [_collectionView setContentOffset:CGPointMake(offsetX, 0)];
    }
    if (_hgImagePickerVc.allowCrop) {
        [_collectionView reloadData];
    }
    
    CGFloat toolBarHeight = [HGCommonTools hg_isIPhoneX] ? 44 + (83 - 49) : 44;
    CGFloat toolBarTop = self.view.hg_height - toolBarHeight;
    _toolBar.frame = CGRectMake(0, toolBarTop, self.view.hg_width, toolBarHeight);
    if (_hgImagePickerVc.allowPickingOriginalPhoto) {
        CGFloat fullImageWidth = [_hgImagePickerVc.fullImageBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13]} context:nil].size.width;
        _originalPhotoButton.frame = CGRectMake(0, 0, fullImageWidth + 56, 44);
        _originalPhotoLabel.frame = CGRectMake(fullImageWidth + 42, 0, 80, 44);
    }
//    [_doneButton sizeToFit];
//    _doneButton.frame = CGRectMake(self.view.hg_width - _doneButton.hg_width - 12, 0, _doneButton.hg_width, 44);
    
    _doneButton.frame = CGRectMake(self.view.hg_width - 50 - 10, 10, 50, 30);
    _doneButton.layer.cornerRadius = 30/2;
    _doneButton.clipsToBounds = YES;
    
    _numberImageView.frame = CGRectMake(_doneButton.hg_left - 24 - 5, 10, 24, 24);
    _numberLabel.frame = _numberImageView.frame;
    
    [self configCropView];
    
    if (_hgImagePickerVc.photoPreviewPageDidLayoutSubviewsBlock) {
        _hgImagePickerVc.photoPreviewPageDidLayoutSubviewsBlock(_collectionView, _naviBar, _backButton, _selectButton, _indexLabel, _toolBar, _originalPhotoButton, _originalPhotoLabel, _doneButton, _numberImageView, _numberLabel);
    }
}

#pragma mark - Notification

- (void)didChangeStatusBarOrientationNotification:(NSNotification *)noti {
    _offsetItemCount = _collectionView.contentOffset.x / _layout.itemSize.width;
}

#pragma mark - Click Event

- (void)select:(UIButton *)selectButton {
    HGImagePickerController *_hgImagePickerVc = (HGImagePickerController *)self.navigationController;
    HGAssetModel *model = _models[self.currentIndex];
    if (!selectButton.isSelected) {
        // 1. select:check if over the maxImagesCount / 选择照片,检查是否超过了最大个数的限制
        if (_hgImagePickerVc.selectedModels.count >= _hgImagePickerVc.maxImagesCount) {
            NSString *title = [NSString stringWithFormat:[NSBundle hg_localizedStringForKey:@"Select a maximum of %zd photos"], _hgImagePickerVc.maxImagesCount];
            [_hgImagePickerVc showAlertWithTitle:title];
            return;
            // 2. if not over the maxImagesCount / 如果没有超过最大个数限制
        } else {
            [_hgImagePickerVc addSelectedModel:model];
            if (self.photos) {
                [_hgImagePickerVc.selectedAssets addObject:_assetsTemp[self.currentIndex]];
                [self.photos addObject:_photosTemp[self.currentIndex]];
            }
            if (model.type == HGAssetModelMediaTypeVideo && !_hgImagePickerVc.allowPickingMultipleVideo) {
                [_hgImagePickerVc showAlertWithTitle:[NSBundle hg_localizedStringForKey:@"Select the video when in multi state, we will handle the video as a photo"]];
            }
        }
    } else {
        NSArray *selectedModels = [NSArray arrayWithArray:_hgImagePickerVc.selectedModels];
        for (HGAssetModel *model_item in selectedModels) {
            if ([model.asset.localIdentifier isEqualToString:model_item.asset.localIdentifier]) {
                // 1.6.7版本更新:防止有多个一样的model,一次性被移除了
                NSArray *selectedModelsTmp = [NSArray arrayWithArray:_hgImagePickerVc.selectedModels];
                for (NSInteger i = 0; i < selectedModelsTmp.count; i++) {
                    HGAssetModel *model = selectedModelsTmp[i];
                    if ([model isEqual:model_item]) {
                        [_hgImagePickerVc removeSelectedModel:model];
                        // [_hgImagePickerVc.selectedModels removeObjectAtIndex:i];
                        break;
                    }
                }
                if (self.photos) {
                    // 1.6.7版本更新:防止有多个一样的asset,一次性被移除了
                    NSArray *selectedAssetsTmp = [NSArray arrayWithArray:_hgImagePickerVc.selectedAssets];
                    for (NSInteger i = 0; i < selectedAssetsTmp.count; i++) {
                        id asset = selectedAssetsTmp[i];
                        if ([asset isEqual:_assetsTemp[self.currentIndex]]) {
                            [_hgImagePickerVc.selectedAssets removeObjectAtIndex:i];
                            break;
                        }
                    }
                    // [_hgImagePickerVc.selectedAssets removeObject:_assetsTemp[self.currentIndex]];
                    [self.photos removeObject:_photosTemp[self.currentIndex]];
                }
                break;
            }
        }
    }
    model.isSelected = !selectButton.isSelected;
    [self refreshNaviBarAndBottomBarState];
    if (model.isSelected) {
        [UIView showOscillatoryAnimationWithLayer:selectButton.imageView.layer type:HGOscillatoryAnimationToBigger];
    }
    [UIView showOscillatoryAnimationWithLayer:_numberImageView.layer type:HGOscillatoryAnimationToSmaller];
}

- (void)backButtonClick {
    if (self.navigationController.childViewControllers.count < 2) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        if ([self.navigationController isKindOfClass: [HGImagePickerController class]]) {
            HGImagePickerController *nav = (HGImagePickerController *)self.navigationController;
            if (nav.imagePickerControllerDidCancelHandle) {
                nav.imagePickerControllerDidCancelHandle();
            }
        }
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
    if (self.backButtonClickBlock) {
        self.backButtonClickBlock(_isSelectOriginalPhoto);
    }
}

- (void)doneButtonClick {
    HGImagePickerController *_hgImagePickerVc = (HGImagePickerController *)self.navigationController;
    // 如果图片正在从iCloud同步中,提醒用户
    if (_progress > 0 && _progress < 1 && (_selectButton.isSelected || !_hgImagePickerVc.selectedModels.count )) {
        _alertView = [_hgImagePickerVc showAlertWithTitle:[NSBundle hg_localizedStringForKey:@"Synchronizing photos from iCloud"]];
        return;
    }
    
    // 如果没有选中过照片 点击确定时选中当前预览的照片
    if (_hgImagePickerVc.selectedModels.count == 0 && _hgImagePickerVc.minImagesCount <= 0) {
        HGAssetModel *model = _models[self.currentIndex];
        [_hgImagePickerVc addSelectedModel:model];
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.currentIndex inSection:0];
    HGPhotoPreviewCell *cell = (HGPhotoPreviewCell *)[_collectionView cellForItemAtIndexPath:indexPath];
    if (_hgImagePickerVc.allowCrop && [cell isKindOfClass:[HGPhotoPreviewCell class]]) { // 裁剪状态
        _doneButton.enabled = NO;
        [_hgImagePickerVc showProgressHUD];
        UIImage *cropedImage = [HGImageCropManager cropImageView:cell.previewView.imageView toRect:_hgImagePickerVc.cropRect zoomScale:cell.previewView.scrollView.zoomScale containerView:self.view];
        if (_hgImagePickerVc.needCircleCrop) {
            cropedImage = [HGImageCropManager circularClipImage:cropedImage];
        }
        _doneButton.enabled = YES;
        [_hgImagePickerVc hideProgressHUD];
        if (self.doneButtonClickBlockCropMode) {
            HGAssetModel *model = _models[self.currentIndex];
            self.doneButtonClickBlockCropMode(cropedImage,model.asset);
        }
    } else if (self.doneButtonClickBlock) { // 非裁剪状态
        self.doneButtonClickBlock(_isSelectOriginalPhoto);
    }
    NSArray *localPaths = [self processLocalPaths];
    if (self.doneButtonClickBlockWithPreviewType) {
        self.doneButtonClickBlockWithPreviewType(self.photos,localPaths,_hgImagePickerVc.selectedAssets,self.isSelectOriginalPhoto);
    }
}

- (NSArray <NSString *>*)processLocalPaths{
    HGImagePickerController *_hgImagePickerVc = (HGImagePickerController *)self.navigationController;
    [_hgImagePickerVc.selectedModels enumerateObjectsUsingBlock:^(HGAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
    }];
    return @[];
}

- (void)originalPhotoButtonClick {
    _originalPhotoButton.selected = !_originalPhotoButton.isSelected;
    _isSelectOriginalPhoto = _originalPhotoButton.isSelected;
    _originalPhotoLabel.hidden = !_originalPhotoButton.isSelected;
    if (_isSelectOriginalPhoto) {
        [self showPhotoBytes];
        if (!_selectButton.isSelected) {
            // 如果当前已选择照片张数 < 最大可选张数 && 最大可选张数大于1，就选中该张图
            HGImagePickerController *_hgImagePickerVc = (HGImagePickerController *)self.navigationController;
            if (_hgImagePickerVc.selectedModels.count < _hgImagePickerVc.maxImagesCount && _hgImagePickerVc.showSelectBtn) {
                [self select:_selectButton];
            }
        }
    }
}

- (void)didTapPreviewCell {
    self.isHideNaviBar = !self.isHideNaviBar;
    _naviBar.hidden = self.isHideNaviBar;
    _toolBar.hidden = self.isHideNaviBar;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offSetWidth = scrollView.contentOffset.x;
    offSetWidth = offSetWidth +  ((self.view.hg_width + 20) * 0.5);
    
    NSInteger currentIndex = offSetWidth / (self.view.hg_width + 20);
    if (currentIndex < _models.count && _currentIndex != currentIndex) {
        _currentIndex = currentIndex;
        [self refreshNaviBarAndBottomBarState];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"photoPreviewCollectionViewDidScroll" object:nil];
}

#pragma mark - UICollectionViewDataSource && Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _models.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HGImagePickerController *_hgImagePickerVc = (HGImagePickerController *)self.navigationController;
    HGAssetModel *model = _models[indexPath.item];
    
    HGAssetPreviewCell *cell;
    __weak typeof(self) weakSelf = self;
    if (_hgImagePickerVc.allowPickingMultipleVideo && model.type == HGAssetModelMediaTypeVideo) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HGVideoPreviewCell" forIndexPath:indexPath];
    } else if (_hgImagePickerVc.allowPickingMultipleVideo && model.type == HGAssetModelMediaTypePhotoGif && _hgImagePickerVc.allowPickingGif) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HGGifPreviewCell" forIndexPath:indexPath];
    } else {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HGPhotoPreviewCell" forIndexPath:indexPath];
        HGPhotoPreviewCell *photoPreviewCell = (HGPhotoPreviewCell *)cell;
        photoPreviewCell.cropRect = _hgImagePickerVc.cropRect;
        photoPreviewCell.allowCrop = _hgImagePickerVc.allowCrop;
        photoPreviewCell.scaleAspectFillCrop = _hgImagePickerVc.scaleAspectFillCrop;
        __weak typeof(_hgImagePickerVc) weakhgImagePickerVc = _hgImagePickerVc;
        __weak typeof(_collectionView) weakCollectionView = _collectionView;
        __weak typeof(photoPreviewCell) weakCell = photoPreviewCell;
        [photoPreviewCell setImageProgressUpdateBlock:^(double progress) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            __strong typeof(weakhgImagePickerVc) stronghgImagePickerVc = weakhgImagePickerVc;
            __strong typeof(weakCollectionView) strongCollectionView = weakCollectionView;
            __strong typeof(weakCell) strongCell = weakCell;
            strongSelf.progress = progress;
            if (progress >= 1) {
                if (strongSelf.isSelectOriginalPhoto) [strongSelf showPhotoBytes];
                if (strongSelf.alertView && [strongCollectionView.visibleCells containsObject:strongCell]) {
                    [stronghgImagePickerVc hideAlertView:strongSelf.alertView];
                    strongSelf.alertView = nil;
                    [strongSelf doneButtonClick];
                }
            }
        }];
    }
    
    cell.model = model;
    [cell setSingleTapGestureBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf didTapPreviewCell];
    }];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[HGPhotoPreviewCell class]]) {
        [(HGPhotoPreviewCell *)cell recoverSubviews];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[HGPhotoPreviewCell class]]) {
        [(HGPhotoPreviewCell *)cell recoverSubviews];
    } else if ([cell isKindOfClass:[HGVideoPreviewCell class]]) {
        HGVideoPreviewCell *videoCell = (HGVideoPreviewCell *)cell;
        if (videoCell.player && videoCell.player.rate != 0.0) {
            [videoCell pausePlayerAndShowNaviBar];
        }
    }
}

#pragma mark - Private Method

- (void)dealloc {
    // NSLog(@"%@ dealloc",NSStringFromClass(self.class));
}

- (void)refreshNaviBarAndBottomBarState {
    HGImagePickerController *_hgImagePickerVc = (HGImagePickerController *)self.navigationController;
    HGAssetModel *model = _models[self.currentIndex];
    _selectButton.selected = model.isSelected;
    [self refreshSelectButtonImageViewContentMode];
    if (_selectButton.isSelected && _hgImagePickerVc.showSelectedIndex && _hgImagePickerVc.showSelectBtn) {
        NSString *index = [NSString stringWithFormat:@"%d", (int)([_hgImagePickerVc.selectedAssetIds indexOfObject:model.asset.localIdentifier] + 1)];
        _indexLabel.text = index;
        _indexLabel.hidden = NO;
    } else {
        _indexLabel.hidden = YES;
    }
    _numberLabel.text = [NSString stringWithFormat:@"%zd",_hgImagePickerVc.selectedModels.count];
    _numberImageView.hidden = (_hgImagePickerVc.selectedModels.count <= 0 || _isHideNaviBar || _isCropImage);
    _numberLabel.hidden = (_hgImagePickerVc.selectedModels.count <= 0 || _isHideNaviBar || _isCropImage);
    
    _originalPhotoButton.selected = _isSelectOriginalPhoto;
    _originalPhotoLabel.hidden = !_originalPhotoButton.isSelected;
    if (_isSelectOriginalPhoto) [self showPhotoBytes];
    
    // If is previewing video, hide original photo button
    // 如果正在预览的是视频，隐藏原图按钮
    if (!_isHideNaviBar) {
        if (model.type == HGAssetModelMediaTypeVideo) {
            _originalPhotoButton.hidden = YES;
            _originalPhotoLabel.hidden = YES;
        } else {
            _originalPhotoButton.hidden = NO;
            if (_isSelectOriginalPhoto)  _originalPhotoLabel.hidden = NO;
        }
    }
    
    _doneButton.hidden = NO;
    _selectButton.hidden = !_hgImagePickerVc.showSelectBtn;
    // 让宽度/高度小于 最小可选照片尺寸 的图片不能选中
    if (![[HGImageManager manager] isPhotoSelectableWithAsset:model.asset]) {
        _numberLabel.hidden = YES;
        _numberImageView.hidden = YES;
        _selectButton.hidden = YES;
        _originalPhotoButton.hidden = YES;
        _originalPhotoLabel.hidden = YES;
        _doneButton.hidden = YES;
    }
    
    if (_hgImagePickerVc.photoPreviewPageDidRefreshStateBlock) {
        _hgImagePickerVc.photoPreviewPageDidRefreshStateBlock(_collectionView, _naviBar, _backButton, _selectButton, _indexLabel, _toolBar, _originalPhotoButton, _originalPhotoLabel, _doneButton, _numberImageView, _numberLabel);
    }
}

- (void)refreshSelectButtonImageViewContentMode {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self->_selectButton.imageView.image.size.width <= 27) {
            self->_selectButton.imageView.contentMode = UIViewContentModeCenter;
        } else {
            self->_selectButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        }
    });
}

- (void)showPhotoBytes {
    [[HGImageManager manager] getPhotosBytesWithArray:@[_models[self.currentIndex]] completion:^(NSString *totalBytes) {
        self->_originalPhotoLabel.text = [NSString stringWithFormat:@"(%@)",totalBytes];
    }];
}

- (NSInteger)currentIndex {
    return [HGCommonTools hg_isRightToLeftLayout] ? self.models.count - _currentIndex - 1 : _currentIndex;
}

@end
