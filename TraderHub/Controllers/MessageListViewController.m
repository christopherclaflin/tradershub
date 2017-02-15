//
//  MessageListViewController.m
//  TraderHub
//
//  Created by imac on 1/5/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "MessageListViewController.h"
#import "Constants.h"
#import "MessageViewController.h"
#import "MessageListTableViewCell.h"
#import "SVProgressHUD.h"

@import Firebase;
@import FirebaseAuth;
@import FirebaseStorage;
@import FirebaseDatabase;

@interface MessageListViewController () <UITableViewDelegate, UITableViewDataSource>{
    FIRDatabaseHandle _refHandle, _refHandleDelete;
}

@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *channels;
@property (strong, nonatomic) FIRStorageReference *storageRef;
@property (weak, nonatomic) IBOutlet UITableView *table;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;


@end

@implementation MessageListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _channels = [NSMutableArray array];
    
    [self configureDatabase];
    [self configureStorage];
}

- (void)dealloc {
    
    NSString *path = [NSString stringWithFormat:@"messages/%@", [FIRAuth auth].currentUser.uid];
    [[_ref child:path] removeObserverWithHandle:_refHandle];
    [[_ref child:path] removeObserverWithHandle:_refHandleDelete];
}

- (void)viewWillAppear:(BOOL)animated {
    
    
    if(_targetUID) {
        [SVProgressHUD show];
        NSString *uid = [_targetUID copy];
        _targetUID = nil;
        
        [[[_ref child:@"users"] child:uid] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            if(snapshot.exists) {
                NSDictionary *info = snapshot.value;
                NSString *userDisplayName = info[UserFieldsDisplayname];
                NSString *userPhotoURL = info[UserFieldsPhotoURL];
                
                FIRDatabaseReference *r = [[[_ref child:@"messages"] child:[FIRAuth auth].currentUser.uid] child:uid];
                [[r child:ChannelFieldsName] setValue:userDisplayName];
                [[r child:ChannelFieldsPhotoURL] setValue:userPhotoURL];
                
                
                [[[[_ref child:@"messages"] child:[FIRAuth auth].currentUser.uid] child:uid] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        // time-consuming task
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [SVProgressHUD dismiss];
                            
                            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                            
                            MessageViewController *msgview = [storyboard instantiateViewControllerWithIdentifier:@"msgview"];
                            msgview.snapshot = snapshot;
                            msgview.opponentPhotoURL = userPhotoURL;
                            msgview.opponentDisplayName = userDisplayName;
                            msgview.opponentUID = uid;
                            
                            //                    [self.navigationController pushViewController:msgview animated:YES];
                            [self presentViewController:msgview animated:YES completion:nil];
                            
                        });
                    });
                }];
            }
        }];
        
        
    }
}
- (void)configureStorage {
    NSString *storageUrl = [FIRApp defaultApp].options.storageBucket;
    self.storageRef = [[FIRStorage storage] referenceForURL:[NSString stringWithFormat:@"gs://%@", storageUrl]];
}

- (void)configureDatabase {
    _ref = [[FIRDatabase database] reference];
    // Listen for new messages in the Firebase database
    
    NSString *path = [NSString stringWithFormat:@"messages/%@", [FIRAuth auth].currentUser.uid];
    
    _refHandle = [[_ref child:path] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        
        NSDictionary *dic = snapshot.value;
        
        if(snapshot.exists && dic && [dic objectForKey:ChannelFieldsName]
           && [[dic objectForKey:ChannelFieldsName] length] > 0) {
            [_channels addObject:snapshot];
            [_table insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_channels.count-1 inSection:0]] withRowAnimation: UITableViewRowAnimationAutomatic];
        }       
        
    }];
    
    _refHandleDelete = [[_ref child:path] observeEventType:FIRDataEventTypeChildRemoved  withBlock:^(FIRDataSnapshot *snapshot) {
        int index = [self indexOfChannels:snapshot];
        [_channels removeObjectAtIndex:index];
        [_table deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

- (int)indexOfChannels:(FIRDataSnapshot *)snapshot {
    for(int i=0; i<_channels.count; i++) {
        FIRDataSnapshot *aSnapshot = _channels[i];
        if([aSnapshot.key isEqualToString:snapshot.key])
            return i;
    }
    return 0;
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
- (IBAction)onBackClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:TRUE];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    FIRDataSnapshot *snapshot = _channels[indexPath.row];
    MessageViewController *msgview = [storyboard instantiateViewControllerWithIdentifier:@"msgview"];
    msgview.snapshot = snapshot;
    
    NSDictionary *channelInfo = snapshot.value;
    msgview.opponentPhotoURL = channelInfo[ChannelFieldsPhotoURL];
    msgview.opponentDisplayName = channelInfo[ChannelFieldsName];
    msgview.opponentUID = [snapshot key];
    
    [self presentViewController:msgview animated:YES completion:nil];
//    [self.navigationController pushViewController:msgview animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_channels count];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return YES;
}
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        
        FIRDataSnapshot *snapshot = [_channels objectAtIndex:indexPath.row];
        
        [[snapshot ref] removeValue];
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 70.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == _table) {
        
        static NSString *CellIdentifier = @"messagelistcell";
        
        int row = (int)indexPath.row;
        MessageListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        // Unpack message from Firebase DataSnapshot
        FIRDataSnapshot *snapshot = _channels[row];
        [cell setCellData:snapshot];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.accessoryType = 0;
        
        return cell;
    }
    return nil;
}

@end
