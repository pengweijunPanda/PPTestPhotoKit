//
//  ViewController.m
//  HGImagePickerController
//
//  Created by pengweijun on 2019/6/18.
//  Copyright © 2019年 彭伟军. All rights reserved.
//

#import "ViewController.h"
#import "HGImagePickerController.h"
#import "HGImageManager.h"

@interface ViewController ()<HGImagePickerControllerDelegate>
- (IBAction)album:(id)sender;
- (IBAction)camera:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (IBAction)album:(id)sender { 
}

- (IBAction)camera:(id)sender {
    HGImagePickerController *imagePickerVc = [[HGImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
    
    // You can get the photos by block, the same as by delegate.
    // 你可以通过block或者代理，来得到用户选择的照片.
    [imagePickerVc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
        
    }];
    [self presentViewController:imagePickerVc animated:YES completion:nil];
}
@end
