//
//  UICollectionViewCell+HBFlowLayoutMoving.m
//  AiYaoLe
//
//  Created by sks on 2017/7/5.
//  Copyright © 2017年 sks. All rights reserved.
//

#import "UICollectionViewCell+HBFlowLayoutMoving.h"

@implementation UICollectionViewCell (HBFlowLayoutMoving)

- (UIView *)snapshotView {

    UIView *snapshotView = [UIView new];
    UIView *cellSnapshotViwe = nil;
    
    if ([self respondsToSelector:@selector(snapshotViewAfterScreenUpdates:)]) {
        cellSnapshotViwe = [self snapshotViewAfterScreenUpdates:NO];
    }else{
        CGSize size = self.frame.size;
        UIGraphicsBeginImageContextWithOptions(size, self.opaque, 0);
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *cellshotImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        cellSnapshotViwe = [[UIImageView alloc] initWithImage:cellshotImage];
    }
    snapshotView.frame = CGRectMake(0, 0, cellSnapshotViwe.frame.size.width, cellSnapshotViwe.frame.size.height);
    cellSnapshotViwe.frame = CGRectMake(0, 0, cellSnapshotViwe.frame.size.width, cellSnapshotViwe.frame.size.height);
    [snapshotView addSubview:cellSnapshotViwe];

    snapshotView.layer.shadowOffset = CGSizeMake(-5.0f, 0);
    snapshotView.layer.shadowRadius = 5.f;
    snapshotView.layer.shadowOpacity = 0.4f;
    
    return snapshotView;
}


@end
