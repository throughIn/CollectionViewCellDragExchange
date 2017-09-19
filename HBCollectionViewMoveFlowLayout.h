//
//  HBCollectionViewMoveFlowLayout.h
//  AiYaoLe
//
//  Created by sks on 2017/7/5.
//  Copyright © 2017年 sks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HBCollectionViewMoveFlowLayout : UICollectionViewFlowLayout


@property(nonatomic, assign, getter=isPanGestureRecognizerEnable) BOOL panGestureRecognizerEnable;

@end

@protocol HBCollectionViewMoveDataSource <UICollectionViewDataSource>

@optional

- (BOOL)collectionView:(UICollectionView *)collectionView
canMoveItemAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)collectionView:(UICollectionView *)collectionView
       itemAtIndexpath:(NSIndexPath *)sourceIndexPath
    canMoveToIndexPath:(NSIndexPath *)destinationIndexPath;

- (void)collectionView:(UICollectionView *)collectionView
       itemAtIndexPath:(NSIndexPath *)sourceIndexPath
   willMoveToIndexPath:(NSIndexPath *)destinationIndexPath;

- (void)collectionView:(UICollectionView *)collectionView
       itemAtIndexPath:(NSIndexPath *)sourceIndexPath
   didMoveToIndexPath:(NSIndexPath *)destinationIndexPath;

@end

@protocol HBCollectionViewDelegateMoveFlowLayout <UICollectionViewDelegateFlowLayout>

@optional

- (void)collectionView:(UICollectionView *)collectionView
                layout:(UICollectionViewLayout *)collectionViewLayout
willBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)collectionView:(UICollectionView *)collectionView
                layout:(UICollectionViewLayout *)collectionViewLayout
didBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)collectionView:(UICollectionView *)collectionView
                layout:(UICollectionViewLayout *)collectionViewLayout
willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)collectionView:(UICollectionView *)collectionView
                layout:(UICollectionViewLayout *)collectionViewLayout
didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath;


@end










