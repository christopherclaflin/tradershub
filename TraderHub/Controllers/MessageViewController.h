//
//  MessageViewController.h
//  TraderHub
//
//  Created by imac on 1/6/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import <UIKit/UIKit.h>

@import FirebaseDatabase;
@import JSQMessagesViewController;


@interface MessageViewController : JSQMessagesViewController
@property (strong, nonatomic) FIRDataSnapshot *snapshot;

@property (strong, nonatomic) IBOutlet UILabel *lblTitle;
@property (strong, nonatomic) IBOutlet UIButton *btnBack;

@property (strong, nonatomic) NSString *opponentDisplayName;
@property (strong, nonatomic) NSString *opponentPhotoURL;
@property (strong, nonatomic) NSString *opponentUID;
@end
