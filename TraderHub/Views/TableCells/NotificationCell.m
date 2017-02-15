//
//  NotificationCell.m
//  TraderHub
//
//  Created by imac on 1/7/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "NotificationCell.h"

@implementation NotificationCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.imgUser.layer.cornerRadius = self.imgUser.frame.size.height / 2;
    self.imgUser.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
