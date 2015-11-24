//
//  FLSAssetsTableViewCell.h
//  RealStar
//
//  Created by EBogomolov on 23.11.15.
//  Copyright © 2015 Vitalii Roditieliev. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FLSAssetsTableViewCellDelegate <NSObject>

@optional
- (void) flsAssetTableViewCellDidSelect:(id)asset;
- (void) flsAssetTableViewCellDidDeselect:(id)asset;

@end

extern CGFloat     const FLSCellPadding;

@interface FLSAssetsTableViewCell : UITableViewCell

@property (nonatomic, weak)     id<FLSAssetsTableViewCellDelegate> delegate;

@property (nonatomic, strong)   NSArray * assets;
@property (nonatomic, assign)   NSInteger maxCount;
@property (nonatomic, assign)   NSInteger selectedMask;

@end
