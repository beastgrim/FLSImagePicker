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
CGFloat     const FLSAlbumCellHeight   = 70.0;



@interface FLSAlbumViewController () <PHPhotoLibraryChangeObserver>

@property (strong) PHImageManager *imageManager;

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

    [self loadAlbums:nil];
    
    [self fetchData];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:FLSAlbumCellId];
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSIndexPath *selectedRow = [self.tableView indexPathForSelectedRow];
    if (selectedRow) [self.tableView deselectRowAtIndexPath:selectedRow animated:animated];
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

#pragma mark Table delegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FLSAlbumCellId forIndexPath:indexPath];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    NSInteger currentTag =  ++cell.tag;
    
    NSDictionary *currentFetchResultRecord = [self.assetGroups objectAtIndex:indexPath.row];
    if ([currentFetchResultRecord isKindOfClass:[ALAssetsGroup class]]) {
        [(ALAssetsGroup*)currentFetchResultRecord setAssetsFilter:[self assetFilter]];
    }
    PHFetchResult *assetsFetchResult = [currentFetchResultRecord allValues][0];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %lu", [currentFetchResultRecord allKeys][0],(unsigned long)assetsFetchResult.count];
    
    if ([assetsFetchResult count] > 0) {
        CGFloat scale = [UIScreen mainScreen].scale;
        
        //Compute the thumbnail pixel size:
        CGSize tableCellThumbnailSize = CGSizeMake(FLSAlbumCellHeight*scale, FLSAlbumCellHeight*scale);
        PHAsset *asset = assetsFetchResult[0];
        
        PHImageRequestOptions *options = [PHImageRequestOptions new];
        // Download from cloud if necessary
        options.networkAccessAllowed    = YES;
        
        [self.imageManager requestImageForAsset:asset
                                     targetSize:tableCellThumbnailSize
                                    contentMode:PHImageContentModeAspectFill
                                        options:options
                                  resultHandler:^(UIImage *result, NSDictionary *info)
         {
             
             CGFloat minSize     = MIN(result.size.width*scale, result.size.height*scale);
             CGRect cropRect     = CGRectMake(0, 0, minSize, minSize);
             cropRect.origin.x   = (result.size.width*scale - minSize)/2;
             cropRect.origin.y   = (result.size.height*scale - minSize)/2;
             
             
             CGImageRef imageRef = CGImageCreateWithImageInRect([result CGImage], cropRect);
             UIImage * cropImage = [UIImage imageWithCGImage:imageRef];
             CGImageRelease(imageRef);
             
             if(cell.tag == currentTag) {
                 cell.imageView.image = cropImage;
             }
         }];

        
    } else {
        cell.imageView.image = nil;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FLSItemViewController *picker = [FLSItemViewController new];
    picker.assetGroup = [[self.assetGroups objectAtIndex:indexPath.row] allValues][0];
    
    [self.navigationController pushViewController:picker animated:YES];
}

@end
