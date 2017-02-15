//
//  OptionsViewController.m
//  TraderHub
//
//  Created by imac on 1/5/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "OptionsViewController.h"
#import "Common.h"
#import "Constants.h"
#import "ProfileEditViewController.h"
#import "ChangePasswordViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>


@import FirebaseAuth;
@import FirebaseDatabase;

@interface OptionsViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *swPrivateAccount;

@end

@implementation OptionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.topItem.title = @"Options";
    
    
    NSMutableArray *array = [Common sharedInstance].privateAccounts;
    NSString *myID = [FIRAuth auth].currentUser.uid;
    
    for(int i=0; i<array.count; i++) {
        if([array[i] isEqualToString:myID]) {
            [self.swPrivateAccount setOn:TRUE];
            return;
        }
    }
    
    [self.swPrivateAccount setOn:FALSE];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[self navigationController] setNavigationBarHidden:YES animated:NO];
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
- (IBAction)onLogoutClicked:(id)sender {
    FIRAuth *firebaseAuth = [FIRAuth auth];
    NSError *signOutError;
    BOOL status = [firebaseAuth signOut:&signOutError];
    if (!status) {
        NSLog(@"Error signing out: %@", signOutError);
        return;
    }
    
    if ([FBSDKAccessToken currentAccessToken]) {
        // User is logged in, do work such as go to next view controller.
        FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
        [loginManager logOut];
    }
    
    [Common sharedInstance].signedIn = false;
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"section %ld, row %ld", (long)indexPath.section, (long)indexPath.row);
    if(indexPath.section == 0) {
        if (indexPath.row == 0)
        {
            //edit profile
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            
            ProfileEditViewController *editview = [storyboard instantiateViewControllerWithIdentifier:@"profileeditview"];
            [self.navigationController pushViewController:editview animated:YES];
        } else if(indexPath.row == 1) {
            //change password
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            
            ProfileEditViewController *passview = [storyboard instantiateViewControllerWithIdentifier:@"changepasswordview"];
            [self.navigationController pushViewController:passview animated:YES];
        } else if(indexPath.row == 2){
            //private account
            
            //nothing to do here
        }
    } else if(indexPath.section == 1) {
        if(indexPath.row == 0) {
            //Help Center
            [self openScheme:URL_HELP_CENTER];
        } else if(indexPath.row == 1) {
            //Report a problem
            [self openScheme:URL_REPORT_PROBLEM];
        }
    } else if(indexPath.section == 2) {
        if(indexPath.row == 0) {
            //Learn to Trade
            [self openScheme:URL_LEARN_TO_TRADE];
        } else if(indexPath.row == 1) {
            //Blog
            [self openScheme:URL_BLOG];
        } else if(indexPath.row == 2) {
            //Privacy Policy
            [self openScheme:URL_PRIVACY_POLICY];
        } else if(indexPath.row == 3) {
            //Terms
            [self openScheme:URL_TERMS];
        }
    }
    
}

- (void)openScheme:(NSString *)scheme {
    UIApplication *application = [UIApplication sharedApplication];
    NSURL *URL = [NSURL URLWithString:scheme];
    
    if ([application respondsToSelector:@selector(openURL:options:completionHandler:)]) {
        [application openURL:URL options:@{}
           completionHandler:^(BOOL success) {
               NSLog(@"Open %@: %d",scheme,success);
           }];
    } else {
        BOOL success = [application openURL:URL];
        NSLog(@"Open %@: %d",scheme,success);
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}
- (IBAction)onPrivateAccountChange:(id)sender {
    NSString *path = [NSString stringWithFormat:@"settings/privates/%@", [FIRAuth auth].currentUser.uid];

    FIRDatabaseReference *ref = [[FIRDatabase database] reference];
    
    if(self.swPrivateAccount.isOn) {
        [[ref child:path] setValue:@"TRUE"];
    } else {
        [[ref child:path] removeValue];
    }
}

@end
