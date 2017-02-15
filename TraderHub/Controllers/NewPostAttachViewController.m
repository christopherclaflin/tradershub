//
//  NewPostAttachViewController.m
//  TraderHub
//
//  Created by imac on 1/5/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "NewPostAttachViewController.h"
#import "SVProgressHUD.h"

@import Photos;
@import Firebase;
@import FirebaseAuth;
@import FirebaseStorage;

@interface NewPostAttachViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *btnImage;
@property (weak, nonatomic) IBOutlet UITextView *txtContent;
@property (weak, nonatomic) IBOutlet UIView *viewContent;

@property (strong, nonatomic) FIRStorageReference *storageRef;
@end

@implementation NewPostAttachViewController {
    NSString *imageURL;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _txtContent.delegate = self;
    
    [self configureStorage];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configureStorage {
    NSString *storageUrl = [FIRApp defaultApp].options.storageBucket;
    self.storageRef = [[FIRStorage storage] referenceForURL:[NSString stringWithFormat:@"gs://%@", storageUrl]];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)onPostClicked:(id)sender {
    [SVProgressHUD show];
    
    if(_delegate && [_delegate respondsToSelector:@selector(attachImageViewDismisWithContent:imageURL:)]) {
        [_delegate attachImageViewDismisWithContent:_txtContent.text imageURL:imageURL];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // time-consuming task
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                [self.navigationController popToRootViewControllerAnimated:YES];
            });
        });
    }
}
- (IBAction)onBackClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
- (IBAction)onUploadClicked:(id)sender {
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
    
        UIImage *image = info[UIImagePickerControllerEditedImage];
    [_btnImage setImage:image forState:UIControlStateNormal];
    
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    NSString *imagePath =
    [NSString stringWithFormat:@"%@/%lld.jpg",
     [FIRAuth auth].currentUser.uid,
     (long long)([[NSDate date] timeIntervalSince1970] * 1000.0)];
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
                                    imageURL = [_storageRef child:metadata.path].description;
                                }];

    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self view] endEditing:YES];
    
    [self moveUp:NO];
}

- (void) moveUp:(BOOL)up {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    
    CGRect rect = self.viewContent.frame;
    if (up)
    {
        rect.origin.y = -300;
    }
    else
    {
        rect.origin.y = 0;
    }
    self.viewContent.frame = rect;
    
    [UIView commitAnimations];
}


#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    [self moveUp:YES];
    
    return TRUE;
}
@end
