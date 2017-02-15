//
//  FConn.m
//  TraderHub
//
//  Created by imac on 1/16/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "FConn.h"
#import "Constants.h"

@import Firebase;
@import FirebaseDatabase;
@import FirebaseStorage;
@import FirebaseRemoteConfig;
@import FirebaseAuth;

@interface FConn () {
    
}
@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) FIRStorageReference *storageRef;

@end

@implementation FConn {
    
}

+ (FConn *)shared {
    static FConn *sharedMyInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyInstance = [[self alloc] init];
    });
    
    if(!sharedMyInstance.ref) {
        sharedMyInstance.ref = [[FIRDatabase database] reference];
    }
    
    return sharedMyInstance;
}




@end
