//
//  FLSImageViewController.m
//  RealStar
//
//  Created by EBogomolov on 23.11.15.
//  Copyright © 2015 Vitalii Roditieliev. All rights reserved.
//

#import "FLSItemViewController.h"
#import "FLSImagePickerController.h"
#import "FLSAssetsTableViewCell.h"

#import <Photos/Photos.h>

NSString *  const FLSAssetsCellId   = @"FLSAssetsCellId";

@interface FLSItemViewController () <PHPhotoLibraryChangeObserver, FLSAssetsTableViewCellDelegate>

@property (nonatomic, assign) NSInteger columns;
@property (nonatomic, strong) NSMutableArray * assets;
@property (nonatomic, assign) BOOL singleSelection;

@property (nonatomic, weak) NSMutableSet * selectedAssets;

@end

@implementation FLSItemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    FLSImagePickerController *controller = (FLSImagePickerController*)self.navigationController;
    _selectedAssets = (NSMutableSet*)controller.selectedAssets;
    
    self.columns = 4;
    _singleSelection = [controller singleSelection];

    UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
    [self.navigationItem setRightBarButtonItem:doneButtonItem];
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView setAllowsSelection:NO];
    
    self.assets = [NSMutableArray new];
    
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    [self.tableView registerClass:[FLSAssetsTableViewCell class] forCellReuseIdentifier:FLSAssetsCellId];
    
    [self performSelectorInBackground:@selector(preparePhotos) withObject:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions
- (void) doneAction:(id)sender {
    [(FLSImagePickerController*)self.navigationController completeSelectImage];
}

#pragma mark - Base
- (void)preparePhotos
{
    [self.assets removeAllObjects];
    PHFetchResult *tempFetchResult = (PHFetchResult *)self.assetGroup;
    for (int k =0; k < tempFetchResult.count; k++) {
        
        PHAsset *asset = tempFetchResult[k];
        [self.assets addObject:asset];
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        // scroll to bottom
        long section = [self numberOfSectionsInTableView:self.tableView] - 1;
        long row = [self tableView:self.tableView numberOfRowsInSection:section] - 1;
        if (section >= 0 && row >= 0) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:row
                                                 inSection:section];
            [self.tableView scrollToRowAtIndexPath:ip
                                  atScrollPosition:UITableViewScrollPositionBottom
                                          animated:NO];
        }
        
        [self.navigationItem setTitle:self.singleSelection ? NSLocalizedString(@"Pick Photo", nil) : NSLocalizedString(@"Pick Photos", nil)];
    });

}
#pragma mark - Cell Delegate
- (void)flsAssetTableViewCellDidSelect:(id)asset {
    [_selectedAssets addObject:asset];
}

-(void)flsAssetTableViewCellDidDeselect:(id)asset {
    [_selectedAssets removeObject:asset];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    self.columns = _columns > 0 ? _columns : 4;
    NSInteger numRows = ceil([self.assets count] / (float)self.columns);
    return numRows;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return (self.view.bounds.size.width-FLSCellPadding*(_columns-1))/_columns;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FLSAssetsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FLSAssetsCellId forIndexPath:indexPath];
    cell.delegate = self;
    
    NSArray *assets = [self assetsForIndexPath:indexPath];
    NSInteger selectedMask = 0;
    for (int i=0; i < assets.count; i++) {
        BOOL selected = [_selectedAssets containsObject:assets[i]];
        if (selected) {
            selectedMask |= 1<<i;
        }
    }
    cell.selectedMask = selectedMask;
    cell.maxCount   = _columns;
    [cell setAssets:assets];
    
//    NSLog(@"Cell mask %ld", selectedMask);
    return cell;
}

#pragma mark - Helpers
- (NSArray *)assetsForIndexPath:(NSIndexPath *)path
{
    long countItems = _assets.count;
    long index = path.row * self.columns;
    if (countItems > index) {
        long length = MIN(self.columns, countItems - index);
        return [self.assets subarrayWithRange:NSMakeRange(index, length)];
    }
    return @[];
}


#pragma mark - Photo Library Observer

-(void)photoLibraryDidChange:(PHChange *)changeInstance {
    PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:(PHFetchResult*)self.assetGroup];
    
    if(changeDetails) {
        self.assetGroup = [changeDetails fetchResultAfterChanges];
        [self preparePhotos];
    }
}

@end
