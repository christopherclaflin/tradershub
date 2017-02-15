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

#import "Constants.h"

@implementation Constants

NSString *const NotificationKeysSignedIn = @"onSignInCompleted";

NSString *const PostFieldsUid = @"uid";
NSString *const PostFieldsUsername = @"username";
NSString *const PostFieldsPhotoUrl = @"photoURL";
NSString *const PostFieldsMarket = @"market";
NSString *const PostFieldsEntry = @"entry";
NSString *const PostFieldsStop = @"stop";
NSString *const PostFieldsIsSell = @"isSell";
NSString *const PostFieldsTarget = @"target";
NSString *const PostFieldsIsTargetOn = @"isTargetOn";
NSString *const PostFieldsType = @"type";
NSString *const PostFieldsImageURL = @"imageURL";
NSString *const PostFieldsContent = @"content";
NSString *const PostFieldsTime = @"time";

//post comments
NSString *const CommentFieldsContent = @"content";
NSString *const CommentFieldsPhotoURL = @"photoURL";
NSString *const CommentFieldsDisplayName = @"displayName";
NSString *const CommentFieldsUserID = @"uid";
NSString *const CommentFieldsTime = @"time";

//users
NSString *const UserFieldsDisplayname = @"displayName";
NSString *const UserFieldsPhotoURL = @"photoURL";
NSString *const UserFieldsUsername = @"username";
NSString *const UserFieldsBio = @"bio";
NSString *const UserFieldsWebsite = @"website";

//notifications
NSString *const NotifFieldsPhotoURL = @"photoURL";
NSString *const NotifFieldsContent = @"content";
NSString *const NotifFieldsTime = @"time";
NSString *const NotifFieldsRead = @"read";

//message channels
NSString *const ChannelFieldsName = @"name";
NSString *const ChannelFieldsLastMsg = @"lastMessage";
NSString *const ChannelFieldsPhotoURL = @"photoURL";
NSString *const ChannelFieldsTime = @"lastUpdateTime";
NSString *const ChannelFieldsUnreads = @"unreads";

NSString *const MessageFieldsSenderId = @"senderId";
NSString *const MessageFieldsSenderName = @"senderName";
NSString *const MessageFieldsText = @"text";
NSString *const MessageFieldsTime = @"time";


@end
