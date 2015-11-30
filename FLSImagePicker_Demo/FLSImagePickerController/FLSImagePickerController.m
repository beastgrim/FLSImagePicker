//
//  FLSImagePicker.m
//  RealStar
//
//  Created by EBogomolov on 23.11.15.
//  Copyright © 2015 Vitalii Roditieliev. All rights reserved.
//

#import "FLSImagePickerController.h"
#import "FLSAlbumViewController.h"

@interface FLSImagePickerController ()

@end

@implementation FLSImagePickerController

- (instancetype)init
{
    FLSAlbumViewController *rootController = [[FLSAlbumViewController alloc] initWithStyle:UITableViewStylePlain];
    self = [self initWithRootViewController:rootController];
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        _selectedAssets = [NSMutableSet new];
        if ([rootViewController isKindOfClass:[FLSAlbumViewController class]]) {
            [(FLSAlbumViewController*)rootViewController setMediaTypes:_mediaTypes];
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Setters
- (void)setMediaTypes:(NSArray *)mediaTypes {
    [(FLSAlbumViewController*)self.viewControllers[0] setMediaTypes:mediaTypes];
}

#pragma mark - Public
- (void)closeImagePicker {
    [(NSMutableSet*)_selectedAssets removeAllObjects];
    if (_completionHandler)     _completionHandler(_selectedAssets.allObjects);

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)completeSelectImage {
    if (_completionHandler)     _completionHandler(_selectedAssets.allObjects);
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
