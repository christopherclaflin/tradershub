//
//  HeaderCollectionViewCell.h
//  TraderHub
//
//  Created by imac on 2/22/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FeedCollectionHeaderDelegate <NSObject>

@optional
- (void)didClickOnAvatar:(NSString *)uid;

@end

@interface HeaderCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imgUser;
@property (weak, nonatomic) IBOutlet UILabel *lblUsername;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imgUserWidthConstraint;

@property (weak, nonatomic) id<FeedCollectionHeaderDelegate> delegate;
@property (weak, nonatomic) NSString *userID;
@end
