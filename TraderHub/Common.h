//
//  Copyright (c) 2016 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>
@import UIKit;

@import FirebaseDatabase;


#define CUSTOM_FIELD_TYPE_FOREX 1
#define CUSTOM_FIELD_TYPE_FUTURES 2
#define CUSTOM_FIELD_TYPE_STOCK 3

@interface Common : NSObject

+ (Common *)sharedInstance;

@property (nonatomic) BOOL signedIn;
@property (nonatomic, retain) NSString *displayName;
@property (nonatomic, retain) NSString *photoURL;

@property (nonatomic) double timeOffset;

//settings/notifications/{userid}
@property (strong, nonatomic) NSMutableArray<NSString *> *notifSettings;

//settings/custom/forex/{userid}
@property (strong, nonatomic) NSMutableArray<NSString *> *customForexList;
//settings/custom/futures/{userid}
@property (strong, nonatomic) NSMutableArray<NSString *> *customFuturesList;
//settings/custom/stock/{userid}
@property (strong, nonatomic) NSMutableArray<NSString *> *customStockList;

//settings/users/private/{userid}
@property (strong, nonatomic) NSMutableArray<NSString *> *privateAccounts;

//followings
@property (strong, nonatomic) NSMutableArray<NSString *> *followings;

+ (NSString *)timeDiffFromNow:(NSTimeInterval)time;
+ (NSString *)dateFromTime:(NSTimeInterval)time;

- (void)turnOnNotifForUser:(NSString *)userID;
- (void)turnOffNotifForUser:(NSString *)userID;
- (BOOL)isNotifTurnedOnForUser:(NSString *)userID;

+ (void) sendNotification:(NSString *)topic title:(NSString *)title body:(NSString *)body;

-(void) follow:(NSString *)userId;
-(void) unfollow:(NSString *)userId;
-(BOOL) isFollowing:(NSString *)userID;

-(void) showAlert:(UIViewController *)view title:(NSString *)title message:(NSString *)message;
-(void) addCustomFieldWithType:(int)type name:(NSString *)customName;
@end
