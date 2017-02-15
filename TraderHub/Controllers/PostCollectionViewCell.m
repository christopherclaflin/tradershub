//
//  SearchCollectionViewCell.m
//  TraderHub
//
//  Created by imac on 1/4/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "PostCollectionViewCell.h"
#import "Constants.h"
#import <SDWebImage/UIImageView+WebCache.h>

@import FirebaseStorage;
@import FirebaseDatabase;

@implementation PostCollectionViewCell {
    FIRDataSnapshot *snapshot;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected)];
    singleTap.numberOfTapsRequired = 1;
    [self.imgPost setUserInteractionEnabled:YES];
    [self.imgPost addGestureRecognizer:singleTap];
    
    CGRect rect = self.frame;
    CGRect rectScreen = [[UIScreen mainScreen] bounds];
    rect.size.width = rectScreen.size.width / 3;
    rect.size.height = rect.size.width;
    self.frame = rect;
}

-(void)tapDetected{
    if (_delegate && [self.delegate respondsToSelector:@selector(didClickOnGridCellWithData:)]) {
        [self.delegate didClickOnGridCellWithData:snapshot];
    }
}

- (void)setCellData:(id)data {
    snapshot = data;
    
    NSDictionary *info = snapshot.value;
    
    if(info) {
        NSString *photoURL = info[PostFieldsImageURL];
        if (photoURL) {
            if([photoURL containsString:@"gs://"]) {
                [[[FIRStorage storage] referenceForURL:photoURL] downloadURLWithCompletion:^(NSURL * _Nullable URL, NSError * _Nullable error) {
                    if(URL){
                        [_imgPost sd_setImageWithURL:URL placeholderImage:[UIImage imageNamed:@"img_placeholder.png"]];
                    }
                }];
            } else {
                NSURL *URL = [NSURL URLWithString:photoURL];
                if (URL) {
                    [_imgPost sd_setImageWithURL:URL placeholderImage:[UIImage imageNamed:@"img_placeholder.png"]];
                }
            }
        } else {
            [_imgPost setImage:[UIImage imageNamed:@"img_placeholder.png"]];
        }
    }
}


@end
