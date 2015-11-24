//
//  ViewController.m
//  FLSImagePicker_Demo
//
//  Created by EBogomolov on 24.11.15.
//  Copyright © 2015 EBogomolov. All rights reserved.
//

#import "ViewController.h"

#import "FLSImagePickerController.h"

#import <Photos/Photos.h>

@interface ViewController ()

@end

@implementation ViewController

- (IBAction)showImagePicker:(id)sender {
    FLSImagePickerController *imagePicker = [FLSImagePickerController new];
    [self presentViewController:imagePicker animated:YES completion:nil];
        
    imagePicker.completionHandler = ^(NSArray *selectedAssets) {
        __block NSInteger count = selectedAssets.count;
        if (count == 0) return;
        
        PHImageRequestOptions * options = [[PHImageRequestOptions alloc] init];
        options.networkAccessAllowed    = YES;
        options.deliveryMode            = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.resizeMode              = PHImageRequestOptionsResizeModeFast;
        options.version                 = PHImageRequestOptionsVersionCurrent;
        
        for (PHAsset * asset in selectedAssets) {
            
            if ([asset isKindOfClass:[PHAsset class]]) {
                
                CGFloat scale = 400.0 / asset.pixelHeight;
                CGFloat newWidth = floorf(asset.pixelWidth * scale);
                CGSize size = CGSizeMake(newWidth, 400.0);
                
                [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                    NSLog(@"IMAGE %@", result);
                }];
            }
        }
    };
}

@end
