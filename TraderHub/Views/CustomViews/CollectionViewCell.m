//
//  CollectionViewCell.m
//  TraderHub
//
//  Created by imac on 2/22/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "CollectionViewCell.h"

@implementation CollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}
- (IBAction)onMoreClicked:(id)sender {
    if(_delegate && [_delegate respondsToSelector:@selector(onMoreClicked:)]) {
        [_delegate onMoreClicked:_data];
    }
}

@end
