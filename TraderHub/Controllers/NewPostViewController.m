//
//  NewPostViewController.m
//  TraderHub
//
//  Created by imac on 1/4/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "NewPostViewController.h"
#import "NewPostAttachViewController.h"
#import "ActionSheetStringPicker.h"
#import "Constants.h"
#import "Common.h"

@import FirebaseDatabase;
@import FirebaseAuth;

#define ADD_CUSTOM @"+Add Custom"

@interface NewPostViewController () <AttachImageDelegate>
@property (weak, nonatomic) IBOutlet UIButton *btnCancel;
@property (weak, nonatomic) IBOutlet UIButton *btnVehicle;
@property (weak, nonatomic) IBOutlet UITextField *txtEntryPrice;
@property (weak, nonatomic) IBOutlet UITextField *txtStopPrice;
@property (weak, nonatomic) IBOutlet UITextField *txtProfitTarget;
@property (weak, nonatomic) IBOutlet UISwitch *swProfitTarget;
@property (weak, nonatomic) IBOutlet UIButton *btnBuy;
@property (weak, nonatomic) IBOutlet UIButton *btnSel;

@property (weak, nonatomic) IBOutlet UIButton *btnTraderType;
@property (weak, nonatomic) IBOutlet UILabel *lblMarket;

@property (strong, nonatomic) FIRDatabaseReference *ref;

@end

@implementation NewPostViewController {
    NSArray         *vehiclesList;
    NSArray *traderTargetList;
    
    BOOL isSell;

    int indexOfVehicles;
    int indexOfForex;
    int indexOfFutures;
    int indexOfStock;
    int indexOfTraderTarget;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    vehiclesList = [NSArray arrayWithObjects:@"Forex", @"Futures", @"Stock", nil];
    traderTargetList = [NSArray arrayWithObjects:@"Scalp", @"Day Trade", @"Swing", @"Position", nil];

    indexOfVehicles = indexOfForex = indexOfFutures = indexOfStock = indexOfTraderTarget = 0;
    
    _ref = [[FIRDatabase database] reference];
    
    _btnBuy.layer.cornerRadius = 3;
    _btnBuy.clipsToBounds = YES;
    
    _btnSel.layer.cornerRadius = 3;
    _btnSel.clipsToBounds = YES;
    
    [self updateSellButtons];
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
- (IBAction)onCancelClicked:(id)sender {
    //[self.navigationController popViewControllerAnimated:YES];
    [self clearUI];
    [self.tabBarController setSelectedIndex:0];
}

- (void)clearUI {
    _lblMarket.text = @"EUR/USD";
    isSell = FALSE;
    [self updateSellButtons];
    _txtStopPrice.text = @"";
    _txtEntryPrice.text = @"";
    _txtProfitTarget.text = @"";
    [_btnTraderType setTitle:@"Trade Type" forState:UIControlStateNormal];
    [_swProfitTarget setOn:YES];
}

- (IBAction)onVehicleClicked:(id)sender {
    
    NSMutableArray *forexList;
    NSMutableArray *futuresList;
    NSMutableArray *stockList;
    
    forexList = [NSMutableArray arrayWithArray:[Common sharedInstance].customForexList];
    [forexList addObject:ADD_CUSTOM];
    futuresList = [NSMutableArray arrayWithArray:[Common sharedInstance].customFuturesList];
    [futuresList addObject:ADD_CUSTOM];
    stockList = [NSMutableArray arrayWithArray:[Common sharedInstance].customStockList];
    [stockList addObject:ADD_CUSTOM];
    
    
    [ActionSheetStringPicker showPickerWithTitle:@"Choose Product" rows:vehiclesList initialSelection:indexOfVehicles doneBlock:^(ActionSheetStringPicker *picker, NSInteger selIndex, id selectedValue) {
        indexOfVehicles = (int)selIndex;
        
        if(indexOfVehicles == 0) {
            //Forex
            [ActionSheetStringPicker showPickerWithTitle:@"Choose Forex" rows:forexList initialSelection:indexOfForex doneBlock:^(ActionSheetStringPicker *picker, NSInteger selIndex, id selectedValue) {
                indexOfForex = (int)selIndex;
                
                NSString *title = [forexList objectAtIndex:indexOfForex];
                
                if([title isEqualToString:ADD_CUSTOM]) {
                    [self doInputCustomMarketWithTitle:@"Forex" type:CUSTOM_FIELD_TYPE_FOREX];
                } else {
                    [self.lblMarket setText:title];
                }
            } cancelBlock:^(ActionSheetStringPicker *picker) {
                
            } origin:self.view];
        } else if(indexOfVehicles == 1) {
            //Futures
            [ActionSheetStringPicker showPickerWithTitle:@"Choose Futures" rows:futuresList initialSelection:indexOfFutures doneBlock:^(ActionSheetStringPicker *picker, NSInteger selIndex, id selectedValue) {
                indexOfFutures = (int)selIndex;
                
                NSString *title = [futuresList objectAtIndex:indexOfFutures];
                
                if([title isEqualToString:ADD_CUSTOM]) {
                    [self doInputCustomMarketWithTitle:@"Futures" type:CUSTOM_FIELD_TYPE_FUTURES];
                } else {
                    [self.lblMarket setText:title];
                }
            } cancelBlock:^(ActionSheetStringPicker *picker) {
                
            } origin:self.view];
        } else if(indexOfVehicles == 2) {
            //Stock
            
            if(stockList.count == 1) {
                [self doInputCustomMarketWithTitle:@"Stock" type:CUSTOM_FIELD_TYPE_STOCK];
            } else {
                [ActionSheetStringPicker showPickerWithTitle:@"Choose Stock" rows:stockList initialSelection:indexOfStock doneBlock:^(ActionSheetStringPicker *picker, NSInteger selIndex, id selectedValue) {
                    indexOfStock = (int)selIndex;
                    
                    NSString *title = [stockList objectAtIndex:indexOfStock];
                    
                    if([title isEqualToString:ADD_CUSTOM]) {
                        [self doInputCustomMarketWithTitle:@"Stock" type:CUSTOM_FIELD_TYPE_STOCK];
                    } else {
                        [self.lblMarket setText:title];
                    }
                } cancelBlock:^(ActionSheetStringPicker *picker) {
                    
                } origin:self.view];
            }
        }
    } cancelBlock:^(ActionSheetStringPicker *picker) {
        
    } origin:self.view];
}

- (IBAction)onTraderTypeClicked:(id)sender {
    [ActionSheetStringPicker showPickerWithTitle:@"Trade Type" rows:traderTargetList initialSelection:indexOfTraderTarget doneBlock:^(ActionSheetStringPicker *picker, NSInteger selIndex, id selectedValue) {
        indexOfTraderTarget = (int)selIndex;
        
        NSString *title = [traderTargetList objectAtIndex:indexOfTraderTarget];
        
        [self.btnTraderType setTitle:title forState:UIControlStateNormal];
    } cancelBlock:^(ActionSheetStringPicker *picker) {
        
    } origin:self.view];
}
- (IBAction)onBuy:(id)sender {
    isSell = NO;
    [self updateSellButtons];
}
- (IBAction)onSel:(id)sender {
    isSell = YES;
    [self updateSellButtons];
}

- (void)updateSellButtons {
    if(isSell) {
        _btnSel.backgroundColor = [UIColor redColor];
        _btnBuy.backgroundColor = [UIColor grayColor];
    } else {
        _btnSel.backgroundColor = [UIColor grayColor];
        _btnBuy.backgroundColor = [UIColor greenColor];
    }
}
- (IBAction)onNext:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    NewPostAttachViewController *attachview = [storyboard instantiateViewControllerWithIdentifier:@"newpostattachview"];
    attachview.delegate = self;
    [self.navigationController pushViewController:attachview animated:YES];
}

- (void)doInputCustomMarketWithTitle:(NSString *)title type:(int)type{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:title
                                          message:@"Custom name"
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         textField.placeholder = NSLocalizedString(@"StockPlaceholder", @"Name");
     }];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                       NSLog(@"Cancel action");
                                   }];
    
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action)
                               {
                                   NSLog(@"OK action");
                                   UITextField *txtCustomStock = alertController.textFields.firstObject;
                                   NSString *customName = txtCustomStock.text;
                                   
                                   [self.lblMarket setText:customName];
                                   
                                   [[Common sharedInstance] addCustomFieldWithType:type name:customName];
                               }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - AttachImageDelegate

- (void)attachImageViewDismisWithContent:(NSString *)content imageURL:(NSString *)imageURL {
    
    // post data
    NSMutableDictionary *mdata = [[NSMutableDictionary alloc] init];

    mdata[PostFieldsUid] = [FIRAuth auth].currentUser.uid;
    mdata[PostFieldsMarket] = _lblMarket.text;
    mdata[PostFieldsEntry] = _txtEntryPrice.text;
    mdata[PostFieldsStop] = _txtStopPrice.text;
    mdata[PostFieldsTarget] = _txtProfitTarget.text;
    if(_swProfitTarget.isOn)
        mdata[PostFieldsIsTargetOn] = @"TRUE";
    else
        mdata[PostFieldsIsTargetOn] = @"FALSE";
    
    if(isSell)
        mdata[PostFieldsIsSell] = @"TRUE";
    else
        mdata[PostFieldsIsSell] = @"FALSE";
    
    mdata[PostFieldsType] = [_btnTraderType titleForState:UIControlStateNormal];
    mdata[PostFieldsImageURL] = imageURL;
    mdata[PostFieldsContent] = content;    
    mdata[PostFieldsPhotoUrl] = [Common sharedInstance].photoURL;
    
    mdata[PostFieldsUsername] = [Common sharedInstance].displayName;
    
    mdata[PostFieldsTime] = [FIRServerValue timestamp];
    
    NSString *photoURL = [Common sharedInstance].photoURL;
    if (photoURL) {
        mdata[PostFieldsPhotoUrl] = photoURL;
    }
    
    // Push data to Firebase Database
    NSString *path = [NSString stringWithFormat:@"posts/%@", [FIRAuth auth].currentUser.uid];
    [[[_ref child:path] childByAutoId] setValue:mdata];
    
    path = [NSString stringWithFormat:@"feeds/%@", [FIRAuth auth].currentUser.uid];
    [[[_ref child:path] childByAutoId] setValue:mdata];
    
    //notification data
    NSMutableDictionary *notifData = [[NSMutableDictionary alloc] init];
    notifData[NotifFieldsPhotoURL] = [FIRAuth auth].currentUser.photoURL.absoluteString;
    notifData[NotifFieldsRead] = @"FALSE";
    notifData[NotifFieldsContent] = [NSString stringWithFormat:@"%@ posted new alert.", [FIRAuth auth].currentUser.displayName];
    notifData[NotifFieldsTime] = [FIRServerValue timestamp];
    
    [[[_ref child:@"followers"] child:[FIRAuth auth].currentUser.uid] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        if(snapshot.exists) {
            NSEnumerator *children = [snapshot children];
            FIRDataSnapshot *child;
            while (child = [children nextObject]) {
                NSString *followerId = [child key];
                [[[[_ref child:@"feeds"] child:followerId] childByAutoId] setValue:mdata];
                [[[[_ref child:@"notifications"] child:followerId] childByAutoId] setValue:notifData];
                
                //send notifications to followers
                NSString *topic = [NSString stringWithFormat:@"followers%@", [FIRAuth auth].currentUser.uid];
                [Common sendNotification:topic title:@"New Post" body:notifData[NotifFieldsContent]];
            }
        }
    }];
    
    [self clearUI];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self view] endEditing:YES];
}
@end
