//
//  HGAlbumListVC.m
//  HGImagePickerController
//
//  Created by pengweijun on 2019/6/18.
//  Copyright © 2019年 彭伟军. All rights reserved.
//

#import "HGAlbumListVC.h"
#import "HGAssetModel.h"

@interface HGAlbumListVC ()

@end

@implementation HGAlbumListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.model.name;
    self.view.backgroundColor = [UIColor cyanColor];
    // Do any additional setup after loading the view.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
