//
//  PostViewCommentCell.m
//  TraderHub
//
//  Created by imac on 1/22/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "PostViewCommentCell.h"
#import "Constants.h"
#import "Common.h"

#import <SDWebImage/UIImageView+WebCache.h>

@import FirebaseStorage;
@import FirebaseDatabase;


@implementation PostViewCommentCell {
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

-(void)tapDetected{
    NSLog(@"single Tap on imageview");
    
    if (_delegate && [self.delegate respondsToSelector:@selector(didClickOnAvatar:)]) {
        if(uid)
            [self.delegate didClickOnAvatar:uid];
    }
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
        _lblDisplayName.text = info[CommentFieldsDisplayName];
        
        NSTimeInterval time = [info[CommentFieldsTime] doubleValue];
        _lblTime.text = [Common timeDiffFromNow:time];
        
        _lblContent.text = info[CommentFieldsContent];
        
        uid = info[CommentFieldsUserID];
        
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


@end
