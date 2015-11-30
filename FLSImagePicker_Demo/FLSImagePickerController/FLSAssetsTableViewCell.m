//
//  FLSAssetsTableViewCell.m
//  RealStar
//
//  Created by EBogomolov on 23.11.15.
//  Copyright © 2015 Vitalii Roditieliev. All rights reserved.
//

#import "FLSAssetsTableViewCell.h"

#import <Photos/Photos.h>

CGFloat     const FLSCellPadding           = 1.0;

@interface FLSAssetsTableViewCell ()

@property (nonatomic, strong) NSMutableArray * images;
@property (nonatomic) CGFloat sizeWith;

@end

@implementation FLSAssetsTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _sizeWith   = 78; // default
        _images     = [NSMutableArray new];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTaped:)];
        [self.contentView addGestureRecognizer:tap];
    }
    return self;
}

- (void)awakeFromNib {
    _images = [NSMutableArray new];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTaped:)];
    [self.contentView addGestureRecognizer:tap];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

#pragma mark - Setters
- (void)setMaxCount:(NSInteger)maxCount {
    if (_maxCount != maxCount) {
        _maxCount = maxCount;
        
        [_images removeAllObjects];
        for (int i = 0; i < maxCount; i++) {
            [_images addObject:[self templateImage]];
        }
        [self setNeedsDisplay];
    }
}

- (void)setAssets:(NSArray *)assets {
    _assets = assets;
    [self setNeedsDisplay];
    
    NSInteger currentTag = ++self.tag;
    
    //set up a pointer here so we don't keep calling [UIImage imageNamed:] if creating overlays
    PHImageManager *imageManager = [PHCachingImageManager defaultManager];
    CGFloat scale = [UIScreen mainScreen].scale;
    
    static PHImageRequestOptions *options;
    if (options == nil) {
        options  = [[PHImageRequestOptions alloc] init];
        options.networkAccessAllowed    = YES;
        options.resizeMode              = PHImageRequestOptionsResizeModeExact;
        options.synchronous             = YES;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        for (int i = 0; i < assets.count; i++) {
            
            PHAsset *asset = [assets objectAtIndex:i];
            
            
            [imageManager requestImageForAsset:asset targetSize:CGSizeMake(_sizeWith*scale, _sizeWith*scale) contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * result, NSDictionary * info) {
                if (currentTag != self.tag) return;

                    CGFloat minSize     = MIN(result.size.width*scale, result.size.height*scale);
                    CGRect cropRect     = CGRectMake(0, 0, minSize, minSize);
                    cropRect.origin.x   = (result.size.width*scale - minSize)/2;
                    cropRect.origin.y   = (result.size.height*scale - minSize)/2;
                    
                    CGImageRef imageRef = CGImageCreateWithImageInRect([result CGImage], cropRect);
                    UIImage * cropImage = [UIImage imageWithCGImage:imageRef];
                    CGImageRelease(imageRef);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (currentTag == self.tag) {
                        [_images replaceObjectAtIndex:i withObject:cropImage];
                        [self drawImageAtIndex:i];
                    }
                });
            }];
        }
    });
    
}

#pragma mark - Actions
- (void) didTaped:(UITapGestureRecognizer*)recognizer {
    
    const CGFloat width = recognizer.view.bounds.size.width/_maxCount;
    CGPoint touchLocation = [recognizer locationInView:self.contentView];
    int index = touchLocation.x/width;
    
    if (_assets.count > index) {
        if (_selectedMask & 1<<index) {
            _selectedMask ^= 1 << index;
            if ([_delegate respondsToSelector:@selector(flsAssetTableViewCellDidDeselect:)])
                [_delegate flsAssetTableViewCellDidDeselect:_assets[index]];
        } else {
            _selectedMask |= 1 << index;
            if ([_delegate respondsToSelector:@selector(flsAssetTableViewCellDidSelect:)])
                [_delegate flsAssetTableViewCellDidSelect:_assets[index]];
        }
        [self drawImageAtIndex:index];
    }
}

#pragma mark - Draw
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor whiteColor] set];
    CGContextFillRect(context, rect);
    
    for (int i = 0; i < _assets.count; i++) {
        CGRect imageRect = CGRectMake((_sizeWith+FLSCellPadding)*i, FLSCellPadding, _sizeWith, _sizeWith);
        if (!CGRectContainsPoint(rect, imageRect.origin)) {
//            NSLog(@"CANCEL DRAW RECT %@ in %@", NSStringFromCGRect(imageRect), NSStringFromCGRect(rect));
            continue;
        }

        UIImage *image = [_images objectAtIndex:i];
        [image drawInRect:imageRect];
        
        CGRect checkRect = CGRectInset(imageRect, _sizeWith/3, _sizeWith/3);
        checkRect = CGRectOffset(checkRect, _sizeWith/3, _sizeWith/3);
        
        BOOL selected = _selectedMask & 1<<i ;
        if (selected) {
            [[UIColor colorWithWhite:1 alpha:0.3] set];
            CGContextFillRect(context, imageRect);
        }
        [self drawCheckedRect:checkRect selected:selected];
        
        PHAsset *asset = _assets[i];
        if (asset.mediaType == PHAssetMediaTypeVideo) {
            CGFloat height = imageRect.size.height/5.5;
            CGRect videoRect = imageRect;
            videoRect.size.height = height;
            [self drawVideoInfoRect:videoRect duration:asset.duration];
        }
    }
}

- (void) drawVideoInfoRect:(CGRect)rect duration:(NSTimeInterval)duration {

    [[UIColor whiteColor] set];
    CGRect elipseRect = CGRectMake(rect.origin.x + 4, rect.origin.y + 4, (rect.size.height-8), rect.size.height-8);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:elipseRect cornerRadius:elipseRect.size.width/6];
    [path fill];
    
    NSString *info = [NSString stringWithFormat:@"%d:%02d", (int)(duration/60), (int)duration%60];
    NSDictionary *attr;
    if (!attr) {
        attr = @{NSFontAttributeName:[UIFont systemFontOfSize:rect.size.height-8], NSForegroundColorAttributeName: [UIColor whiteColor]};
    }
    CGSize infoSize = [info sizeWithAttributes:attr];
    [info drawAtPoint:CGPointMake(rect.origin.x + rect.size.width-infoSize.width-4, (rect.size.height-infoSize.height)/2) withAttributes:attr];
    
    path = [UIBezierPath bezierPath];
    [path moveToPoint: CGPointMake(rect.origin.x + elipseRect.size.width + 4, CGRectGetMidY(rect))];
    [path addLineToPoint: CGPointMake(rect.origin.x + elipseRect.size.width + elipseRect.size.width/2 + 4, rect.origin.y+4)];
    [path addLineToPoint: CGPointMake(rect.origin.x + elipseRect.size.width + elipseRect.size.width/2 + 4, CGRectGetMaxY(rect)-4)];
    [path closePath];
    path.lineCapStyle = kCGLineCapRound;
    path.lineWidth = 1;
    [path fill];
}

- (void) drawCheckedRect:(CGRect)rect selected:(BOOL)selected
{
    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* checkmarkBlue2 = [UIColor colorWithRed: 0.078 green: 0.435 blue: 0.875 alpha: 1];
    
    //// Shadow Declarations
    UIColor* shadow2 = [UIColor blackColor];
    CGSize shadow2Offset = CGSizeMake(0.1, -0.1);
    CGFloat shadow2BlurRadius = 2.5;
    
    //// Frames
    CGRect frame = rect;
    
    //// Subframes
    CGRect group = CGRectMake(CGRectGetMinX(frame) + 3, CGRectGetMinY(frame) + 3, CGRectGetWidth(frame) - 6, CGRectGetHeight(frame) - 6);
    
    
    //// Group
    {
        //// CheckedOval Drawing
        UIBezierPath* checkedOvalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(CGRectGetMinX(group) + floor(CGRectGetWidth(group) * 0.00000 + 0.5), CGRectGetMinY(group) + floor(CGRectGetHeight(group) * 0.00000 + 0.5), floor(CGRectGetWidth(group) * 1.00000 + 0.5) - floor(CGRectGetWidth(group) * 0.00000 + 0.5), floor(CGRectGetHeight(group) * 1.00000 + 0.5) - floor(CGRectGetHeight(group) * 0.00000 + 0.5))];
        CGContextSaveGState(context);
        CGContextSetShadowWithColor(context, shadow2Offset, shadow2BlurRadius, shadow2.CGColor);
        if (selected) {
            [checkmarkBlue2 setFill];
        } else
            [[UIColor clearColor] setFill];
        [checkedOvalPath fill];
        CGContextRestoreGState(context);
        
        [[UIColor whiteColor] setStroke];
        checkedOvalPath.lineWidth = 1;
        [checkedOvalPath stroke];
        
        if (selected) {
            //// Bezier Drawing
            UIBezierPath* bezierPath = [UIBezierPath bezierPath];
            [bezierPath moveToPoint: CGPointMake(CGRectGetMinX(group) + 0.27083 * CGRectGetWidth(group), CGRectGetMinY(group) + 0.54167 * CGRectGetHeight(group))];
            [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(group) + 0.41667 * CGRectGetWidth(group), CGRectGetMinY(group) + 0.68750 * CGRectGetHeight(group))];
            [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(group) + 0.75000 * CGRectGetWidth(group), CGRectGetMinY(group) + 0.35417 * CGRectGetHeight(group))];
            bezierPath.lineCapStyle = kCGLineCapSquare;
            
            [[UIColor whiteColor] setStroke];
            bezierPath.lineWidth = 1.3;
            [bezierPath stroke];
        }
    }
}

- (void)layoutSubviews
{
    _sizeWith = MIN(self.bounds.size.height, (self.bounds.size.width-(_maxCount-1)*FLSCellPadding)/_maxCount);
    [self setNeedsDisplay];
}

#pragma mark - Helpers

- (void) drawImageAtIndex:(NSInteger)index {
    if (index > _maxCount) return;
    
    const CGFloat height = self.bounds.size.width/_maxCount;
    CGRect indexRect = CGRectMake(height*index, 0, height, height);

    [self setNeedsDisplayInRect:indexRect];
}

- (UIImage *)templateImage {
    
    static UIImage *image;
    if (image) {
        return image;
    }
    
    CGRect imageRect = CGRectMake(0, 0, _sizeWith, _sizeWith);
    
    UIGraphicsBeginImageContextWithOptions(imageRect.size, YES, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();

    [[UIColor whiteColor] set];
    CGContextFillRect(context, imageRect);
    
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
