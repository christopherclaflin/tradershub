//
//  PostViewController.m
//  TraderHub
//
//  Created by imac on 1/5/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "PostViewController.h"
#import "MessageListViewController.h"
#import "KILabel.h"
#import "SearchViewController.h"
#import "Constants.h"
#import "Common.h"
#import "PostViewPostCell.h"
#import "PostViewCommentCell.h"
#import "ProfileViewController.h"

#import <SDWebImage/UIImageView+WebCache.h>

@import Firebase;
@import FirebaseStorage;
@import FirebaseAuth;

@interface PostViewController () <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, CommentCellDelegate> {
    NSString *postID;
    FIRDatabaseHandle _refHandle;
}
@property (weak, nonatomic) IBOutlet UIView *viewNewComment;
@property (weak, nonatomic) IBOutlet UIImageView *imgUser;
@property (weak, nonatomic) IBOutlet UILabel *lblUsername;
@property (weak, nonatomic) IBOutlet UITextField *txtNewComment;
@property (weak, nonatomic) IBOutlet UIButton *btnMore;

@property (weak, nonatomic) IBOutlet UITableView *table;

@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *comments;
@property (strong, nonatomic) FIRStorageReference *storageRef;

@end

@implementation PostViewController {
    BOOL keyboardMovedUp;
    CGRect keyboardFrame;
    CGRect lastFrame;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    keyboardMovedUp = NO;
    
    _imgUser.layer.cornerRadius = _imgUser.layer.frame.size.width / 2;
    _imgUser.clipsToBounds = YES;
    
    postID = _snapshot.key;
    _comments = [NSMutableArray array];
    
    _table.delegate = self;
    _table.dataSource = self;
    
    [self configureDatabase];
    [self configureStorage];

    
    [self initUI];
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
    [self.navigationController popViewControllerAnimated:YES];
}
- (IBAction)onMoreClicked:(id)sender {
    NSDictionary *post;
    NSString *uid;
    
    if(_snapshot.exists) {
        post = _snapshot.value;
        uid = post[PostFieldsUid];
    }
    
    BOOL isNotifTurnedOn = [[Common sharedInstance] isNotifTurnedOnForUser:uid];
    
    if([post[PostFieldsUid] isEqualToString:[FIRAuth auth].currentUser.uid])
        return;
    
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
    
    BOOL isFollowing = [[Common sharedInstance] isFollowing:uid];
    NSString *title = isFollowing ? @"Unfollow" : @"Follow";
    UIAlertAction *viewPost = [UIAlertAction actionWithTitle:title
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
                                                                         [[Common sharedInstance] unfollow:uid];
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
                                   else
                                       [[Common sharedInstance] follow:uid];
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
    [alertCtrl addAction:viewPost];
    [alertCtrl addAction:turnOnNotif];
    [alertCtrl addAction:cancel];
    
    [self presentViewController:alertCtrl animated:YES completion:nil];
}

- (IBAction)onPostClicked:(id)sender {
    NSString *comment = _txtNewComment.text;
    
    if([comment isEqualToString:@""])
        return;
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    dic[CommentFieldsContent] = comment;
    dic[CommentFieldsTime] = [FIRServerValue timestamp];
    dic[CommentFieldsDisplayName] = [FIRAuth auth].currentUser.displayName;
    dic[CommentFieldsUserID] = [FIRAuth auth].currentUser.uid;
    dic[CommentFieldsPhotoURL] = [FIRAuth auth].currentUser.photoURL.absoluteString;
    
    NSString *path = [NSString stringWithFormat:@"comments/%@", postID];
    [[[_ref child:path] childByAutoId] setValue:dic];
    
    //send notification to the poster
    
    NSDictionary *post;
    NSString *uid;
    
    if(_snapshot.exists) {
        post = _snapshot.value;
        uid = post[PostFieldsUid];
        
        NSString *topic = [NSString stringWithFormat:@"user%@", uid];
        [Common sendNotification:topic title:@"New Comment" body:comment];
    }
    
    _txtNewComment.text = @"";
    [_txtNewComment resignFirstResponder];
}


-(void)keyboardWillShow:(NSNotification*)notification {
    
    NSDictionary *info  = notification.userInfo;
    NSValue      *value = info[UIKeyboardFrameEndUserInfoKey];
    
    CGRect rawFrame      = [value CGRectValue];
    keyboardFrame = [self.view convertRect:rawFrame fromView:nil];
    
    
    
    // Animate the current view out of the way
    [self setViewMovedUp:!keyboardMovedUp];
    
}

-(void)keyboardWillHide {
    [self setViewMovedUp:!keyboardMovedUp];
}

-(void)textFieldDidBeginEditing:(UITextField *)sender
{
    if ([sender isEqual:_txtNewComment])
    {
        //move the main view, so that the keyboard does not hide it.
        if  (!keyboardMovedUp)
        {
            [self setViewMovedUp:YES];
        }
    }
}

//method to move the view up/down whenever the keyboard is shown/dismissed
-(void)setViewMovedUp:(BOOL)movedUp
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    
    CGRect rect = self.viewNewComment.frame;
    if (movedUp)
    {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        lastFrame = rect;
        
        rect.origin.y = keyboardFrame.origin.y - rect.size.height;
        keyboardMovedUp = YES;
    }
    else
    {
        // revert back to the normal state.
        rect = lastFrame;
        keyboardMovedUp = NO;
    }
    self.viewNewComment.frame = rect;
    
    [UIView commitAnimations];
    
    
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self view] endEditing:YES];
}


- (void) initUI {
    if(_snapshot && _snapshot.exists) {
        NSDictionary<NSString *, NSString *> *post = _snapshot.value;
        
        
        //if my post, hide more button
        if([post[PostFieldsUid] isEqualToString:[FIRAuth auth].currentUser.uid]) {
            [_btnMore setHidden:YES];
        } else {
            [_btnMore setHidden:NO];
        }
        
        _lblUsername.text = post[PostFieldsUsername];
        
        NSString *photoURL = post[PostFieldsPhotoUrl];
        
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
    }
    
    
}

- (void)dealloc {
    
    NSString *path = [NSString stringWithFormat:@"comments/%@", postID];
    [[_ref child:path] removeObserverWithHandle:_refHandle];
}

- (void)configureStorage {
    NSString *storageUrl = [FIRApp defaultApp].options.storageBucket;
    self.storageRef = [[FIRStorage storage] referenceForURL:[NSString stringWithFormat:@"gs://%@", storageUrl]];
}

- (void)configureDatabase {
    _ref = [[FIRDatabase database] reference];
    // Listen for new messages in the Firebase database
    
    NSString *path = [NSString stringWithFormat:@"comments/%@", postID];
    
    _refHandle = [[_ref child:path] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        [_comments addObject:snapshot];
        [_table reloadData];
    }];
    
}

#pragma mark TableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_comments count] + 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == _table) {
        
        static NSString *CellIdentifierPost = @"postviewpostcell";
        static NSString *CellIdentifierComment = @"postviewcommentcell";
        
        int row = (int)indexPath.row;
        
        if(row == 0) {
            //for post
            
            PostViewPostCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierPost];
            
            // Unpack message from Firebase DataSnapshot
            [cell setCellData:_snapshot];
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.lblPost.hashtagLinkTapHandler = ^(KILabel *label, NSString *string, NSRange range) {
                NSLog(@"Hashtag tapped %@", string);
                
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                
                SearchViewController *searchview = [storyboard instantiateViewControllerWithIdentifier:@"searchview"];
                searchview.strSearch = string;
                [self.navigationController pushViewController:searchview animated:YES];
            };

            
            cell.accessoryType = 0;
            
            return cell;
            
        } else {
            //for comments
            PostViewCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierComment];
            
            // Unpack message from Firebase DataSnapshot
            int row = (int)indexPath.row - 1;
            
            FIRDataSnapshot *commentSnapshot = _comments[row];
            [cell setCellData:commentSnapshot];
            
            cell.delegate = self;
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.lblContent.hashtagLinkTapHandler = ^(KILabel *label, NSString *string, NSRange range) {
                NSLog(@"Hashtag tapped %@", string);
                
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                
                SearchViewController *searchview = [storyboard instantiateViewControllerWithIdentifier:@"searchview"];
                searchview.strSearch = string;
                [self.navigationController pushViewController:searchview animated:YES];
            };
            
            cell.accessoryType = 0;
            
            return cell;
        }
        
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    tableView.estimatedRowHeight = 500;
    return UITableViewAutomaticDimension;
}

#pragma mark CommentCellDelegate
- (void)didClickOnAvatar:(NSString *)uid {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    ProfileViewController *profileview = [storyboard instantiateViewControllerWithIdentifier:@"profileview"];
    profileview.uid = uid;
    profileview.isOther = YES;
    [self.navigationController pushViewController:profileview animated:YES];
}

@end
