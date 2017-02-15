//
//  SearchViewController.h
//  TraderHub
//
//  Created by imac on 1/4/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchViewController : UIViewController
@property (nonatomic, copy) NSString *strSearch;
- (void)didClickOnCellWithData:(id)data;
@end
