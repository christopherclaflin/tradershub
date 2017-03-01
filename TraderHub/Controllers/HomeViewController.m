//
//  HomeViewController.m
//  TraderHub
//
//  Created by imac on 1/3/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "HomeViewController.h"
//#import "HomeTableViewCell.h"
#import "MessageListViewController.h"
#import "Post.h"
#import "PostViewController.h"
#import "Constants.h"
#import "Common.h"
#import "ProfileViewController.h"
#import "M13BadgeView/M13BadgeView.h"
#import "CollectionViewCell.h"
#import "HeaderCollectionViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>

@import Firebase;
@import FirebaseDatabase;
@import FirebaseStorage;
@import FirebaseRemoteConfig;
@import FirebaseAuth;

@interface HomeViewController () <UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, FeedCollectionCellDelegate, FeedCollectionHeaderDelegate> {
    FIRDatabaseHandle _refHandle, _refHandleDelete;
    FIRDatabaseHandle _refHandleMsg;
    FIRDatabaseHandle _refHandleNotifAdd, _refHandleNotifDelete;
    CGRect rectBadage;
}

@property (weak, nonatomic) IBOutlet UITableView *table;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *btnMessage;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *feeds;

@property (strong, nonatomic) FIRStorageReference *storageRef;
@property (nonatomic, strong) FIRRemoteConfig *remoteConfig;

@property (retain, nonatomic) M13BadgeView *badgeView;


@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    _table.delegate = self;
//    _table.dataSource = self;
    
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    
    [_collectionView registerNib:[UINib nibWithNibName:@"CollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"feedcontentcell"];
    [_collectionView registerNib:[UINib nibWithNibName:@"HeaderCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"feedheadercell"];
    
    [self initData];
    
    [self configureDatabase];
    [self configureStorage];
    [self configureRemoteConfig];
    [self fetchConfig];
    
    [self initBadge];
}

- (void)dealloc {
    [[_ref child:@"feeds"] removeObserverWithHandle:_refHandle];
}

- (void)configureDatabase {
    _ref = [[FIRDatabase database] reference];
    // Listen for new messages in the Firebase database
    
    NSString *path = [NSString stringWithFormat:@"feeds/%@", [FIRAuth auth].currentUser.uid];
    
    _refHandle = [[_ref child:path] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        [_feeds insertObject:snapshot atIndex:0];
//        [_table insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation: UITableViewRowAnimationAutomatic];
        
        [_collectionView reloadData];
    }];
    
    //observe server time offset
    [[_ref child:@".info/serverTimeOffset"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSLog(@"%@", snapshot.value);
        [Common sharedInstance].timeOffset = [snapshot.value intValue];
    }];
    
    //observe notifications count
    [[[_ref child:@"notifications"] child:[FIRAuth auth].currentUser.uid] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        int count = 0;
        
        NSEnumerator *children = [snapshot children];
        FIRDataSnapshot *child;
        while (child = [children nextObject]) {
            NSDictionary *dic = child.value;
            if(child.exists && [dic objectForKey:NotifFieldsRead]) {
                if([[dic objectForKey:NotifFieldsRead] boolValue])
                    //if read, skip
                    continue;
                count++;
            }
        }

        if(count == 0)
            [[super.tabBarController.viewControllers objectAtIndex:3] tabBarItem].badgeValue = nil;
        else
            [[super.tabBarController.viewControllers objectAtIndex:3] tabBarItem].badgeValue = [NSString stringWithFormat:@"%d", count];
    }];
    
    //Common Settings
    NSString *myID = [FIRAuth auth].currentUser.uid;
    
    path = [NSString stringWithFormat:@"settings/notifications/%@", myID];
    
    _refHandleNotifAdd = [[_ref child:path] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        if(snapshot.exists) {
            NSString *userID = snapshot.value;
            [[Common sharedInstance] turnOnNotifForUser:userID];
        }
    }];
    
    _refHandleNotifDelete = [[_ref child:path] observeEventType:FIRDataEventTypeChildRemoved withBlock:^(FIRDataSnapshot *snapshot) {
        if(snapshot.exists) {
            NSString *userID = snapshot.value;
            [[Common sharedInstance] turnOffNotifForUser:userID];
        }
    }];
    
    //Custom Fields
    
    path = [NSString stringWithFormat:@"settings/custom/forex/%@", myID];
    [[_ref child:path] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSString *value = snapshot.value;
        [[Common sharedInstance].customForexList addObject:value];
    }];
    
    path = [NSString stringWithFormat:@"settings/custom/futures/%@", myID];
    [[_ref child:path] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSString *value = snapshot.value;
        [[Common sharedInstance].customFuturesList addObject:value];
    }];
    
    path = [NSString stringWithFormat:@"settings/custom/stock/%@", myID];
    [[_ref child:path] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSString *value = snapshot.value;
        [[Common sharedInstance].customStockList addObject:value];
    }];
    
    path = [NSString stringWithFormat:@"settings/privates"];
    [[_ref child:path] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSString *value = snapshot.key;
        [[Common sharedInstance].privateAccounts addObject:value];
    }];
    
    [[_ref child:path] observeEventType:FIRDataEventTypeChildRemoved withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSString *value = snapshot.key;
        NSMutableArray *array = [Common sharedInstance].privateAccounts;
        for(int i=0; i<array.count; i++) {
            if([array[i] isEqualToString:value]) {
                [array removeObjectAtIndex:i];
                return;
            }
        }
    }];
    
    path = [NSString stringWithFormat:@"followings/%@", myID];
    
    [[_ref child:path] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSString *value = snapshot.key;
        [[Common sharedInstance].followings addObject:value];
    }];
    
    [[_ref child:path] observeEventType:FIRDataEventTypeChildRemoved withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSString *value = snapshot.key;
        NSMutableArray *array = [Common sharedInstance].followings;
        for(int i=0; i<array.count; i++) {
            if([array[i] isEqualToString:value]) {
                [array removeObjectAtIndex:i];
                return;
            }
        }
    }];

}

- (void)initBadge{
    CGRect rectMsg = _btnMessage.layer.frame;
    rectBadage = CGRectMake(rectMsg.origin.x + rectMsg.size.width - 20, rectMsg.origin.y - 5, 20, 20);
    
    _badgeView = [[M13BadgeView alloc] initWithFrame:rectBadage];
    _badgeView.text = @"";
    _badgeView.layer.frame = rectBadage;
    [_headerView addSubview:_badgeView];
    _badgeView.hidden = YES;
    
    NSString *path = [NSString stringWithFormat:@"messages/%@", [FIRAuth auth].currentUser.uid];
    _refHandleMsg = [[_ref child:path] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
        int unreads = 0;
        
        NSEnumerator *oppoNodes = [snapshot children];
        FIRDataSnapshot *oppoSnapshot;
        while(oppoSnapshot = [oppoNodes nextObject]) {
            NSDictionary *dic = oppoSnapshot.value;
            
            if(oppoSnapshot.exists && dic[ChannelFieldsUnreads]) {
                unreads += [dic[ChannelFieldsUnreads] intValue];
            }
    
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(unreads == 0) {
                _badgeView.hidden = YES;
            } else {
                _badgeView.text = [NSString stringWithFormat:@"%d", unreads];
                _badgeView.layer.frame = rectBadage;
                _badgeView.hidden = NO;
            }
        });
    }];
}

- (void)configureStorage {
    NSString *storageUrl = [FIRApp defaultApp].options.storageBucket;
    self.storageRef = [[FIRStorage storage] referenceForURL:[NSString stringWithFormat:@"gs://%@", storageUrl]];
}

- (void)configureRemoteConfig {
    _remoteConfig = [FIRRemoteConfig remoteConfig];
    // Create Remote Config Setting to enable developer mode.
    // Fetching configs from the server is normally limited to 5 requests per hour.
    // Enabling developer mode allows many more requests to be made per hour, so developers
    // can test different config values during development.
    FIRRemoteConfigSettings *remoteConfigSettings = [[FIRRemoteConfigSettings alloc] initWithDeveloperModeEnabled:YES];
    self.remoteConfig.configSettings = remoteConfigSettings;
}

- (void)fetchConfig {
//    long expirationDuration = 3600;
//    // If in developer mode cacheExpiration is set to 0 so each fetch will retrieve values from
//    // the server.
//    if (self.remoteConfig.configSettings.isDeveloperModeEnabled) {
//        expirationDuration = 0;
//    }
//    
//    // cacheExpirationSeconds is set to cacheExpiration here, indicating that any previously
//    // fetched and cached config would be considered expired because it would have been fetched
//    // more than cacheExpiration seconds ago. Thus the next fetch would go to the server unless
//    // throttling is in progress. The default expiration duration is 43200 (12 hours).
//    [self.remoteConfig fetchWithExpirationDuration:expirationDuration completionHandler:^(FIRRemoteConfigFetchStatus status, NSError *error) {
//        if (status == FIRRemoteConfigFetchStatusSuccess) {
//            NSLog(@"Config fetched!");
//            [_remoteConfig activateFetched];
//            FIRRemoteConfigValue *friendlyMsgLength = _remoteConfig[@"friendly_msg_length"];
//            if (friendlyMsgLength.source != FIRRemoteConfigSourceStatic) {
//                _msglength = friendlyMsgLength.numberValue.intValue;
//                NSLog(@"Friendly msg length config: %d", _msglength);
//            }
//        } else {
//            NSLog(@"Config not fetched");
//            NSLog(@"Error %@", error);
//        }
//    }];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    FIRDataSnapshot *snapshot = _feeds[indexPath.row];
    PostViewController *postview = [storyboard instantiateViewControllerWithIdentifier:@"postview"];
    postview.snapshot = snapshot;
    
    [self.navigationController pushViewController:postview animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_feeds count];
}


//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (tableView == _table) {
//        
//        static NSString *CellIdentifier = @"hometablecell";
//        
//        int row = (int)indexPath.row;
//        HomeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//
//        // Unpack message from Firebase DataSnapshot
//        FIRDataSnapshot *feedSnapshot = _feeds[row];
//        [cell setCellData:feedSnapshot];
//        
//        cell.delegate = self;
//        cell.selectionStyle = UITableViewCellSelectionStyleNone;
//        
//        cell.accessoryType = 0;
//        
//        return cell;
//    }
//    return nil;
//}

- (void)initData{
    _feeds = [NSMutableArray array];
    [Common sharedInstance].notifSettings = [NSMutableArray array];
    [Common sharedInstance].customForexList = [NSMutableArray arrayWithObjects:@"EUR/USD", @"USD/JPY", @"GBP/USD", @"USD/CHF", @"AUD/USD", @"USD/CAD", @"NZD/USD", nil];
    [Common sharedInstance].customFuturesList = [NSMutableArray arrayWithObjects:@"S&P 500", @"Dow", @"NASDAQ", @"Russel", @"Dollar Index", @"Gold", @"30 Yr Bond", @"Crude Oil", nil];
    [Common sharedInstance].customStockList = [NSMutableArray array];
    [Common sharedInstance].privateAccounts = [NSMutableArray array];
    [Common sharedInstance].followings = [NSMutableArray array];
}




- (IBAction)onMessagesClicked:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    MessageListViewController *msgview = [storyboard instantiateViewControllerWithIdentifier:@"messagelistview"];
    [self.navigationController pushViewController:msgview animated:YES];
}

- (void)didClickOnAvatar:(NSString *)uid {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    ProfileViewController *profileview = [storyboard instantiateViewControllerWithIdentifier:@"profileview"];
    profileview.uid = uid;
    
    if([uid isEqualToString:[FIRAuth auth].currentUser.uid]) {
        profileview.isOther = NO;
    } else {
        profileview.isOther = YES;
    }
    [self.navigationController pushViewController:profileview animated:YES];
}

#pragma mark - Collection View Delegates

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 2;
}

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _feeds.count + 1;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    FIRDataSnapshot *snapshot = _feeds[indexPath.section - 1];
    PostViewController *postview = [storyboard instantiateViewControllerWithIdentifier:@"postview"];
    postview.snapshot = snapshot;
    
    [self.navigationController pushViewController:postview animated:YES];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    long row = indexPath.section;
    long col = indexPath.row;
    
    if(row == 0) {
        if(col == 0) { //header
            HeaderCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"feedheadercell" forIndexPath:indexPath];
//            cell.imgUserWidthConstraint.constant = 0;
            cell.lblUsername.text = @"Signal";
            cell.imgUser.image = nil;
            
            return cell;
        } else {
            CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"feedcontentcell" forIndexPath:indexPath];
            
            cell.btnMore.hidden = YES;
            
            cell.lblMarket.text = @"Market";
            [cell.imgIncDec setImage:[UIImage imageNamed:@"ic_incdec.png"]];
            cell.lblEntry.text = @"Entry";
            cell.lblStop.text = @"Stop";
            cell.lblTarget.text = @"Target";
            cell.lblType.text = @"Type";
            
            return cell;
        }
    } else {
        if(col == 0) {
            HeaderCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"feedheadercell" forIndexPath:indexPath];
            cell.imgUserWidthConstraint.constant = 30;
            
            FIRDataSnapshot *feedSnapshot = _feeds[row-1];
            NSDictionary *dic = feedSnapshot.value;
            cell.lblUsername.text = dic[PostFieldsUsername];
            cell.userID = dic[PostFieldsUid];
            cell.delegate = self;
            
            NSString *photoURL = dic[PostFieldsPhotoUrl];
            if (photoURL) {
                if([photoURL containsString:@"gs://"]) {
                    [[[FIRStorage storage] referenceForURL:photoURL] downloadURLWithCompletion:^(NSURL * _Nullable URL, NSError * _Nullable error) {
                        if(URL){
                            [cell.imgUser sd_setImageWithURL:URL placeholderImage:[UIImage imageNamed:@"avatar.png"]];
                        }
                    }];
                } else {
                    NSURL *URL = [NSURL URLWithString:photoURL];
                    if (URL) {
                        [cell.imgUser sd_setImageWithURL:URL placeholderImage:[UIImage imageNamed:@"avatar.png"]];
                    }
                }
            } else {
                [cell.imgUser setImage:[UIImage imageNamed:@"avatar.png"]];
            }
            
            
            return cell;
        } else {
            
            CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"feedcontentcell" forIndexPath:indexPath];
            
            cell.btnMore.hidden = NO;
            
            FIRDataSnapshot *feedSnapshot = _feeds[row-1];
            NSDictionary *dic = feedSnapshot.value;
            
            cell.lblMarket.text = dic[PostFieldsMarket];
            
            BOOL isSell = [dic[PostFieldsIsSell] boolValue];
            if(!isSell) {
                [cell.imgIncDec setImage:[UIImage imageNamed:@"ic_inc.png"]];
            } else {
                [cell.imgIncDec setImage:[UIImage imageNamed:@"ic_dec.png"]];
            }
            
            cell.lblEntry.text = dic[PostFieldsEntry];
            cell.lblStop.text = dic[PostFieldsStop];
            BOOL isTargetOn = [dic[PostFieldsIsTargetOn] boolValue];
            
            if(isTargetOn) {
                NSNumber *target = dic[PostFieldsTarget];
                cell.lblTarget.text = [NSString stringWithFormat:@"%.2f", target.floatValue];
            } else {
                cell.lblTarget.text = @"#";
            }
            
            cell.lblType.text = dic[PostFieldsType];
            cell.data = feedSnapshot;
            cell.delegate = self;
            
            return cell;            
        }
    }
    
    return nil;
}

////collection content cell delegate
//- (void) onMoreClicked:(id)data {
//    
//}

- (void)onMoreClicked:(id)data {
    FIRDataSnapshot *snapshot = data;
    
    NSDictionary *post;
    NSString *uid;
    
    if(!snapshot.exists) {
        NSLog(@"Cell snapshot value not exist");
        return;
    }
    
    post = snapshot.value;
    uid = post[PostFieldsUid];
    
    BOOL isNotifTurnedOn = [[Common sharedInstance] isNotifTurnedOnForUser:uid];
    
    UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:nil
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
    //Create an action
    UIAlertAction *sendMessage = [UIAlertAction actionWithTitle:@"Send Message"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action)
                                  {
                                      NSLog(@"Send Message");
                                      
                                      
                                      UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                      
                                      MessageListViewController *messagelistview = [storyboard instantiateViewControllerWithIdentifier:@"messagelistview"];
                                      messagelistview.targetUID = uid;
                                      [self.navigationController pushViewController:messagelistview animated:YES];
                                      
                                  }];
    UIAlertAction *viewPost = [UIAlertAction actionWithTitle:@"View Post"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action)
                               {
                                   NSLog(@"View Post");
                                   UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                   
                                   PostViewController *postview = [storyboard instantiateViewControllerWithIdentifier:@"postview"];
                                   postview.snapshot = snapshot;
                                   
                                   [self.navigationController pushViewController:postview animated:YES];
                                   //                                       [self presentViewController:postview animated:YES completion:nil];
                               }];
    
    NSString *title = isNotifTurnedOn ? @"Turn Off Notifications" : @"Turn On Notifications";
    
    UIAlertAction *turnOnNotif = [UIAlertAction actionWithTitle:title
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action)
                                  {
                                      if(isNotifTurnedOn) {
                                          [[Common sharedInstance] turnOffNotifForUser:uid];
                                      } else {
                                          [[Common sharedInstance] turnOnNotifForUser:uid];
                                      }
                                  }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction *action)
                             {
                                 NSLog(@"Cancel");
                             }];
    
    
    //Add action to alertCtrl
    [alertCtrl addAction:sendMessage];
    [alertCtrl addAction:viewPost];
    [alertCtrl addAction:turnOnNotif];
    [alertCtrl addAction:cancel];
    
    [self presentViewController:alertCtrl animated:YES completion:nil];
}

@end
