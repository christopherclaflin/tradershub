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

#import "Common.h"
#import "Constants.h"
#import "NSDate+DateTools.h"
#import <AFNetworking/AFNetworking.h>
#import "AFURLRequestSerialization.h"

@import FirebaseMessaging;
@import Firebase;
@import FirebaseDatabase;
@import FirebaseStorage;
@import FirebaseRemoteConfig;
@import FirebaseAuth;

@interface Common () {
    
}
@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) FIRStorageReference *storageRef;

@end


@implementation Common

+ (Common *)sharedInstance {
  static Common *sharedMyInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedMyInstance = [[self alloc] init];
  });
    
    if(!sharedMyInstance.ref) {
        sharedMyInstance.ref = [[FIRDatabase database] reference];
    }
    
  return sharedMyInstance;
}

+ (NSString *)timeDiffFromNow:(NSTimeInterval)time {
    if (time == 0)
        return @"";
//    NSDate *date = [NSDate dateWithTimeIntervalSince1970:(time-[Common sharedInstance].timeOffset)/1000];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time/1000];
//    NSDate *date = [NSDate date];
    
    return [date shortTimeAgoSinceNow];
}

+ (NSString *)dateFromTime:(NSTimeInterval)time {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time/1000];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd/MM/YY"];
    NSString *dateString = [formatter stringFromDate:date];
    
    return dateString;
}

- (void)turnOnNotifForUser:(NSString *)userID {
    [_notifSettings addObject:userID];
    
    NSString *topic = [NSString stringWithFormat:@"topics/followers%@", userID];
    [[FIRMessaging messaging] subscribeToTopic:topic];
}
- (void)turnOffNotifForUser:(NSString *)userID {
    for(int i=0; i<_notifSettings.count; i++) {
        NSString *aUserID = _notifSettings[i];
        
        if([aUserID isEqualToString:userID])
            [_notifSettings removeObject:aUserID];
    }
    
    NSString *topic = [NSString stringWithFormat:@"topics/followers%@", userID];
    [[FIRMessaging messaging] subscribeToTopic:topic];
}

- (BOOL)isNotifTurnedOnForUser:(NSString *)userID {
    for(int i=0; i<_notifSettings.count; i++) {
        NSString *aUserID = _notifSettings[i];
        
        if([aUserID isEqualToString:userID])
            return TRUE;
    }
    return FALSE;
}


+ (void) doPostWithURL:(NSString *)url parameters:(NSDictionary *)parameters {
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [manager POST:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"success!");
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error: %@", error);
    }];
//    [[AFHTTPRequestSerializer serializer] requestWithMethod:@"POST" URLString:url parameters:parameters error:nil];
}

+ (void) sendNotification:(NSString *)topic title:(NSString *)title body:(NSString *)body{
    static NSString *url = @"http://thesuperdevs.com/fcm/public/send-to-topic";
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:topic, @"topic", title, @"title", body, @"body", nil];
    
    [Common doPostWithURL:url parameters:parameters];
}

-(void)follow:(NSString *)userId {
    NSString *me = [FIRAuth auth].currentUser.uid;
    NSString *myDisplayName = [FIRAuth auth].currentUser.displayName;
    NSString *myPhotoURL = [FIRAuth auth].currentUser.photoURL.absoluteString;
    
    NSString *path = [NSString stringWithFormat:@"followers/%@/%@", userId, me];
    [[_ref child:path] setValue:@"TRUE"];
    
    path = [NSString stringWithFormat:@"followings/%@/%@", me, userId];
    [[_ref child:path] setValue:@"TRUE"];
    
    path = [NSString stringWithFormat:@"notifications/%@", userId];
    
    NSMutableDictionary *notifData = [[NSMutableDictionary alloc] init];
    notifData[NotifFieldsContent] = [NSString stringWithFormat:@"%@ followed you.", myDisplayName];
    notifData[NotifFieldsRead] = @"FALSE";
    notifData[NotifFieldsPhotoURL] = myPhotoURL;
    notifData[NotifFieldsTime] = [FIRServerValue timestamp];
    
    [[[_ref child:path] childByAutoId] setValue:notifData];
    
    
    //register to followers of <uid> for notification
    NSString *topic = [NSString stringWithFormat:@"/topics/followers%@", userId];
    [[FIRMessaging messaging] subscribeToTopic:topic];
    
    //for turn on/off notification
    path = [NSString stringWithFormat:@"settings/notifications/%@/%@", me, userId];
    [[_ref child:path] setValue:@"TRUE"];
}

-(void)unfollow:(NSString *)userId {
    NSString *me = [FIRAuth auth].currentUser.uid;
    
    NSString *path = [NSString stringWithFormat:@"followers/%@/%@", userId, me];
    [[_ref child:path] removeValue];
    
    path = [NSString stringWithFormat:@"followings/%@/%@", me, userId];
    [[_ref child:path] removeValue];
    
    //register to followers of <uid> for notification
    NSString *topic = [NSString stringWithFormat:@"/topics/followers%@", userId];
    [[FIRMessaging messaging] unsubscribeFromTopic:topic];
    
    //for turn on/off notification
    path = [NSString stringWithFormat:@"settings/notifications/%@/%@", me, userId];
    [[_ref child:path] removeValue];
}

-(BOOL)isFollowing:(NSString *)userID {
    for(int i=0; i<self.followings.count; i++) {
        if([self.followings[i] isEqualToString:userID])
            return TRUE;
    }
    return FALSE;
}

-(void) showAlert:(UIViewController *)view title:(NSString *)title message:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:ok];
    
    [view presentViewController:alertController animated:YES completion:nil];
}

-(void) addCustomFieldWithType:(int)type name:(NSString *)customName {
    NSMutableArray *array;
    NSString *path;
    NSString *myId = [FIRAuth auth].currentUser.uid;
    
    if(type == CUSTOM_FIELD_TYPE_FOREX) {
        array = self.customForexList;
        path = [NSString stringWithFormat:@"settings/custom/forex/%@", myId];
    } else if(type == CUSTOM_FIELD_TYPE_FUTURES) {
        array = self.customFuturesList;
        path = [NSString stringWithFormat:@"settings/custom/futures/%@", myId];
    } else if(type == CUSTOM_FIELD_TYPE_STOCK) {
        array = self.customStockList;
        path = [NSString stringWithFormat:@"settings/custom/stock/%@", myId];
    } else {
        return;
    }
    
    for(int i=0; i<array.count; i++) {
        NSString *field = array[i];
        if([field isEqualToString:customName])
            return;
    }
    
    [[[_ref child:path] childByAutoId] setValue:customName];
}
@end
