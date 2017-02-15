//
//  MessageListTableViewCell.h
//  TraderHub
//
//  Created by imac on 1/15/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "M13BadgeView/M13BadgeView.h"

@interface MessageListTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imgUser;
@property (weak, nonatomic) IBOutlet UILabel *lblLastMsg;
@property (weak, nonatomic) IBOutlet UILabel *lblUsername;
@property (weak, nonatomic) IBOutlet UILabel *lblTime;

@property (retain, nonatomic) M13BadgeView *badgeView;


- (void)setCellData:(id)data;
@end
