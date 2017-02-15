//
//  ChangePasswordViewController.m
//  TraderHub
//
//  Created by imac on 1/26/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "ChangePasswordViewController.h"
#import "Common.h"
#import "SVProgressHUD.h"

@import FirebaseAuth;

@interface ChangePasswordViewController ()
@property (weak, nonatomic) IBOutlet UITextField *txtCurPass;
@property (weak, nonatomic) IBOutlet UITextField *txtNewPass;
@property (weak, nonatomic) IBOutlet UITextField *txtConfirmPass;

@end

@implementation ChangePasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

}

- (void) viewWillAppear:(BOOL)animated {
    [self initNavBar];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) initNavBar{
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.topItem.title = @"Change Password";
    
    UIBarButtonItem *updateButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Update"
                                   style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(updatePassword:)];
    self.navigationItem.rightBarButtonItem = updateButton;
}

- (void)viewWillDisappear:(BOOL)animated {
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
}

- (IBAction)updatePassword:(id)sender {
    FIRUser *user = [FIRAuth auth].currentUser;
    
    NSString *password = _txtNewPass.text;
    NSString *confirmPass = _txtConfirmPass.text;
    
    if([password isEqual:@""]) {
        [[Common sharedInstance] showAlert:self title:@"Change Password" message:@"Please input password"];
        return;
    }
    
    if(![password isEqualToString:confirmPass]) {
        [[Common sharedInstance] showAlert:self title:@"Change Password" message:@"Password does not match"];
        return;
    }
    
    [SVProgressHUD show];
    
    if(user) {
        [user updatePassword:password completion:^(NSError * _Nullable error) {
            [SVProgressHUD dismiss];
            if(error) {
                [[Common sharedInstance] showAlert:self title:@"Change Password" message:error.localizedDescription];
            } else {
                [SVProgressHUD showSuccessWithStatus:@"Password changed successfully"];
            }
        }];
    }
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self view] endEditing:YES];
}


@end
