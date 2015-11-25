//
//  FLSImageViewController.h
//  RealStar
//
//  Created by EBogomolov on 23.11.15.
//  Copyright © 2015 Vitalii Roditieliev. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PHFetchResult;

@interface FLSImageViewController : UITableViewController

@property (nonatomic, strong) PHFetchResult * assetGroup;

@end
