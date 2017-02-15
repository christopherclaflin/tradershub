//
//  SignupViewController.m
//  TraderHub
//
//  Created by imac on 1/5/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "SignupViewController.h"
#import "HomeViewController.h"
#import "Common.h"
#import "Constants.h"
#import "SVProgressHUD.h"

@import Firebase;
@import FirebaseAuth;


@interface SignupViewController ()

@property (weak, nonatomic) IBOutlet UITextField *txtEmail;
@property (weak, nonatomic) IBOutlet UITextField *txtUsername;
@property (weak, nonatomic) IBOutlet UITextField *txtPassword;
@property (weak, nonatomic) IBOutlet UITextField *txtDisplayName;
@property (weak, nonatomic) IBOutlet UIButton *btnSignup;
@property (weak, nonatomic) IBOutlet UITextField *txtConfirmPassword;

@property (strong, nonatomic) FIRDatabaseReference *ref;


@end

@implementation SignupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self configureDatabase];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configureDatabase {
    _ref = [[FIRDatabase database] reference];
    // Listen for new messages in the Firebase database
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)onSignupClicked:(id)sender {
    NSString *email = _txtEmail.text;
    NSString *password = _txtPassword.text;
    NSString *confirmPass = _txtConfirmPassword.text;
    NSString *username = _txtUsername.text;
    NSString *displayName = _txtDisplayName.text;
    
    if([email isEqualToString:@""]) {
        [self showAlert:@"Sign up" message:@"Enter email address"];
        return;
    }
    
    if([displayName isEqualToString:@""]) {
        [self showAlert:@"Sign up" message:@"Enter display name"];
        return;
    }
    
    if([username isEqualToString:@""]) {
        [self showAlert:@"Sign up" message:@"Enter user name"];
        return;
    }
    
    if([password isEqualToString:@""]) {
        [self showAlert:@"Sign up" message:@"Enter password"];
        return;
    }
    
    if(![password isEqualToString:confirmPass]) {
        [self showAlert:@"Sign up" message:@"Password mismatch"];
        return;
    }
    
    [SVProgressHUD show];
    
    
    [[FIRAuth auth] createUserWithEmail:email
                               password:password
                             completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
                                 
                                 if (error) {
                                     NSLog(@"%@", error.localizedDescription);
                                     
                                     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                         // time-consuming task
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             [SVProgressHUD dismiss];
                                             [self showAlert:@"Sign up" message:error.localizedDescription];
                                         });
                                     });
                                     return;
                                 }
                                 [self setDisplayName:user username:username displayName:displayName];
                                 
                             }];
}

- (void)setDisplayName:(FIRUser *)user username:(NSString *)username displayName:(NSString *)displayName{
    FIRUserProfileChangeRequest *changeRequest =
    [user profileChangeRequest];
    // Use first part of email as the default display name
//    changeRequest.displayName = [[user.email componentsSeparatedByString:@"@"] objectAtIndex:0];
    changeRequest.displayName = displayName;
    
    [changeRequest commitChangesWithCompletion:^(NSError *_Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
        if (error) {
            NSLog(@"%@", error.localizedDescription);
            return;
        }
        [self signedIn:[FIRAuth auth].currentUser username:username];
    }];
    
    
}


- (IBAction)onFacebookClicked:(id)sender {
    [self performSegueWithIdentifier:@"toMain" sender:nil];
}
- (IBAction)onBackClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)signedIn:(FIRUser *)user username:(NSString *)username{
    //    [MeasurementHelper sendLoginEvent];
    
    [Common sharedInstance].displayName = user.displayName;
    [Common sharedInstance].photoURL = [user.photoURL absoluteString];
    [Common sharedInstance].signedIn = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationKeysSignedIn
                                                        object:nil userInfo:nil];
    
    NSMutableDictionary *mdata = [[NSMutableDictionary alloc] init];
    mdata[UserFieldsDisplayname] = [Common sharedInstance].displayName;
    mdata[UserFieldsUsername] = username;
    
    NSString *path = [NSString stringWithFormat:@"users/%@", [FIRAuth auth].currentUser.uid];
    [[_ref child:path] setValue:mdata];
    
    NSString *topic = [NSString stringWithFormat:@"/topics/user%@", [FIRAuth auth].currentUser.uid];
    [[FIRMessaging messaging] subscribeToTopic:topic];
     
    [self performSegueWithIdentifier:@"toMain" sender:nil];
}

-(void) showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:ok];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self view] endEditing:YES];
}
@end
