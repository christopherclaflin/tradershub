//
//  HomeTableViewCell.h
//  TraderHub
//
//  Created by imac on 1/3/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"
@protocol HomeCellDelegate <NSObject>
- (void)didClickOnCellWithData:(id)data;
- (void)didClickOnAvatar:(NSString *)uid;
@end

@interface HomeTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imgUser;
@property (weak, nonatomic) IBOutlet UILabel *lblName;
@property (weak, nonatomic) IBOutlet UILabel *lblMarket;
@property (weak, nonatomic) IBOutlet UIImageView *imgInc;
@property (weak, nonatomic) IBOutlet UILabel *lblEntry;
@property (weak, nonatomic) IBOutlet UILabel *lblStop;
@property (weak, nonatomic) IBOutlet UILabel *lblTarget;
@property (weak, nonatomic) IBOutlet UILabel *lblType;
@property (weak, nonatomic) IBOutlet UIButton *btnMore;

@property (weak, nonatomic) id<HomeCellDelegate>delegate;

- (void)setCellData:(id)data;
@end
