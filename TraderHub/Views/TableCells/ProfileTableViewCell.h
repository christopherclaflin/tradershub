//
//  ProfileTableViewCell.h
//  TraderHub
//
//  Created by imac on 1/14/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProfileTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *lblMarket;
@property (weak, nonatomic) IBOutlet UIImageView *imgInc;
@property (weak, nonatomic) IBOutlet UILabel *lblEntry;
@property (weak, nonatomic) IBOutlet UILabel *lblStop;
@property (weak, nonatomic) IBOutlet UILabel *lblTarget;
@property (weak, nonatomic) IBOutlet UILabel *lblType;
@property (weak, nonatomic) IBOutlet UILabel *lblDate;

- (void)setCellData:(id)data;
@end
