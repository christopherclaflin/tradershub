//
//  THTabBarController.h
//  TraderHub
//
//  Created by imac on 1/7/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface THTabBarController : UITabBarController
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController;
@end
