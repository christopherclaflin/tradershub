//
//  LoginViewController.m
//  TraderHub
//
//  Created by imac on 1/5/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "LoginViewController.h"
#import "SignupViewController.h"
#import "Common.h"
#import "Constants.h"
#import "SVProgressHUD.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@import Firebase;
@import FirebaseAuth;

@interface LoginViewController () <UITextFieldDelegate, FBSDKLoginButtonDelegate>
@property (weak, nonatomic) IBOutlet UITextField *txtUsername;
@property (weak, nonatomic) IBOutlet UITextField *txtPassword;
@property (weak, nonatomic) IBOutlet FBSDKLoginButton *btnFacebook;
@property (weak, nonatomic) IBOutlet UIButton *btnSignup;
@property (weak, nonatomic) IBOutlet UIButton *btnLogin;

@property (strong, nonatomic) FIRDatabaseReference *ref;
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _btnFacebook.layer.cornerRadius = 3;
    _btnFacebook.clipsToBounds = YES;
    _btnFacebook.delegate = self;
    
    _btnFacebook.readPermissions = @[@"email"];
    

    _btnLogin.layer.cornerRadius = 3;
    _btnLogin.clipsToBounds = YES;
    
    _txtUsername.delegate = self;
    _txtPassword.delegate = self;
    
    _ref = [[FIRDatabase database] reference];
}

- (void)viewDidAppear:(BOOL)animated {
    FIRUser *user = [FIRAuth auth].currentUser;
    if (user) {
        [self signedIn:user];
    }
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
- (IBAction)onFacebookLoginClicked:(id)sender {
    [SVProgressHUD show];
}

- (IBAction)onSignupClicked:(id)sender {
    [self performSegueWithIdentifier:@"toSignup" sender:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == _txtUsername) {
        [_txtPassword becomeFirstResponder];
    } else if(textField == _txtPassword)
    {
        [_txtPassword resignFirstResponder];
        [self doLogin];
    }
    return TRUE;
}

- (IBAction)onLogin:(id)sender {
    [self doLogin];
}

- (void)doLogin{
    
    [SVProgressHUD show];
    
    NSString *email = _txtUsername.text;
    NSString *password = _txtPassword.text;

    [[FIRAuth auth] signInWithEmail:email
                           password:password
                         completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 [SVProgressHUD dismiss];
                                 if (error) {
                                     NSLog(@"%@", error.localizedDescription);
                                     return;
                                 }
                                 [self signedIn:user];
                             });
                         }];
    
    
}
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self view] endEditing:YES];
}


- (void)signedIn:(FIRUser *)user {
//    [MeasurementHelper sendLoginEvent];
    
    [Common sharedInstance].displayName = user.displayName.length > 0 ? user.displayName : user.email;
    [Common sharedInstance].photoURL = user.photoURL.absoluteString;
    [Common sharedInstance].signedIn = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationKeysSignedIn
                                                        object:nil userInfo:nil];
    
    NSMutableDictionary *mdata = [[NSMutableDictionary alloc] init];
    mdata[UserFieldsDisplayname] = [Common sharedInstance].displayName;
    mdata[UserFieldsUsername] = [Common sharedInstance].displayName;
    
    if ([FBSDKAccessToken currentAccessToken]) {
        FBSDKProfile *profile = [FBSDKProfile currentProfile];
        NSString *userID = profile.userID;
        NSString *photoURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=medium", userID];
        mdata[UserFieldsPhotoURL] = photoURL;
    }
    
    NSString *path = [NSString stringWithFormat:@"users/%@", [FIRAuth auth].currentUser.uid];
    [[_ref child:path] updateChildValues:mdata];
    
    NSString *topic = [NSString stringWithFormat:@"/topics/user%@", [FIRAuth auth].currentUser.uid];
    [[FIRMessaging messaging] subscribeToTopic:topic];
    
    [self performSegueWithIdentifier:@"toMain" sender:nil];
}


- (IBAction)didRequestPasswordReset:(id)sender {
    UIAlertController *prompt =
    [UIAlertController alertControllerWithTitle:nil
                                        message:@"Email:"
                                 preferredStyle:UIAlertControllerStyleAlert];
    __weak UIAlertController *weakPrompt = prompt;
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * _Nonnull action) {
                                   UIAlertController *strongPrompt = weakPrompt;
                                   NSString *userInput = strongPrompt.textFields[0].text;
                                   if (!userInput.length)
                                   {
                                       return;
                                   }
                                   [[FIRAuth auth] sendPasswordResetWithEmail:userInput
                                                                   completion:^(NSError * _Nullable error) {
                                                                       if (error) {
                                                                           NSLog(@"%@", error.localizedDescription);
                                                                           return;
                                                                       }
                                                                   }];
                                   
                               }];
    [prompt addTextFieldWithConfigurationHandler:nil];
    [prompt addAction:okAction];
    [self presentViewController:prompt animated:YES completion:nil];
}

#pragma mark -Facbook Login Button delegate
- (void)loginButton:(FBSDKLoginButton *)loginButton
didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result
              error:(NSError *)error {
    
    
    if (error == nil) {
        FIRAuthCredential *credential = [FIRFacebookAuthProvider
                                         credentialWithAccessToken:[FBSDKAccessToken currentAccessToken]
                                         .tokenString];
        
        [[FIRAuth auth] signInWithCredential:credential
                                  completion:^(FIRUser *user, NSError *error) {
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          [SVProgressHUD dismiss];
                                          
                                          if (error) {
                                              [SVProgressHUD dismiss];
                                              [[Common sharedInstance] showAlert:self title:@"Log in" message:error.localizedDescription];
                                              NSLog(@"%@", error.localizedDescription);
                                          } else {
                                              [self signedIn:user];
                                          }
                                      });
                                  }];
    } else {
        [SVProgressHUD dismiss];
        [[Common sharedInstance] showAlert:self title:@"Log in" message:error.localizedDescription];
        NSLog(@"%@", error.localizedDescription);
    }
}
    
- (void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton {
    NSLog(@"FB logout");
    
    [SVProgressHUD dismiss];
    
}

@end
