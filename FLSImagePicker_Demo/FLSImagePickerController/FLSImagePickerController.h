//
//  FLSImagePicker.h
//  RealStar
//
//  Created by EBogomolov on 23.11.15.
//  Copyright © 2015 Vitalii Roditieliev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FLSImagePickerController : UINavigationController

@property (nonatomic, assign) NSInteger maximumImagesCount;
@property (nonatomic, assign) BOOL onOrder;
/**
 * An array indicating the media types to be accessed by the media picker controller.
 * Same usage as for UIImagePickerController.
 */
@property (nonatomic, copy)     NSArray *mediaTypes;
@property (nonatomic, assign)   BOOL singleSelection;

@property (nonatomic, readonly) NSSet *selectedAssets;
@property (nonatomic, copy) void (^completionHandler) (NSArray *assets);

- (void) closeImagePicker;
- (void) completeSelectImage;

@end
