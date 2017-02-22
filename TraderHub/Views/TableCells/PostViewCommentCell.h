//
//  PostViewCommentCell.h
//  TraderHub
//
//  Created by imac on 1/22/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KILabel.h"

@protocol CommentCellDelegate <NSObject>
- (void)didClickOnAvatar:(NSString *)uid;
@end


@interface PostViewCommentCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imgUser;
@property (weak, nonatomic) IBOutlet UILabel *lblDisplayName;
@property (weak, nonatomic) IBOutlet UILabel *lblTime;
@property (weak, nonatomic) IBOutlet KILabel *lblContent;

@property (weak, nonatomic) id<CommentCellDelegate>delegate;

- (void)setCellData:(id)data;

@end
