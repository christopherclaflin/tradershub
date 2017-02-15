//
//  ProfileTableViewCell.m
//  TraderHub
//
//  Created by imac on 1/14/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "ProfileTableViewCell.h"
#import "Constants.h"
#import "Common.h"

#import <SDWebImage/UIImageView+WebCache.h>

@import FirebaseStorage;
@import FirebaseDatabase;


@implementation ProfileTableViewCell {
    FIRDatabaseReference *ref;
    FIRDataSnapshot *snapshot;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
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
        _lblMarket.text = info[PostFieldsMarket];
        
        NSNumber *entry = info[PostFieldsEntry];
        _lblEntry.text = [NSString stringWithFormat:@"%.2f", entry.floatValue];
        
        NSNumber *stop = info[PostFieldsStop];
        _lblStop.text = [NSString stringWithFormat:@"%.2f", stop.floatValue];
        
        BOOL isTargetOn = [info[PostFieldsIsTargetOn] boolValue];
        
        if(isTargetOn) {
            NSNumber *target = info[PostFieldsTarget];
            _lblTarget.text = [NSString stringWithFormat:@"%.2f", target.floatValue];
        } else {
            _lblTarget.text = @"#";
        }
        
        BOOL isSell = [info[PostFieldsIsSell] boolValue];
        if(isSell) {
            [_imgInc setImage:[UIImage imageNamed:@"ic_dec.png"]];
        } else {
            [_imgInc setImage:[UIImage imageNamed:@"ic_inc.png"]];
        }
        
        _lblType.text = info[PostFieldsType];
        NSTimeInterval time = [info[PostFieldsTime] doubleValue];
        _lblDate.text = [Common dateFromTime:time];
    }
}

@end
