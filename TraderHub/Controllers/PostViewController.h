//
//  PostViewController.h
//  TraderHub
//
//  Created by imac on 1/5/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import <UIKit/UIKit.h>
@import FirebaseDatabase;

@interface PostViewController : UIViewController

@property (weak, nonatomic) FIRDataSnapshot *snapshot;

@end
