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

@interface Constants : NSObject

#define URL_HELP_CENTER     @"https://tradershubapp.com/support"
#define URL_REPORT_PROBLEM  @"https://tradershubapp.com/support"
#define URL_LEARN_TO_TRADE  @"https://tradershubapp.com/learn-to-trade"
#define URL_BLOG            @"https://tradershubapp.com/learn-to-trade"
#define URL_PRIVACY_POLICY  @"https://tradershubapp.com/privacy"
#define URL_TERMS           @"https://tradershubapp.com/terms-and-conditions"

extern NSString *const NotificationKeysSignedIn;

extern NSString *const PostFieldsUid;
extern NSString *const PostFieldsUsername;
extern NSString *const PostFieldsPhotoUrl;
extern NSString *const PostFieldsMarket;
extern NSString *const PostFieldsEntry;
extern NSString *const PostFieldsStop;
extern NSString *const PostFieldsIsSell;
extern NSString *const PostFieldsTarget;
extern NSString *const PostFieldsIsTargetOn;
extern NSString *const PostFieldsType;
extern NSString *const PostFieldsImageURL;
extern NSString *const PostFieldsContent;
extern NSString *const PostFieldsTime;

extern NSString *const CommentFieldsContent;
extern NSString *const CommentFieldsPhotoURL;
extern NSString *const CommentFieldsDisplayName;
extern NSString *const CommentFieldsUserID;
extern NSString *const CommentFieldsTime;

extern NSString *const UserFieldsDisplayname;
extern NSString *const UserFieldsPhotoURL;
extern NSString *const UserFieldsUsername;
extern NSString *const UserFieldsBio;
extern NSString *const UserFieldsWebsite;

extern NSString *const NotifFieldsPhotoURL;
extern NSString *const NotifFieldsContent;
extern NSString *const NotifFieldsTime;
extern NSString *const NotifFieldsRead;

extern NSString *const ChannelFieldsName;
extern NSString *const ChannelFieldsLastMsg;
extern NSString *const ChannelFieldsPhotoURL;
extern NSString *const ChannelFieldsTime;
extern NSString *const ChannelFieldsUnreads;

extern NSString *const MessageFieldsSenderId;
extern NSString *const MessageFieldsSenderName;
extern NSString *const MessageFieldsText;
extern NSString *const MessageFieldsTime;
@end
