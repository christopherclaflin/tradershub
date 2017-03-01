//
//  SearchViewController.m
//  TraderHub
//
//  Created by imac on 1/4/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "SearchViewController.h"
#import "SearchTableViewCell.h"
#import "PostCollectionViewCell.h"
#import "PostViewController.h"
#import "MessageListViewController.h"
#import "Constants.h"
#import "ProfileViewController.h"
#import "Common.h"

@import Firebase;
@import FirebaseDatabase;
@import FirebaseStorage;
@import FirebaseRemoteConfig;
@import FirebaseAuth;

#define SEARCH_VIEW_MODE_LIST 1
#define SEARCH_VIEW_MODE_GRID 2

@interface SearchViewController () <UITableViewDelegate, UITableViewDataSource, SearchCellDelegate, UISearchBarDelegate,UICollectionViewDelegate, UICollectionViewDataSource, PostGridCellDelegate> {
    FIRDatabaseHandle _refHandle;
}
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIButton *btnList;
@property (weak, nonatomic) IBOutlet UIButton *btnGrid;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *posts;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *filteredPosts;
@property (strong, nonatomic) FIRStorageReference *storageRef;

@end

@implementation SearchViewController {
    int viewMode;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _posts = [NSMutableArray array];
    _filteredPosts = [NSMutableArray array];
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    
    _searchBar.delegate = self;
    
    [self setViewMode:SEARCH_VIEW_MODE_LIST];
    
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor whiteColor]];
    
    NSArray *searchBarSubViews = [[self.searchBar.subviews objectAtIndex:0] subviews];
    for (UIView *view in searchBarSubViews) {
        if([view isKindOfClass:[UITextField class]])
        {
            UITextField *textField = (UITextField*)view;
            UIImageView *imgView = (UIImageView*)textField.leftView;
            imgView.image = [imgView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            imgView.tintColor = [UIColor whiteColor];
            
            UIButton *btnClear = (UIButton*)[textField valueForKey:@"clearButton"];
            [btnClear setImage:[btnClear.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            btnClear.tintColor = [UIColor whiteColor];
            
        }
    }
    [self.searchBar reloadInputViews];

    if(_strSearch)
        _searchBar.text = _strSearch;
    
    [self configureDatabase];
    [self configureStorage];
}

- (void)viewWillAppear {
    
}

- (void)dealloc {
    NSString *path = [NSString stringWithFormat:@"posts"];
    [[_ref child:path] removeObserverWithHandle:_refHandle];
}


- (void)configureStorage {
    NSString *storageUrl = [FIRApp defaultApp].options.storageBucket;
    self.storageRef = [[FIRStorage storage] referenceForURL:[NSString stringWithFormat:@"gs://%@", storageUrl]];
}

- (void)configureDatabase {
    _ref = [[FIRDatabase database] reference];
    // Listen for new messages in the Firebase database
    
    NSString *path = [NSString stringWithFormat:@"posts"];
    
    _refHandle = [[_ref child:path] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
        [_posts removeAllObjects];
        NSEnumerator *userNodes = [snapshot children];
        FIRDataSnapshot *snapshotUserNode;
        while (snapshotUserNode = [userNodes nextObject]) {
            if([snapshotUserNode.key isEqualToString:[FIRAuth auth].currentUser.uid])
                continue; //ignores my post
            
            NSEnumerator *postNodes = [snapshotUserNode children];
            FIRDataSnapshot *postSnapshot;
            
            while (postSnapshot = [postNodes nextObject]) {
                [_posts addObject:postSnapshot];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refresh];
        });
    }];
    
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
- (IBAction)onListClicked:(id)sender {
    [self setViewMode:SEARCH_VIEW_MODE_LIST];
}
- (IBAction)onGridClicked:(id)sender {
    [self setViewMode:SEARCH_VIEW_MODE_GRID];
}

- (void)refresh{
    _strSearch = _searchBar.text;
    [_filteredPosts removeAllObjects];
    
    if([_strSearch isEqualToString:@""]) {
        return;
    }

    for(int i=0; i<_posts.count; i++) {
        FIRDataSnapshot *snapshot = _posts[i];
        
        if(!snapshot.exists)
            continue;
        
        NSDictionary<NSString *, NSString *> *post = snapshot.value;
        
        if([post[PostFieldsContent].lowercaseString containsString:_strSearch.lowercaseString] ||
           [post[PostFieldsUsername].lowercaseString containsString:_strSearch.lowercaseString]) {
            
            //check if private account
            NSMutableArray *array = [Common sharedInstance].privateAccounts;
            for(int i=0; i<array.count; i++) {
                if([post[PostFieldsUid] isEqualToString:array[i]])
                    continue; //if so skip
            }
            
            [_filteredPosts insertObject:snapshot atIndex:0];
        }
        
    }
    
    [_tableView reloadData];
    [_collectionView reloadData];
}
- (void)setViewMode:(int)mode {
    viewMode = mode;
    
    if(viewMode == SEARCH_VIEW_MODE_LIST) {
        [self.tableView setHidden:FALSE];
        [self.collectionView setHidden:TRUE];
    } else {
        [self.collectionView setHidden:FALSE];
        [self.tableView setHidden:TRUE];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    PostViewController *postview = [storyboard instantiateViewControllerWithIdentifier:@"postview"];
    postview.snapshot = [_filteredPosts objectAtIndex:indexPath.row];
    
    [self.navigationController pushViewController:postview animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_filteredPosts count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == _tableView) {
        static NSString *CellIdentifier = @"searchlistcell";
        
        int row = (int)indexPath.row;
        SearchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        FIRDataSnapshot *snapshot = [_filteredPosts objectAtIndex:row];
        [cell setCellData:snapshot];
        cell.delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.accessoryType = 0;
        return cell;
    }
    return 0;
}

#pragma mark - Cell delegates
- (void)didClickOnCellWithData:(id)data {
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

- (void)didClickOnAvatar:(NSString *)uid {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    ProfileViewController *profileview = [storyboard instantiateViewControllerWithIdentifier:@"profileview"];
    profileview.uid = uid;
    profileview.isOther = YES;
    [self.navigationController pushViewController:profileview animated:YES];
}

#pragma mark - Collection View Delegates

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    PostViewController *postview = [storyboard instantiateViewControllerWithIdentifier:@"postview"];
    postview.snapshot = [_filteredPosts objectAtIndex:indexPath.row];
    
    [self.navigationController pushViewController:postview animated:YES];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _filteredPosts.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"postgridcell";
    
    PostCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    [cell setCellData:[_filteredPosts objectAtIndex:indexPath.row]];
    cell.delegate = self;
    
    return cell;
}

- (void)didClickOnGridCellWithData:(id)data {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    PostViewController *postview = [storyboard instantiateViewControllerWithIdentifier:@"postview"];
    postview.snapshot = data;
    
    [self.navigationController pushViewController:postview animated:YES];
}

#pragma mark GridCell
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [self refresh];
    
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self view] endEditing:YES];
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
