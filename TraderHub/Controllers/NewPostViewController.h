//
//  NewPostViewController.h
//  TraderHub
//
//  Created by imac on 1/4/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AttachImageDelegate <NSObject>

@optional
- (void)attachImageViewDismisWithContent:(NSString *)content imageURL:(NSString *)imageURL;
@end

@interface NewPostViewController : UIViewController

@end
