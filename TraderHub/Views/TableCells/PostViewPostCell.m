//
//  PostViewPostCell.m
//  TraderHub
//
//  Created by imac on 1/22/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "PostViewPostCell.h"
#import "Constants.h"
#import "Common.h"

#import <SDWebImage/UIImageView+WebCache.h>

@import FirebaseStorage;
@import FirebaseDatabase;


@implementation PostViewPostCell{
    FIRDatabaseReference *ref;
    FIRDataSnapshot *snapshot;
    
    NSString *uid;
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
    
    NSDictionary *post = snapshot.value;
    
    _lblMarket.text = post[PostFieldsMarket];
    _lblEntry.text = post[PostFieldsEntry];
    _lblStop.text = post[PostFieldsStop];
    
    BOOL isTargetOn = post[PostFieldsIsTargetOn];
    if(isTargetOn)
        _lblTarget.text = post[PostFieldsTarget];
    else
        _lblTarget.text = @"#";
    
    BOOL isSell = [post[PostFieldsIsSell] boolValue];
    if(!isSell) {
        [_imgInc setImage:[UIImage imageNamed:@"ic_inc.png"]];
    } else {
        [_imgInc setImage:[UIImage imageNamed:@"ic_dec.png"]];
        
    }
    
    _lblType.text = post[PostFieldsType];
    NSTimeInterval time = [post[PostFieldsTime] doubleValue];
    _lblTime.text = [Common dateFromTime:time];
    
    NSString *imgURL = post[PostFieldsImageURL];
    
    if (imgURL) {
        if([imgURL containsString:@"gs://"]) {
            [[[FIRStorage storage] referenceForURL:imgURL] downloadURLWithCompletion:^(NSURL * _Nullable URL, NSError * _Nullable error) {
                if(URL){
                    [_imgPost sd_setImageWithURL:URL placeholderImage:[UIImage imageNamed:@"img_placeholder.png"]];
                }
            }];
        } else {
            NSURL *URL = [NSURL URLWithString:imgURL];
            if (URL) {
                [_imgPost sd_setImageWithURL:URL placeholderImage:[UIImage imageNamed:@"img_placeholder.png"]];
            }
        }
    }
    
    _lblPost.text = post[PostFieldsContent];
}
@end
