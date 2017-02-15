//
//  NotificationCell.h
//  TraderHub
//
//  Created by imac on 1/7/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NotificationCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imgUser;
@property (weak, nonatomic) IBOutlet UILabel *lblNotif;
@property (weak, nonatomic) IBOutlet UILabel *lblTime;

@end
