//
//  HomeTableViewCell.m
//  TraderHub
//
//  Created by imac on 1/3/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "HomeTableViewCell.h"
#import "Constants.h"

#import <SDWebImage/UIImageView+WebCache.h>

@import FirebaseStorage;
@import FirebaseDatabase;

@implementation HomeTableViewCell {
    FIRDatabaseReference *ref;
    FIRDataSnapshot *snapshot;
    
    NSString *uid;
}


- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.imgUser.layer.cornerRadius = self.imgUser.frame.size.height / 2;
    self.imgUser.clipsToBounds = YES;
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected)];
    singleTap.numberOfTapsRequired = 1;
    [self.imgUser setUserInteractionEnabled:YES];
    [self.imgUser addGestureRecognizer:singleTap];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)tapDetected{
    NSLog(@"single Tap on imageview");
    
    if (_delegate && [self.delegate respondsToSelector:@selector(didClickOnAvatar:)]) {
        if(uid)
            [self.delegate didClickOnAvatar:uid];
    }
}

- (void)setCellData:(id)data {
    snapshot = data;
    
    
    if(!ref)
        ref = [[FIRDatabase database] reference];
    
    NSDictionary *info = snapshot.value;
    
    if(info) {
        _lblName.text = info[PostFieldsUsername];
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
        if(!isSell) {
            [_imgInc setImage:[UIImage imageNamed:@"ic_inc.png"]];
        } else {
            [_imgInc setImage:[UIImage imageNamed:@"ic_dec.png"]];
        }
        
        _lblType.text = info[PostFieldsType];
        uid = info[PostFieldsUid];
        
        NSString *photoURL = info[PostFieldsPhotoUrl];
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
    }
}
- (IBAction)onMoreClicked:(id)sender {
    if (_delegate && [self.delegate respondsToSelector:@selector(didClickOnCellWithData:)]) {
        [self.delegate didClickOnCellWithData:snapshot];
    }
}
@end
