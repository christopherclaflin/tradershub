//
//  ProfileViewController.m
//  TraderHub
//
//  Created by imac on 1/5/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "ProfileViewController.h"
#import "OptionsViewController.h"
#import "ProfileEditViewController.h"
#import "MessageListViewController.h"
#import "KILabel.h"
#import "Constants.h"
#import "PostViewController.h"
#import "ProfileTableViewCell.h"
#import "Common.h"
#import "PostCollectionViewCell.h"


#import <SDWebImage/UIImageView+WebCache.h>

@import Firebase;
@import FirebaseDatabase;
@import FirebaseStorage;
@import FirebaseRemoteConfig;
@import FirebaseAuth;

@interface ProfileViewController () <UITableViewDelegate, UITableViewDataSource, PostGridCellDelegate, UICollectionViewDelegate, UICollectionViewDataSource> {
    FIRDatabaseHandle _refHandle, _refHandleDelete;
}
@property (weak, nonatomic) IBOutlet UIButton *btnBack;
@property (weak, nonatomic) IBOutlet UIButton *btnMore;
@property (weak, nonatomic) IBOutlet UILabel *lblUsername;
@property (weak, nonatomic) IBOutlet UIButton *btnOption;
@property (weak, nonatomic) IBOutlet UIImageView *imgUser;
@property (weak, nonatomic) IBOutlet UIButton *btnFollow;
@property (weak, nonatomic) IBOutlet UIButton *btnEditProfile;
@property (weak, nonatomic) IBOutlet UIButton *btnGrid;
@property (weak, nonatomic) IBOutlet UIButton *btnList;
@property (weak, nonatomic) IBOutlet UITableView *table;
@property (weak, nonatomic) IBOutlet UICollectionView *collection;


@property (weak, nonatomic) IBOutlet UILabel *lblPosts;
@property (weak, nonatomic) IBOutlet UILabel *lblFollowers;
@property (weak, nonatomic) IBOutlet UILabel *lblFollowing;
@property (weak, nonatomic) IBOutlet KILabel *lblDesc;

@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *posts;
@property (strong, nonatomic) FIRStorageReference *storageRef;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _imgUser.layer.cornerRadius = _imgUser.layer.frame.size.width / 2;
    _imgUser.clipsToBounds = YES;
    
    _posts = [NSMutableArray array];
    
    _collection.delegate = self;
    _collection.dataSource = self;
    
    [self toggleProfile];
    
    [self configureDatabase];
    [self configureStorage];
}

- (NSString *)targetUid {
    if(_isOther) {
        return _uid;
    } else {
        return [FIRAuth auth].currentUser.uid;
    }
}

- (void)dealloc {
    NSString *uid = [self targetUid];
    
    if(uid == nil) {
        NSLog(@"ProfileView - user id is nil");
        return;
    }
    
    NSString *path = [NSString stringWithFormat:@"posts/%@", uid];
    
    [[_ref child:path] removeObserverWithHandle:_refHandle];
}

- (void)configureDatabase {
    _ref = [[FIRDatabase database] reference];
    // Listen for new messages in the Firebase database
    NSString *userID = [self targetUid];
    
    if(userID == nil) {
        NSLog(@"ProfileView - user id is nil");
        return;
    }
    
    _refHandle = [[[_ref child:@"posts"] child:userID] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        [_posts insertObject:snapshot atIndex:0];
        [_table insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation: UITableViewRowAnimationAutomatic];
        [_collection reloadData];
    }];
    
    _refHandleDelete = [[[_ref child:@"posts"] child:userID] observeEventType:FIRDataEventTypeChildRemoved  withBlock:^(FIRDataSnapshot *snapshot) {
        int index = [self indexOfPost:snapshot];
        [_posts removeObjectAtIndex:index];
        [_table deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
        [_collection reloadData];
    }];
    
    
    [[[_ref child:@"followers"] child:userID] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        _lblFollowers.text = [NSString stringWithFormat:@"%lu", (unsigned long)snapshot.childrenCount];
    } withCancelBlock:^(NSError * _Nonnull error) {
        NSLog(@"%@", error.localizedDescription);
    }];
    
    [[[_ref child:@"followings"] child:userID] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        _lblFollowing.text = [NSString stringWithFormat:@"%lu", (unsigned long)snapshot.childrenCount];
    } withCancelBlock:^(NSError * _Nonnull error) {
        NSLog(@"%@", error.localizedDescription);
    }];
}

- (int)indexOfPost:(FIRDataSnapshot *)snapshot {
    for(int i=0; i<_posts.count; i++) {
        FIRDataSnapshot *aSnapshot = _posts[i];
        if([aSnapshot.key isEqualToString:snapshot.key])
            return i;
    }
    return 0;
}

- (void)viewWillAppear:(BOOL)animated {
    NSString *userID = [self targetUid];
    
    if(userID == nil) {
        NSLog(@"ProfileView - user id is nil");
        return;
    }
    BOOL isFollowing = [[Common sharedInstance] isFollowing:_uid];
    if(isFollowing) {
        [_btnFollow setTitle:@"Following" forState:UIControlStateNormal];
    } else {
        [_btnFollow setTitle:@"Follow" forState:UIControlStateNormal];
    }
    
    [[[_ref child:@"users"] child:userID] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        NSDictionary *userInfo = snapshot.value;
        
        if(!snapshot.exists)
            return;
        
        NSString *bio = userInfo[UserFieldsBio];
        NSString *website = userInfo[UserFieldsWebsite];
        NSString *displayName = userInfo[UserFieldsDisplayname];
        
        if(bio == nil) {
            bio = @"";
        }
        
        if(website == nil) {
            website = @"";
        }
        
        NSString *desc = [NSString stringWithFormat:@"%@\n%@\n%@", displayName, bio, website];
        _lblDesc.text = desc;
        _lblUsername.text = displayName;
        
        NSString *photoURL = userInfo[UserFieldsPhotoURL];
        if (photoURL) {
            if([photoURL containsString:@"gs://"]) {
                [[[FIRStorage storage] referenceForURL:photoURL] downloadURLWithCompletion:^(NSURL * _Nullable URL, NSError * _Nullable error) {
                    if(URL){
                        [_imgUser sd_setImageWithURL:URL placeholderImage:[UIImage imageNamed:@"avatar.png"]];
                    }
                }];
            } else {
                NSURL *URL = [NSURL URLWithString:photoURL];
                if (URL) {
                    [_imgUser sd_setImageWithURL:URL placeholderImage:[UIImage imageNamed:@"avatar.png"]];
                }
            }
        }
        
    } withCancelBlock:^(NSError * _Nonnull error) {
        NSLog(@"%@", error.localizedDescription);
    }];

}

- (void)configureStorage {
    NSString *storageUrl = [FIRApp defaultApp].options.storageBucket;
    self.storageRef = [[FIRStorage storage] referenceForURL:[NSString stringWithFormat:@"gs://%@", storageUrl]];
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

- (void)toggleProfile {
    if(_isOther) {
        [_btnOption setHidden:YES];
        [_btnEditProfile setHidden:YES];
        [_btnBack setHidden:NO];
        [_btnFollow setHidden:NO];
        [_btnMore setHidden:NO];
    } else {
        [_btnBack setHidden:YES];
        [_btnFollow setHidden:YES];
        [_btnMore setHidden:YES];
        [_btnOption setHidden:NO];
        [_btnEditProfile setHidden:NO];
    }
}

- (IBAction)onBackClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
- (IBAction)onMoreClicked:(id)sender {
    //if other's profile
    if(!_isOther)
        return;
    
    BOOL isNotifTurnedOn = [[Common sharedInstance] isNotifTurnedOnForUser:_uid];
    
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
                                      messagelistview.targetUID = _uid;
                                      [self.navigationController pushViewController:messagelistview animated:YES];
                                      
                                  }];
    
    BOOL isFollowing = [[Common sharedInstance] isFollowing:_uid];
    NSString *title = isFollowing ? @"Unfollow" : @"Follow";
    
    UIAlertAction *followAction = [UIAlertAction actionWithTitle:title
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action)
                               {
                                   if(isFollowing) {
                                       UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:nil
                                                                                                          message:nil
                                                                                                   preferredStyle:UIAlertControllerStyleActionSheet];
                                       //Create an action
                                       
                                       UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"Unfollow"
                                                                                             style:UIAlertActionStyleDestructive
                                                                                           handler:^(UIAlertAction *action)
                                                                     {
                                                                         [[Common sharedInstance] unfollow:_uid];
                                                                         [self.btnFollow setTitle:@"Follow" forState:UIControlStateNormal];
                                                                     }];
                                       
                                       UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                                                        style:UIAlertActionStyleCancel
                                                                                      handler:^(UIAlertAction *action)
                                                                {
                                                                    
                                                                }];
                                       
                                       
                                       //Add action to alertCtrl
                                       [alertCtrl addAction:alertAction];
                                       [alertCtrl addAction:cancel];
                                       
                                       [self presentViewController:alertCtrl animated:YES completion:nil];
                                   }
                                   else {
                                       [[Common sharedInstance] follow:self.uid];
                                       [self.btnFollow setTitle:@"Following" forState:UIControlStateNormal];
                                   }
                               }];
    
    title = isNotifTurnedOn ? @"Turn Off Notifications" : @"Turn On Notifications";
    UIAlertAction *turnOnNotif = [UIAlertAction actionWithTitle:title
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action)
                                  {
                                      NSLog(@"Turn On Notifications");
                                  }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction *action)
                             {
                                 NSLog(@"Cancel");
                             }];
    
    
    //Add action to alertCtrl
    [alertCtrl addAction:sendMessage];
    [alertCtrl addAction:followAction];
    [alertCtrl addAction:turnOnNotif];
    [alertCtrl addAction:cancel];
    
    [self presentViewController:alertCtrl animated:YES completion:nil];
}
- (IBAction)onOptionClicked:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    OptionsViewController *optionview = [storyboard instantiateViewControllerWithIdentifier:@"optionsview"];
    [self.navigationController pushViewController:optionview animated:YES];
}
- (IBAction)onFollowClicked:(id)sender {
    BOOL isFollowing = [[Common sharedInstance] isFollowing:_uid];
    
    if(isFollowing) {
        UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:nil
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
        //Create an action
        
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"Unfollow"
                                                                  style:UIAlertActionStyleDestructive
                                                                handler:^(UIAlertAction *action)
                                          {
                                              [[Common sharedInstance] unfollow:_uid];
                                              [self.btnFollow setTitle:@"Follow" forState:UIControlStateNormal];
                                          }];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction *action)
                                 {
                                     
                                 }];
        
        
        //Add action to alertCtrl
        [alertCtrl addAction:alertAction];
        [alertCtrl addAction:cancel];
        
        [self presentViewController:alertCtrl animated:YES completion:nil];
        
    } else {
        [[Common sharedInstance] follow:_uid];
        [self.btnFollow setTitle:@"Following" forState:UIControlStateNormal];
    }
    
}
- (IBAction)onEditProfile:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    ProfileEditViewController *editview = [storyboard instantiateViewControllerWithIdentifier:@"profileeditview"];
    [self.navigationController pushViewController:editview animated:YES];
    
}
- (IBAction)onListView:(id)sender {
    [_table setHidden:NO];
    [_collection setHidden:YES];
}
- (IBAction)onGridView:(id)sender {
    [_table setHidden:YES];
    [_collection setHidden:NO];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    PostViewController *postview = [storyboard instantiateViewControllerWithIdentifier:@"postview"];
    
    postview.snapshot = [_posts objectAtIndex:indexPath.row];
    
    [self.navigationController pushViewController:postview animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_posts count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == _table) {
        
        static NSString *CellIdentifier = @"profiletablecell";
        
        int row = (int)indexPath.row;
        ProfileTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        // Unpack message from Firebase DataSnapshot
        FIRDataSnapshot *postSnapshot = _posts[row];
       
        [cell setCellData:postSnapshot];
        
        cell.accessoryType = 0;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell;
    }
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    if(_isOther)
        return NO;
    else
        return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        
        FIRDataSnapshot *snapshot = [_posts objectAtIndex:indexPath.row];
        
        [[snapshot ref] removeValue];
    }
}

#pragma mark - Collection View Delegates

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    PostViewController *postview = [storyboard instantiateViewControllerWithIdentifier:@"postview"];
    postview.snapshot = [_posts objectAtIndex:indexPath.row];
    
    [self.navigationController pushViewController:postview animated:YES];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _posts.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"postgridcell";
    
    PostCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    [cell setCellData:[_posts objectAtIndex:indexPath.row]];
    cell.delegate = self;
    
    return cell;
}

- (void)didClickOnGridCellWithData:(id)data {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    PostViewController *postview = [storyboard instantiateViewControllerWithIdentifier:@"postview"];
    postview.snapshot = data;
    
    [self.navigationController pushViewController:postview animated:YES];
}

#pragma mark Collection view layout things
// Layout: Set cell size
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGRect rtCollection = collectionView.frame;
    
    CGSize mElementSize = CGSizeMake(rtCollection.size.width/3, rtCollection.size.width/3);
    return mElementSize;
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0.0;
}

// Layout: Set Edges
- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    // return UIEdgeInsetsMake(0,8,0,8);  // top, left, bottom, right
    return UIEdgeInsetsMake(0,0,0,0);  // top, left, bottom, right
}

@end
