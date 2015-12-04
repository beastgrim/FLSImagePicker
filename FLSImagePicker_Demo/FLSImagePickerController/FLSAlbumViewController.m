//
//  FLSAlbumViewController.m
//  RealStar
//
//  Created by EBogomolov on 23.11.15.
//  Copyright © 2015 Vitalii Roditieliev. All rights reserved.
//

#import "FLSAlbumViewController.h"
#import "FLSImagePickerController.h"
#import "FLSItemViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <Photos/Photos.h>


NSString *  const FLSAlbumCellId    = @"FLSAlbumCellId";
CGFloat     const FLSAlbumCellHeight   = 80.0;



@interface FLSAlbumViewController () <PHPhotoLibraryChangeObserver>

@property (strong, nonatomic) PHImageManager    * imageManager;
@property (strong, nonatomic) UIImage           * placeholderImage;

@end

@implementation FLSAlbumViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];

    [self.navigationItem setTitle:NSLocalizedString(@"Loading...", nil)];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:(FLSImagePickerController*)self.navigationController action:@selector(closeImagePicker)];
    [self.navigationItem setRightBarButtonItem:cancelButton];
    
    if (!_mediaTypes.count) {
        _mediaTypes = @[@(PHAssetMediaTypeVideo), @(PHAssetMediaTypeImage)];
    }
    
    self.assetGroups            = [NSMutableArray new];
    self.imageManager           = [PHImageManager defaultManager];
    
//    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:FLSAlbumCellId];
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];


    [self loadAlbums:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSIndexPath *selectedRow = [self.tableView indexPathForSelectedRow];
    if (selectedRow) [self.tableView deselectRowAtIndexPath:selectedRow animated:animated];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Getters
- (ALAssetsFilter *)assetFilter
{
    if([self.mediaTypes containsObject:(NSString *)kUTTypeImage] && [self.mediaTypes containsObject:(NSString *)kUTTypeMovie])
    {
        return [ALAssetsFilter allAssets];
    }
    else if([self.mediaTypes containsObject:(NSString *)kUTTypeMovie])
    {
        return [ALAssetsFilter allVideos];
    }
    else
    {
        return [ALAssetsFilter allPhotos];
    }
}

#pragma mark - Base
- (void) loadAlbums:(void(^)(void))completion {
    
    [self fetchData];
    if (completion) completion();
}

- (void) fetchData {
    [self.assetGroups removeAllObjects];
    
    //Fetch PHAssetCollections:
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType in %@", _mediaTypes];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsWithOptions:options];
    
    [self.assetGroups addObject:@{@"All Photos":assetsFetchResult}];
    
    
    PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    
    for (PHCollection *collection in topLevelUserCollections)
    {
        if ([collection isKindOfClass:[PHAssetCollection class]])
        {
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType in %@", _mediaTypes];
            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
            
            //Albums collections are allways PHAssetCollectionType=1 & PHAssetCollectionSubtype=2
            
            PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
            [self.assetGroups addObject:@{collection.localizedTitle : assetsFetchResult}];
            
        }
    }
    
    [self.tableView reloadData];
    [self.navigationItem setTitle:NSLocalizedString(@"Select an Album", nil)];
}

#pragma mark - Library did change
- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    // Call might come on any background queue. Re-dispatch to the main queue to handle it.
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSMutableArray *updatedCollectionsFetchResults = nil;
        
        for (NSDictionary *fetchResultDictionary in self.assetGroups) {
            PHFetchResult *collectionsFetchResult = [fetchResultDictionary allValues][0];
            PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:collectionsFetchResult];
            if (changeDetails) {
                
                if (!updatedCollectionsFetchResults) {
                    updatedCollectionsFetchResults = [self.assetGroups mutableCopy];
                }
                
                [updatedCollectionsFetchResults replaceObjectAtIndex:[self.assetGroups indexOfObject:fetchResultDictionary] withObject:@{[fetchResultDictionary allKeys][0] :[changeDetails fetchResultAfterChanges]}];
            }
        }
        
        if (updatedCollectionsFetchResults) {
            self.assetGroups = updatedCollectionsFetchResults;
            [self.tableView reloadData];
        }
        
    });
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _assetGroups.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return FLSAlbumCellHeight;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {

}

#pragma mark Table delegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell       = [tableView dequeueReusableCellWithIdentifier:FLSAlbumCellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:FLSAlbumCellId];
    }
    cell.accessoryType          = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.contentMode  = UIViewContentModeScaleAspectFit;
    cell.imageView.image        = _placeholderImage;
    
    NSInteger currentTag =  ++cell.tag;
    
    NSDictionary *currentFetchResultRecord = [self.assetGroups objectAtIndex:indexPath.row];
    if ([currentFetchResultRecord isKindOfClass:[ALAssetsGroup class]]) {
        [(ALAssetsGroup*)currentFetchResultRecord setAssetsFilter:[self assetFilter]];
    }
    PHFetchResult *assetsFetchResult = [currentFetchResultRecord allValues][0];
    cell.textLabel.text = [currentFetchResultRecord allKeys][0];
    cell.detailTextLabel.text = @(assetsFetchResult.count).stringValue;
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize tableCellThumbnailSize = CGSizeMake((FLSAlbumCellHeight-2)*scale, (FLSAlbumCellHeight-2)*scale);
    
    if ([assetsFetchResult count] > 0) {

        [self albumImageFromAlbum:assetsFetchResult withSize:tableCellThumbnailSize completion:^(UIImage *result) {
            if (cell.tag == currentTag) {
                cell.imageView.image = result;
//                NSLog(@"Cell rect %@ image %@ scale %f", NSStringFromCGRect(cell.bounds), NSStringFromCGSize(result.size), result.scale);
                [cell layoutSubviews];
            }
        }];
        
    } else {
        [self placeholderImageWithSize:tableCellThumbnailSize completion:^(UIImage *result) {
            cell.imageView.image = result;
            [cell layoutSubviews];
        }];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FLSItemViewController *picker = [FLSItemViewController new];
    picker.assetGroup = [[self.assetGroups objectAtIndex:indexPath.row] allValues][0];
    
    [self.navigationController pushViewController:picker animated:YES];
}


#pragma mark - Draw
- (void) placeholderImageWithSize:(CGSize)size completion:(void(^)(UIImage * result))completion {
    if (_placeholderImage) {
        if (completion) completion(_placeholderImage);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
        UIGraphicsBeginImageContextWithOptions(size, YES, 1.0);
        CGContextRef context = UIGraphicsGetCurrentContext();

        [[UIColor whiteColor] set];
        CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
        
        // draw place holder
        [[UIColor groupTableViewBackgroundColor] set];
        const CGRect mainRect = CGRectInset(CGRectMake(0, 0, size.width, size.height), size.width/7, size.height/4);
        UIBezierPath *path  = [UIBezierPath bezierPathWithRoundedRect:mainRect cornerRadius:size.width/20];
        path.lineWidth      = 4;
        [path stroke];
        
        CGFloat padding     = mainRect.size.height/8;
        CGRect circleRect   = CGRectOffset(mainRect, padding, padding);
        circleRect.size     = CGSizeMake(mainRect.size.width/4, mainRect.size.width/4);
        CGContextFillEllipseInRect(context, circleRect);
        
        path                = [UIBezierPath bezierPath];
        path.lineWidth      = 2;
        [path moveToPoint:CGPointMake(mainRect.origin.x + padding, CGRectGetMaxY(mainRect) - padding)];
        [path addLineToPoint:CGPointMake(mainRect.origin.x + padding, CGRectGetMaxY(mainRect) - padding*2)];
        [path addLineToPoint:CGPointMake(CGRectGetMaxX(circleRect) - padding/1.5, CGRectGetMaxY(circleRect) + padding*1)];
        [path addLineToPoint:CGPointMake(CGRectGetMaxX(circleRect) + padding/2, CGRectGetMaxY(mainRect) - padding*2.5)];
        [path addLineToPoint:CGPointMake(CGRectGetMaxX(circleRect)*1.6, mainRect.origin.y + padding*2)];
        [path addLineToPoint:CGPointMake(CGRectGetMaxX(mainRect) - padding, CGRectGetMaxY(circleRect) + padding*1.5)];
        [path addLineToPoint:CGPointMake(CGRectGetMaxX(mainRect) - padding, CGRectGetMaxY(mainRect) - padding)];
        [path closePath];
        [path fill];
        
        UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _placeholderImage   = result;
            if (completion) completion(_placeholderImage);
        });
    });
}

- (void) albumImageFromAlbum:(PHFetchResult*)album withSize:(CGSize)size completion:(void(^)(UIImage * result))completion {
    

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
//        NSLog(@"Create placeholder image %@", NSStringFromCGSize(size));

        UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        [[UIColor clearColor] set];
        CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
        
        const CGFloat padding   = 6.0;
        const CGRect mainRect = CGRectMake(padding, padding, size.width-padding*2, size.height-padding*2);
        
        PHImageRequestOptions *options  = [PHImageRequestOptions new];
        options.deliveryMode            = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.resizeMode              = PHImageRequestOptionsResizeModeExact;
        options.networkAccessAllowed    = YES;
        options.synchronous             = YES;
        
        const int totalCount    = MIN((int)album.count, 3);
        int count               = totalCount;
        
        for (PHAsset *asset in album) {
            
            CGRect current = CGRectInset(mainRect, padding*count, padding*count);
            current.origin = CGPointMake((count+1)*padding, (totalCount-count+1)*padding);
            
            [self.imageManager requestImageForAsset:asset
                                         targetSize:current.size
                                        contentMode:PHImageContentModeAspectFill
                                            options:options
                                      resultHandler:^(UIImage *result, NSDictionary *info)
             {
                 
                 CGFloat minSize     = MIN(result.size.width, result.size.height);
                 CGRect cropRect     = CGRectMake(0, 0, minSize, minSize);
                 cropRect.origin.x   = (result.size.width - minSize)/2;
                 cropRect.origin.y   = (result.size.height - minSize)/2;
                 
                 CGImageRef imageRef = CGImageCreateWithImageInRect([result CGImage], cropRect);
                 UIImage * cropImage = [UIImage imageWithCGImage:imageRef];
                 CGImageRelease(imageRef);
                 
//                 NSLog(@"Draw image %@", NSStringFromCGRect(current));
                 [cropImage drawAtPoint:current.origin];
             }];
            
            count--;
            if (count == 0)  break;
        }
        
        UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(result);
        });

    });

}

@end
