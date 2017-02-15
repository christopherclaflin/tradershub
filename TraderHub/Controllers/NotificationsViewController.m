//
//  NotificationsViewController.m
//  TraderHub
//
//  Created by imac on 1/5/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "NotificationsViewController.h"
#import "NotificationItem.h"
#import "NotificationCell.h"
#import "Constants.h"
#import "Common.h"

#import <SDWebImage/UIImageView+WebCache.h>

@import Firebase;
@import FirebaseDatabase;
@import FirebaseStorage;
@import FirebaseRemoteConfig;
@import FirebaseAuth;

@interface NotificationsViewController () <UITableViewDelegate, UITableViewDataSource> {
    FIRDatabaseHandle _refHandleInsert, _refHandleDelete;
}

@property (weak, nonatomic) IBOutlet UITableView *table;

@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *notifications;
@property (strong, nonatomic) FIRStorageReference *storageRef;


@end

@implementation NotificationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _notifications = [NSMutableArray array];
    
    _table.allowsMultipleSelectionDuringEditing = NO;
    _table.delegate = self;
    _table.dataSource = self;
    
    [self configureDatabase];
    [self configureStorage];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    NSString *path = [NSString stringWithFormat:@"notifications/%@", [FIRAuth auth].currentUser.uid];
    [[_ref child:path] removeObserverWithHandle:_refHandleInsert];
    [[_ref child:path] removeObserverWithHandle:_refHandleDelete];
}

- (void)configureStorage {
    NSString *storageUrl = [FIRApp defaultApp].options.storageBucket;
    self.storageRef = [[FIRStorage storage] referenceForURL:[NSString stringWithFormat:@"gs://%@", storageUrl]];
}

- (void)configureDatabase {
    _ref = [[FIRDatabase database] reference];
    // Listen for new messages in the Firebase database
    
    NSString *path = [NSString stringWithFormat:@"notifications/%@", [FIRAuth auth].currentUser.uid];
    
    _refHandleInsert = [[_ref child:path] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        [_notifications insertObject:snapshot atIndex:0];
        [_table insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation: UITableViewRowAnimationAutomatic];
        
        [[snapshot.ref child:NotifFieldsRead] setValue:@"TRUE"];
    }];
    
    _refHandleDelete = [[_ref child:path]
     observeEventType:FIRDataEventTypeChildRemoved
     withBlock:^(FIRDataSnapshot *snapshot) {
         int index = [self indexOfNotification:snapshot];
         [_notifications removeObjectAtIndex:index];
         [_table deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                               withRowAnimation:UITableViewRowAnimationAutomatic];
     }];
}

- (int)indexOfNotification:(FIRDataSnapshot *)snapshot {
    for(int i=0; i<_notifications.count; i++) {
        FIRDataSnapshot *aSnapshot = _notifications[i];
        if([aSnapshot.key isEqualToString:snapshot.key])
            return i;
    }
    return 0;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_notifications count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == _table) {
        
        static NSString *CellIdentifier = @"notifcell";
        
        int row = (int)indexPath.row;
        NotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        FIRDataSnapshot *postSnapshot = _notifications[row];
        
        if(!postSnapshot.exists)
            return nil;
        
        NSDictionary<NSString *, NSString *> *notif = postSnapshot.value;
        
        NSString *photoURL = notif[NotifFieldsPhotoURL];
        
        if (photoURL) {
            if([photoURL containsString:@"gs://"]) {
                [[[FIRStorage storage] referenceForURL:photoURL] downloadURLWithCompletion:^(NSURL * _Nullable URL, NSError * _Nullable error) {
                    if(URL){
                        [cell.imgUser sd_setImageWithURL:URL placeholderImage:[UIImage imageNamed:@"btn_profile.png"]];
                    }
                }];
            } else {
                NSURL *URL = [NSURL URLWithString:photoURL];
                if (URL) {
                    [cell.imgUser sd_setImageWithURL:URL placeholderImage:[UIImage imageNamed:@"btn_profile.png"]];
                }
            }
        }

        
        [cell.lblNotif setText:notif[NotifFieldsContent]];
        
        NSTimeInterval time = [notif[NotifFieldsTime] doubleValue];
        NSString *timeAgo = [Common timeDiffFromNow:time];
        [cell.lblTime setText:timeAgo];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.accessoryType = 0;
       
        return cell;
    }
    return 0;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        
        FIRDataSnapshot *snapshot = [_notifications objectAtIndex:indexPath.row];
        
        [[snapshot ref] removeValue];
        
//        [_notifications removeObjectAtIndex:indexPath.row];
//        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    }
}


@end
