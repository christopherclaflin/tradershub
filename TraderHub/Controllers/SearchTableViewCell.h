//
//  SearchTableViewCell.h
//  TraderHub
//
//  Created by imac on 1/4/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import <UIKit/UIKit.h>
@import FirebaseDatabase;

@protocol SearchCellDelegate <NSObject>

@optional
- (void)didClickOnCellWithData:(id)data;
- (void)didClickOnAvatar:(NSString *)uid;

@end

@interface SearchTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *btnMore;
@property (weak, nonatomic) IBOutlet UIImageView *imgUser;
@property (weak, nonatomic) IBOutlet UILabel *lblName;
@property (weak, nonatomic) IBOutlet UILabel *lblMarket;
@property (weak, nonatomic) IBOutlet UIImageView *imgInc;
@property (weak, nonatomic) IBOutlet UILabel *lblEntry;
@property (weak, nonatomic) IBOutlet UILabel *lblStop;
@property (weak, nonatomic) IBOutlet UILabel *lblTarget;
@property (weak, nonatomic) IBOutlet UILabel *lblType;

@property (strong, nonatomic) FIRDataSnapshot *snapshot;

@property (weak, nonatomic) id<SearchCellDelegate>delegate;

- (void)setCellData:(id)data;
@end
