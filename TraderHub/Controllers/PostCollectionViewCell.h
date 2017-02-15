//
//  SearchCollectionViewCell.h
//  TraderHub
//
//  Created by imac on 1/4/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PostGridCellDelegate <NSObject>
- (void)didClickOnGridCellWithData:(id)data;
@end


@interface PostCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imgPost;

@property (weak, nonatomic) id<PostGridCellDelegate> delegate;
- (void)setCellData:(id)data;
@end
