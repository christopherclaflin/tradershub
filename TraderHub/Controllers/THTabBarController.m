//
//  THTabBarController.m
//  TraderHub
//
//  Created by imac on 1/7/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "THTabBarController.h"
#import "NewPostViewController.h"

@interface THTabBarController ()< UITabBarControllerDelegate>

@end

@implementation THTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setDelegate:self];
    
    
    //set background image
    CGRect rect = [[UIScreen mainScreen] bounds];
    UIImageView *tabBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, rect.size.width, 49)];
    tabBackground.image = [UIImage imageNamed:@"tabbar_back.png"];
    tabBackground.contentMode = UIViewContentModeScaleAspectFill;
    [self.tabBar insertSubview:tabBackground atIndex:0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    
    UINavigationController *navigationController;
    if([viewController isKindOfClass:[UINavigationController class]])
        navigationController = (UINavigationController *)viewController;
    
    if  (navigationController && [navigationController.viewControllers[0] isKindOfClass:[NewPostViewController class]])  {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        
        NewPostViewController *postview = [storyboard instantiateViewControllerWithIdentifier:@"newpostview"];
        
        [self.selectedViewController pushViewController:postview animated:YES];
        return NO;
    }
    return YES;
}

//- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
//    NSLog(@"didselectitem");
//}

@end
