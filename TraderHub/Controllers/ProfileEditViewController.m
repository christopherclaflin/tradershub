//
//  ProfileEditViewController.m
//  TraderHub
//
//  Created by imac on 1/5/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "ProfileEditViewController.h"
#import "Constants.h"
#import "Common.h"
#import "SVProgressHUD.h"

#import <SDWebImage/UIImageView+WebCache.h>

@import FirebaseAuth;
@import FirebaseDatabase;
@import FirebaseStorage;
@import Firebase;

@interface ProfileEditViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, UITextFieldDelegate> {
    FIRDatabaseHandle _refHandle;
    NSString *photoURL;
}
@property (weak, nonatomic) IBOutlet UIView *viewContent;
@property (weak, nonatomic) IBOutlet UIImageView *imgUser;
@property (weak, nonatomic) IBOutlet UITextField *txtName;
@property (weak, nonatomic) IBOutlet UITextField *txtUsername;
@property (weak, nonatomic) IBOutlet UITextView *txtBio;
@property (weak, nonatomic) IBOutlet UITextField *txtWebsite;
@property (weak, nonatomic) IBOutlet UITextField *txtEmail;

@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) FIRStorageReference *storageRef;



@end

@implementation ProfileEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _imgUser.layer.cornerRadius = _imgUser.layer.frame.size.width / 2;
    _imgUser.clipsToBounds = YES;
    
    _imgUser.layer.borderColor = [UIColor blackColor].CGColor;
    _imgUser.layer.borderWidth = 2;
    
    _txtName.delegate = self;
    _txtUsername.delegate = self;
    _txtBio.delegate = self;
    _txtWebsite.delegate = self;
    _txtEmail.delegate = self;
    
    [self configureDatabase];
    [self configureStorage];
}

- (void)dealloc {
    NSString *path = [NSString stringWithFormat:@"users/%@", [FIRAuth auth].currentUser.uid];
    
    [[_ref child:path] removeObserverWithHandle:_refHandle];
}

- (void)configureDatabase {
    _ref = [[FIRDatabase database] reference];
    // Listen for new messages in the Firebase database
    
    NSString *path = [NSString stringWithFormat:@"users/%@", [FIRAuth auth].currentUser.uid];
    
    _refHandle = [[_ref child:path] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
        [self updateUserView:snapshot];
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

- (void)updateUserView: (FIRDataSnapshot *)snapshot {
    
    
    _txtName.text = [FIRAuth auth].currentUser.displayName;
    _txtEmail.text = [FIRAuth auth].currentUser.email;
    photoURL = [[FIRAuth auth].currentUser.photoURL absoluteString];
    
    if(!snapshot.exists)
        return;
    
    NSDictionary<NSString *, NSString *> *userInfo = snapshot.value;
    
    _txtUsername.text = userInfo[UserFieldsUsername];
    _txtBio.text = userInfo[UserFieldsBio];
    _txtWebsite.text = userInfo[UserFieldsWebsite];
    
    
    
    
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
- (IBAction)onBackClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
- (IBAction)onDoneClicked:(id)sender {
    
    NSMutableDictionary *mdata = [[NSMutableDictionary alloc] init];
    
    [SVProgressHUD show];
    
    mdata[UserFieldsUsername] = _txtUsername.text;
    mdata[UserFieldsBio] = _txtBio.text;
    mdata[UserFieldsWebsite] = _txtWebsite.text;
    
    [Common sharedInstance].photoURL = photoURL;
    [Common sharedInstance].displayName = _txtName.text;
    
    mdata[UserFieldsDisplayname] = _txtName.text;
    mdata[UserFieldsPhotoURL] = photoURL;
    
    NSString *path = [NSString stringWithFormat:@"users/%@", [FIRAuth auth].currentUser.uid];
    [[_ref child:path] updateChildValues:mdata];
    
    FIRUserProfileChangeRequest *changeRequest = [[FIRAuth auth].currentUser profileChangeRequest];
    changeRequest.displayName = _txtName.text;
    changeRequest.photoURL = [NSURL URLWithString:photoURL];
    [changeRequest commitChangesWithCompletion:^(NSError *_Nullable error) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // time-consuming task
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                
                [self.navigationController popViewControllerAnimated:YES];
            });
        });
    }];
}
- (IBAction)onChangePicture:(id)sender {
    UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:nil
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
    //Create an action
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"Take photo"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action)
                                   {
                                       [self showImagePickerWithType:UIImagePickerControllerSourceTypeCamera];
                                       
                                   }];
    UIAlertAction *galleryAction = [UIAlertAction actionWithTitle:@"Load from library"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action)
                                    {
                                        [self showImagePickerWithType:UIImagePickerControllerSourceTypePhotoLibrary];
                                    }];
    
    
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction *action)
                             {
                                 
                             }];
    
    
    //Add action to alertCtrl
    [alertCtrl addAction:cameraAction];
    [alertCtrl addAction:galleryAction];
    [alertCtrl addAction:cancel];
    
    [self presentViewController:alertCtrl animated:YES completion:nil];
}
- (void)showImagePickerWithType:(int)type {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = type;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [SVProgressHUD show];
    
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    [_imgUser setImage:chosenImage];
    
    NSData *imageData = UIImageJPEGRepresentation(chosenImage, 0.8);
    NSString *imagePath =
    [NSString stringWithFormat:@"avatar/%@.jpg",
     [FIRAuth auth].currentUser.uid];
    FIRStorageMetadata *metadata = [FIRStorageMetadata new];
    metadata.contentType = @"image/jpeg";
    [[_storageRef child:imagePath] putData:imageData metadata:metadata
                                completion:^(FIRStorageMetadata * _Nullable metadata, NSError * _Nullable error) {
                                    
                                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                        // time-consuming task
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [SVProgressHUD dismiss];
                                        });
                                    });
                                    
                                    if (error) {
                                        NSLog(@"Error uploading: %@", error);
                                        return;
                                    }
                                    
                                    photoURL = [_storageRef child:metadata.path].description;
                                }];


    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self view] endEditing:YES];
    
    [self moveUp:0];
}

- (void) moveUp:(int)y {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    
    CGRect rect = self.viewContent.frame;
    rect.origin.y = y;
    self.viewContent.frame = rect;
    
    [UIView commitAnimations];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    
    if(textView == _txtBio) {
        [self moveUp:-120];
    }
    
    return TRUE;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if(textField == _txtEmail) {
        [self moveUp:-220];
    } else if(textField == _txtWebsite) {
        [self moveUp:-180];
    } else if(textField == _txtUsername) {
        [self moveUp:-20];
    } else if(textField == _txtName) {
        [self moveUp:0];
    }
    
    return TRUE;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == _txtEmail) {
        [textField resignFirstResponder];
    } else if(textField == _txtWebsite) {
        [_txtEmail becomeFirstResponder];
    } else if(textField == _txtUsername) {
        [_txtBio becomeFirstResponder];
    } else if(textField == _txtName) {
        [_txtUsername becomeFirstResponder];
    }
    return TRUE;
}

@end
