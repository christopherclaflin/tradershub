//
//  SearchTableViewCell.m
//  TraderHub
//
//  Created by imac on 1/4/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "SearchTableViewCell.h"
#import "Constants.h"
#import <SDWebImage/UIImageView+WebCache.h>

@import FirebaseStorage;

@implementation SearchTableViewCell {
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

- (IBAction)onBtnMoreClicked:(id)sender {
    if (_delegate && [self.delegate respondsToSelector:@selector(didClickOnCellWithData:)]) {
        [self.delegate didClickOnCellWithData:_snapshot];
    }
}

- (void)setCellData:(FIRDataSnapshot *)data {
    self.snapshot = data;
    if(!_snapshot || !_snapshot.exists)
        return;
    
    NSDictionary *post = _snapshot.value;
    
    if(data) {
        _lblName.text = post[PostFieldsUsername];
        _lblMarket.text = post[PostFieldsMarket];
        
        NSNumber *entry = post[PostFieldsEntry];
        _lblEntry.text = [NSString stringWithFormat:@"%.2f", entry.floatValue];
        
        NSNumber *stop = post[PostFieldsStop];
        _lblStop.text = [NSString stringWithFormat:@"%.2f", stop.floatValue];
        
        BOOL isTargetOn = [post[PostFieldsIsTargetOn] boolValue];
        
        if(isTargetOn) {
            NSNumber *target = post[PostFieldsTarget];
            _lblTarget.text = [NSString stringWithFormat:@"%.2f", target.floatValue];
        } else {
            _lblTarget.text = @"#";
        }
        
        BOOL isSell = [post[PostFieldsIsSell] boolValue];
        if(!isSell) {
            [_imgInc setImage:[UIImage imageNamed:@"ic_inc.png"]];
        } else {
            [_imgInc setImage:[UIImage imageNamed:@"ic_dec.png"]];
        }
        
        _lblType.text = post[PostFieldsType];
        uid = post[PostFieldsUid];
        
        NSString *photoURL = post[PostFieldsPhotoUrl];
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

@end
