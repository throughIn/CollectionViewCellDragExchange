//
//  HBCollectionViewMoveFlowLayout.m
//  AiYaoLe
//
//  Created by sks on 2017/7/5.
//  Copyright © 2017年 sks. All rights reserved.
//

#import "HBCollectionViewMoveFlowLayout.h"
#import "UICollectionViewCell+HBFlowLayoutMoving.h"


#define stringify   __STRING

static CGFloat const PRESS_TO_MIN_DURATION = 0.2f;
static CGFloat const MIN_PRESS_TO_BEGIN_EDITING_DURATION = 0.6f;

CG_INLINE CGPoint CGPointOffset(CGPoint point, CGFloat dx, CGFloat dy)
{
    return CGPointMake(point.x + dx, point.y + dy);
}

@interface HBCollectionViewMoveFlowLayout ()<UIGestureRecognizerDelegate>

@property(nonatomic, readonly) id<HBCollectionViewMoveDataSource> dataSource;
@property(nonatomic, readonly) id<HBCollectionViewDelegateMoveFlowLayout> delegate;

@end

@implementation HBCollectionViewMoveFlowLayout
{

    UILongPressGestureRecognizer *_longPressRecognizer;
    UIPanGestureRecognizer *_panRecognizer;
    NSIndexPath *_movingIndexPath;
    UIView *_beingMovingPromptView;
    CGPoint _sourceItemCollectionCellCenter;
    
}

#pragma mark - setup

- (void)dealloc{

    [self removeGestureRecognizers];
    [self removeObserver:self forKeyPath:@stringify(collectionView)];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {

    [self addObserver:self forKeyPath:@stringify(collectionView) options:NSKeyValueObservingOptionNew context:nil];
}

- (void)addGesteureRecognizers {

    self.collectionView.userInteractionEnabled = YES;
    
    _longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognizerTriggerd:)];
    _longPressRecognizer.cancelsTouchesInView = NO;
    _longPressRecognizer.minimumPressDuration = PRESS_TO_MIN_DURATION;
    _longPressRecognizer.delegate = self;
    
    for (UIGestureRecognizer *gesteureRecognizer in self.collectionView.gestureRecognizers) {
        if ([gesteureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            [gesteureRecognizer requireGestureRecognizerToFail:_longPressRecognizer];
        }
    }
    [self.collectionView addGestureRecognizer:_longPressRecognizer];
    
    _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecgnizerTriggerd:)];
    _panRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:_panRecognizer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)removeGestureRecognizers {

    if (_longPressRecognizer) {
        if (_longPressRecognizer.view) {
            [_longPressRecognizer.view removeGestureRecognizer:_longPressRecognizer];
        }
        _longPressRecognizer = nil;
    }
    
    if (_panRecognizer) {
        if (_panRecognizer.view) {
            [_panRecognizer.view removeGestureRecognizer:_panRecognizer];
        }
        _panRecognizer = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

#pragma mark - setter and getter 

- (id<HBCollectionViewMoveDataSource>)dataSource {

    return (id<HBCollectionViewMoveDataSource>)self.collectionView.dataSource;
}

- (id<HBCollectionViewDelegateMoveFlowLayout>)delegate {

    return (id<HBCollectionViewDelegateMoveFlowLayout>)self.collectionView.delegate;
}

#pragma mark - override UICollectionViewLayout method

-(NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray *layoutArrributesForElementsInRect = [super layoutAttributesForElementsInRect:rect];
    for (UICollectionViewLayoutAttributes *layoutAttribute in layoutArrributesForElementsInRect) {
        if (layoutAttribute.representedElementCategory == UICollectionElementCategoryCell) {
            layoutAttribute.hidden = [layoutAttribute.indexPath isEqual:_movingIndexPath];
        }
    }
    return layoutArrributesForElementsInRect;
}

-(UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath{

    UICollectionViewLayoutAttributes *layoutAttributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    if (layoutAttributes.representedElementCategory == UICollectionElementCategoryCell) {
        layoutAttributes.hidden = [layoutAttributes.indexPath isEqual:_movingIndexPath];
    }
    return layoutAttributes;
}

#pragma mark - gestureRecognizer stuff

- (void)setPanGestureRecognizerEnable:(BOOL)panGestureRecognizerEnable {

    _panGestureRecognizerEnable = panGestureRecognizerEnable;
    
    _panRecognizer.enabled = _panGestureRecognizerEnable;
}


- (void)longPressGestureRecognizerTriggerd:(UILongPressGestureRecognizer *)longPress {

    switch (longPress.state) {
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateBegan:{
            _movingIndexPath = [self.collectionView indexPathForItemAtPoint:[longPress locationInView:self.collectionView]];
            // 不能移动
            if ([self.dataSource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:)] && [self.dataSource collectionView:self.collectionView canMoveItemAtIndexPath:_movingIndexPath] == NO) {
                _movingIndexPath = nil;
                return;
            }
            // 开始拖动
            if ([self.delegate respondsToSelector:@selector(collectionView:layout:willBeginDraggingItemAtIndexPath:)]) {
                [self.delegate collectionView:self.collectionView layout:self willBeginDraggingItemAtIndexPath:_movingIndexPath];
            }
            
            UICollectionViewCell *sourceCollectionViewCell = [self.collectionView cellForItemAtIndexPath:_movingIndexPath];
         
            UIView *window = [UIApplication sharedApplication].keyWindow;
            CGRect windowRect = [self.collectionView convertRect:sourceCollectionViewCell.frame toView:window];
            _beingMovingPromptView = [[UIView alloc] initWithFrame:windowRect];
            
            sourceCollectionViewCell.highlighted = YES;
            UIView *highlightedSnapshotView = [sourceCollectionViewCell snapshotView];
            highlightedSnapshotView.frame = _beingMovingPromptView.bounds;
            highlightedSnapshotView.alpha = 1.f;

            sourceCollectionViewCell.highlighted = NO;
            UIView *snapshotView = [sourceCollectionViewCell snapshotView];
            snapshotView.frame = sourceCollectionViewCell.bounds;
            snapshotView.alpha = 0.f;
            
            [_beingMovingPromptView addSubview:snapshotView];
            [_beingMovingPromptView addSubview:highlightedSnapshotView];;
            //加在主窗口上
            [window addSubview:_beingMovingPromptView];
            
            _sourceItemCollectionCellCenter = sourceCollectionViewCell.center;
            
            __weak typeof(self)weakSelf = self;
            [UIView animateWithDuration:0
                                  delay:0
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 typeof(self) __strong strongS = weakSelf;
                                 if (strongS) {
                                     highlightedSnapshotView.alpha = 0.f;
                                     snapshotView.alpha = 1.f;
                                     _beingMovingPromptView.transform = CGAffineTransformMakeScale(1.05f, 1.05f);
                                 }
                             } completion:^(BOOL finished) {
                                 typeof(self) __strong strongS = weakSelf;
                                 if (strongS) {
                                     [highlightedSnapshotView removeFromSuperview];
                                     if ([self.delegate respondsToSelector:@selector(collectionView:layout:didBeginDraggingItemAtIndexPath:)]) {
                                         [strongS.delegate collectionView:self.collectionView layout:self didBeginDraggingItemAtIndexPath:_movingIndexPath];
                                     }
                                 }
                             }];
            [self invalidateLayout];
        }
            break;
        case UIGestureRecognizerStateChanged:
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:{
            
            NSIndexPath *movingIndexPath = _movingIndexPath;
            if (movingIndexPath) {
                if ([self.delegate respondsToSelector:@selector(collectionView:layout:willEndDraggingItemAtIndexPath:)]) {
                    [self.delegate collectionView:self.collectionView layout:self willEndDraggingItemAtIndexPath:movingIndexPath];
                }
            }
            _movingIndexPath = nil;
            _sourceItemCollectionCellCenter = CGPointZero;
            
            UICollectionViewLayoutAttributes *movingItemlayoutAttributes = [self layoutAttributesForItemAtIndexPath:movingIndexPath];
            
            _longPressRecognizer.enabled = NO;
            typeof(self) __weak weakSelf = self;
            [UIView animateWithDuration:0.2
                                  delay:0
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 __strong typeof(self) strongS = weakSelf;
                                 if (strongS) {
                                     _sourceItemCollectionCellCenter = movingItemlayoutAttributes.center;
                                 }
                             }
                             completion:^(BOOL finished) {
                                 _longPressRecognizer.enabled = YES;
                                 __strong typeof(self)strongS = weakSelf;
                                 if (strongS) {
                                     _beingMovingPromptView.transform = CGAffineTransformIdentity;
                                     UIView *window = [UIApplication sharedApplication].keyWindow;
                                     CGPoint promptCenter = [self.collectionView convertPoint:_sourceItemCollectionCellCenter toView:window];
                                     _beingMovingPromptView.center = promptCenter;
                                     [_beingMovingPromptView removeFromSuperview];
                                     _beingMovingPromptView = nil;
                                     [strongS invalidateLayout];
                                     
                                     if ([strongS.delegate respondsToSelector:@selector(collectionView:layout:didEndDraggingItemAtIndexPath:)]) {
                                         [strongS.delegate collectionView:strongS.collectionView layout:strongS didEndDraggingItemAtIndexPath:movingIndexPath];
                                     }
                                 }
                             }];
            
        }
            break;
        case UIGestureRecognizerStateFailed:
            break;
        default:
            break;
    }
    
}

- (void)panGestureRecgnizerTriggerd:(UIPanGestureRecognizer *)pan {
    
    switch (pan.state) {
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:{
        
            UIView *window = [UIApplication sharedApplication].keyWindow;
            CGPoint panTranslation = [pan translationInView:self.collectionView];
            CGPoint promptCenter = [self.collectionView convertPoint:_sourceItemCollectionCellCenter toView:window];
            _beingMovingPromptView.center = CGPointOffset(promptCenter, panTranslation.x, panTranslation.y);
            
            NSIndexPath *sourceIndexPath = _movingIndexPath;
            CGPoint movingCenter = CGPointOffset(_sourceItemCollectionCellCenter, panTranslation.x, panTranslation.y);
            NSIndexPath *destinationIndexPath = [self.collectionView indexPathForItemAtPoint:movingCenter];
            if (destinationIndexPath == nil || [destinationIndexPath isEqual:sourceIndexPath])
                return;
            
            if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexpath:canMoveToIndexPath:)] && [self.dataSource collectionView:self.collectionView itemAtIndexpath:sourceIndexPath canMoveToIndexPath:destinationIndexPath] == NO)
                return;
            
            if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:willMoveToIndexPath:)]) {
                [self.dataSource collectionView:self.collectionView itemAtIndexPath:sourceIndexPath willMoveToIndexPath:destinationIndexPath];
            }
            
            _movingIndexPath = destinationIndexPath;
            
            __weak typeof(self)weakSelf = self;
            [self.collectionView performBatchUpdates:^{
                __strong typeof(self)stongS = weakSelf;
                if (stongS) {
                    if (sourceIndexPath && destinationIndexPath) {
                        [self.collectionView moveItemAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
                    }
                }
            } completion:^(BOOL finished) {
                __strong typeof(self)strongS = weakSelf;
                if ([strongS.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:didMoveToIndexPath:)]) {
                    [strongS.dataSource collectionView:strongS.collectionView itemAtIndexPath:sourceIndexPath didMoveToIndexPath:destinationIndexPath];
                }
            }];
        }
            break;
        case UIGestureRecognizerStateEnded:
            break;
        case UIGestureRecognizerStateCancelled:
            break;
        case UIGestureRecognizerStateFailed:
            break;
        default:
            break;
    }
    
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{

    if ([gestureRecognizer isEqual:_panRecognizer]) {
        return _movingIndexPath != nil;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{

    //  only _longPressGestureRecognizer and _panGestureRecognizer can recognize simultaneously
    if ([_longPressRecognizer isEqual:gestureRecognizer]) {
        return [_panRecognizer isEqual:otherGestureRecognizer];
    }
    
    if ([_panRecognizer isEqual:gestureRecognizer]) {
        return [_longPressRecognizer isEqual:otherGestureRecognizer];
    }
    
    return NO;
}


#pragma mark - KVO and Notification

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{

    if ([keyPath isEqualToString:@stringify(collectionView)]) {
        if (self.collectionView) {
            [self addGesteureRecognizers];
        }else{
            [self removeGestureRecognizers];
        }
    }
}

- (void)applicationWillResignActive:(NSNotification *)noti {

    _panRecognizer.enabled = NO;
    _panRecognizer.enabled = YES;
}





@end
