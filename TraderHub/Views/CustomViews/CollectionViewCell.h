//
//  CollectionViewCell.h
//  TraderHub
//
//  Created by imac on 2/22/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FeedCollectionCellDelegate <NSObject>

@optional
- (void) onMoreClicked:(id)data;

@end

@interface CollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *lblMarket;
@property (weak, nonatomic) IBOutlet UIImageView *imgIncDec;
@property (weak, nonatomic) IBOutlet UILabel *lblEntry;
@property (weak, nonatomic) IBOutlet UILabel *lblStop;
@property (weak, nonatomic) IBOutlet UILabel *lblTarget;
@property (weak, nonatomic) IBOutlet UILabel *lblType;
@property (weak, nonatomic) IBOutlet UIButton *btnMore;

@property (weak, nonatomic) id<FeedCollectionCellDelegate> delegate;

@property (weak, nonatomic) id data;
@end
