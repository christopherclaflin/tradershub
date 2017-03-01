//
//  HeaderCollectionViewCell.m
//  TraderHub
//
//  Created by imac on 2/22/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "HeaderCollectionViewCell.h"

@implementation HeaderCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    _imgUser.layer.cornerRadius = _imgUser.frame.size.width/2;
    _imgUser.layer.masksToBounds = YES;
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected)];
    singleTap.numberOfTapsRequired = 1;
    [self.imgUser setUserInteractionEnabled:YES];
    [self.imgUser addGestureRecognizer:singleTap];
}

-(void)tapDetected{
    NSLog(@"single Tap on imageview");
    
    if (_delegate && [self.delegate respondsToSelector:@selector(didClickOnAvatar:)]) {
        if(_userID)
            [self.delegate didClickOnAvatar:_userID];
    }
}

@end
