//
//  MessageListTableViewCell.m
//  TraderHub
//
//  Created by imac on 1/15/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "MessageListTableViewCell.h"
#import "Constants.h"
#import "Common.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "M13BadgeView/M13BadgeView.h"


@import Firebase;
@import FirebaseStorage;
@import FirebaseDatabase;

@implementation MessageListTableViewCell {
    FIRDatabaseReference *ref;
    FIRDataSnapshot *snapshot;
    CGRect rectBadge;
    
    
}

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

- (void)setCellData:(id)data {
    snapshot = data;
    
    if(!ref)
        ref = [[FIRDatabase database] reference];
    
    NSDictionary *info = snapshot.value;
    
    if(info) {
        _lblUsername.text = info[ChannelFieldsName];
        NSTimeInterval time = [info[ChannelFieldsTime] doubleValue];
        _lblTime.text = [Common timeDiffFromNow:time];
        
        _lblLastMsg.text = info[ChannelFieldsLastMsg];
        NSString *photoURL = info[ChannelFieldsPhotoURL];
        
        if (photoURL) {
            if([photoURL containsString:@"gs://"]) {
                [[[FIRStorage storage] referenceForURL:photoURL] downloadURLWithCompletion:^(NSURL * _Nullable URL, NSError * _Nullable error) {
                    if(URL){
                        [_imgUser sd_setImageWithURL:URL placeholderImage:[UIImage imageNamed:@"avatar.png"]];
                    }
                }];
            } else {
                NSURL *URL = [NSURL URLWithString:photoURL];
                if (URL) {
                    [_imgUser sd_setImageWithURL:URL placeholderImage:[UIImage imageNamed:@"avatar.png"]];
                }
            }
        }
        
        if([info objectForKey:ChannelFieldsTime]) {
            NSTimeInterval time = [info[ChannelFieldsTime] doubleValue];
            
            _lblTime.text = [Common timeDiffFromNow:time];
        }
        
        
        CGRect rectUser = _imgUser.layer.frame;
        rectBadge = CGRectMake(rectUser.origin.x + rectUser.size.width - 20, rectUser.origin.y + rectUser.size.height - 20, 20, 20);

        int unreads = [info[ChannelFieldsUnreads] intValue];
        
        if(!_badgeView)
            _badgeView = [[M13BadgeView alloc] initWithFrame:rectBadge];
        _badgeView.text = [NSString stringWithFormat:@"%d", unreads];
        _badgeView.layer.frame = rectBadge;
        [self.contentView addSubview:_badgeView];
        
        if(unreads == 0)
            _badgeView.hidden = YES;
        else
            _badgeView.hidden = NO;
        
    }
}


@end
