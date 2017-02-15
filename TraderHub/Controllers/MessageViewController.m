//
//  MessageViewController.m
//  TraderHub
//
//  Created by imac on 1/6/17.
//  Copyright © 2017 imac. All rights reserved.
//

#import "MessageViewController.h"
#import "Constants.h"
#import "Common.h"

@import Firebase;
@import FirebaseStorage;
@import FirebaseAuth;



@interface MessageViewController () {
    FIRDatabaseHandle _newMessageRefHandle, _updatedMessageRefHandle;
    BOOL localTyping;
    JSQMessagesBubbleImage *outgoingBubbleImageView, *incomingBubbleImageView;
    
    UIImage *opponentImage, *myImage;
}

@property (strong, nonatomic) FIRDatabaseReference *channelRef, *messagesRef, *userIsTypingRef;
@property (strong, nonatomic) FIRDatabaseReference *opponentChannelRef, *opponentMessagesRef;
@property (strong, nonatomic) NSMutableArray<JSQMessage *> *messages;
@property (strong, nonatomic) NSMutableDictionary<NSString *, JSQPhotoMediaItem *> *photoMessageMap;
@property (strong, nonatomic) FIRStorageReference *storageRef;

@end

@implementation MessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.topItem.title = @"Messages";
    
    if(_snapshot) {
        _channelRef = _snapshot.ref;
        _messagesRef = [_channelRef child:@"messages"];
        _userIsTypingRef = [_channelRef child:@"typingIndicator"];

    } else {
        NSLog(@"Message View Snapshot is nil");
    }
    
    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
    _opponentChannelRef = [[[rootRef child:@"messages"] child:_opponentUID] child:[FIRAuth auth].currentUser.uid];
    _opponentMessagesRef = [_opponentChannelRef child:@"messages"];
    
    self.senderId = [FIRAuth auth].currentUser.uid;
    self.senderDisplayName = [FIRAuth auth].currentUser.displayName;
    
    _messages = [NSMutableArray array];
    
    incomingBubbleImageView = [self setupIncomingBubble];
    outgoingBubbleImageView = [self setupOutgoingBubble];
    
    [self configureDatabase];
    [self configureStorage];
    
    [self initUI];
    
    [self loadPhotos];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    
    [super viewWillDisappear:animated];
}

- (void)initUI{
    CGRect screenRect;
    screenRect = [UIScreen mainScreen].bounds;
    
    CGRect rect = screenRect;
    rect.size.height = 70;
    
    UIView *navView = [[UIView alloc] initWithFrame:rect];
    [self.view addSubview:navView];
    
    [navView setBackgroundColor:[UIColor colorWithRed:0.92 green:0.92 blue:0.94 alpha:1.0f]];
    
    rect = CGRectMake(14, 32, 27, 30);
    _btnBack = [[UIButton alloc] initWithFrame:rect];
    [_btnBack setTitleColor:[UIColor colorWithRed:0.04 green:0.37 blue:1 alpha:1.0f] forState:UIControlStateNormal];
    [_btnBack setTitle:@"<" forState:UIControlStateNormal];
    _btnBack.titleLabel.font = [UIFont systemFontOfSize:32];
    
    [_btnBack addTarget:self
                 action:@selector(onBackClicked:)
       forControlEvents:UIControlEventTouchUpInside];
    
    [navView addSubview:_btnBack];
    
    rect = CGRectMake(66, 37, 244, 21);
    rect.origin.x = (screenRect.size.width - rect.size.width) / 2;
    _lblTitle = [[UILabel alloc] initWithFrame:rect];
    [_lblTitle setTextAlignment:NSTextAlignmentCenter];
    [_lblTitle setText:_opponentDisplayName];
    [navView addSubview:_lblTitle];
    
    
}

- (void)dealloc {
    NSString *path = [NSString stringWithFormat:@"users/%@", [FIRAuth auth].currentUser.uid];
    [[_messagesRef child:path] removeObserverWithHandle:_newMessageRefHandle];
    
    [[_messagesRef child:path] removeObserverWithHandle:_updatedMessageRefHandle];
}

- (void)configureStorage {
    NSString *storageUrl = [FIRApp defaultApp].options.storageBucket;
    self.storageRef = [[FIRStorage storage] referenceForURL:[NSString stringWithFormat:@"gs://%@", storageUrl]];
}

- (void)configureDatabase {
    FIRDatabaseQuery *query = [_messagesRef queryLimitedToLast:25];
    
    _newMessageRefHandle = [query observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSDictionary *msg = snapshot.value;
        
        NSString *senderId = msg[MessageFieldsSenderId];
        NSString *senderName = msg[MessageFieldsSenderName];
        NSString *text = msg[MessageFieldsText];
        [self addMessageWithId:senderId senderName:senderName text:text];
        [self finishReceivingMessage];
    }];
    
    _updatedMessageRefHandle = [_messagesRef observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSLog(@"Message changed");
    }];
    
    [[_channelRef child:ChannelFieldsUnreads] setValue:@"0"];
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
//    [self.navigationController popViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)addMessageWithId:(NSString *)senderId senderName:(NSString *)senderName text:(NSString*) text {
    JSQMessage *msg = [JSQMessage messageWithSenderId:senderId displayName:senderName text:text];
    
    [_messages addObject:msg];
}

- (void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date {
    FIRDatabaseReference *ref = _messagesRef.childByAutoId;
    
    NSMutableDictionary *msg = [[NSMutableDictionary alloc] init];
    msg[MessageFieldsSenderId] = senderId;
    msg[MessageFieldsSenderName] = senderDisplayName;
    msg[MessageFieldsText] = text;
    msg[MessageFieldsTime] = [FIRServerValue timestamp];
    
    [ref setValue:msg];
    
    
    ref = _opponentMessagesRef.childByAutoId;
    [ref setValue:msg];
    
    [[_channelRef child:ChannelFieldsLastMsg] setValue:text];
    
    [[_opponentChannelRef child:ChannelFieldsName] setValue:[FIRAuth auth].currentUser.displayName];
    [[_opponentChannelRef child:ChannelFieldsPhotoURL] setValue:[FIRAuth auth].currentUser.photoURL.absoluteString];
    [[_opponentChannelRef child:ChannelFieldsLastMsg] setValue:text];
    [[_opponentChannelRef child:ChannelFieldsTime] setValue:[FIRServerValue timestamp]];
    
    [[_opponentChannelRef child:ChannelFieldsUnreads] runTransactionBlock:^FIRTransactionResult * _Nonnull(FIRMutableData * _Nonnull currentData) {
        NSNumber *value = currentData.value;
        if (!value || [value isEqual:[NSNull null]]) {
            value = 0;
        }
        
        [currentData setValue:[NSNumber numberWithInt:(1 + [value intValue])]];
        
        return [FIRTransactionResult successWithValue:currentData];
    } andCompletionBlock:^(NSError * _Nullable error,
                           BOOL committed,
                           FIRDataSnapshot * _Nullable snapshot) {
        // Transaction completed
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }
    }];
    
    [JSQSystemSoundPlayer jsq_playMessageSentAlert];
    
    [self finishSendingMessage];
    
    //send notification
    NSString *topic = [NSString stringWithFormat:@"user%@", _opponentUID];
    [Common sendNotification:topic title:[FIRAuth auth].currentUser.displayName body:msg[MessageFieldsText]];
}
- (void)didPressAccessoryButton:(UIButton *)sender {
    
}
- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    return _messages[indexPath.row];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _messages.count;
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessage *msg = _messages[indexPath.row];
    
    if([msg.senderId isEqualToString:self.senderId]) {
        return outgoingBubbleImageView;
    } else {
        return incomingBubbleImageView;
    }
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessage *msg = _messages[indexPath.row];
    
    UIImage *image;
    
    if([msg.senderId isEqualToString:self.senderId]) {
        image = myImage;
    } else {
        image = opponentImage;
    }
    return image ? [JSQMessagesAvatarImage avatarWithImage:image] : nil;
    
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    JSQMessage *msg = _messages[indexPath.row];
    
    if([msg.senderId isEqualToString:self.senderId]) {
        cell.textView.textColor = [UIColor whiteColor];
    } else {
        cell.textView.textColor = [UIColor blackColor];
    }
    
    return cell;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    return 15.0f;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessage *msg = _messages[indexPath.row];
    
    if([msg.senderId isEqualToString:self.senderId]) {
        return nil;
    } else {
        return [[NSAttributedString alloc] initWithString:msg.senderDisplayName];
    }
}

- (JSQMessagesBubbleImage *)setupOutgoingBubble {
    JSQMessagesBubbleImageFactory *factory = [[JSQMessagesBubbleImageFactory alloc] init];
    
    return [factory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleBlueColor]];
}

- (JSQMessagesBubbleImage *)setupIncomingBubble {
    JSQMessagesBubbleImageFactory *factory = [[JSQMessagesBubbleImageFactory alloc] init];
    
    return [factory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
}


- (void)loadPhotos {
    NSString *imageURL = _opponentPhotoURL;
    if (imageURL) {
        if ([imageURL hasPrefix:@"gs://"]) {
            [[[FIRStorage storage] referenceForURL:imageURL] dataWithMaxSize:INT64_MAX
                                                                  completion:^(NSData *data, NSError *error) {
                                                                      if (error) {
                                                                          NSLog(@"Error downloading: %@", error);
                                                                          return;
                                                                      }
                                                                      opponentImage = [UIImage imageWithData:data];
                                                                      [self.collectionView reloadData];
                                                                  }];
        } else {
            opponentImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
        }
    } else {
        opponentImage = [UIImage imageNamed:@"avatar.png"];
    }
    
    imageURL = [FIRAuth auth].currentUser.photoURL.absoluteString;
    if (imageURL) {
        if ([imageURL hasPrefix:@"gs://"]) {
            [[[FIRStorage storage] referenceForURL:imageURL] dataWithMaxSize:INT64_MAX
                                                                  completion:^(NSData *data, NSError *error) {
                                                                      if (error) {
                                                                          NSLog(@"Error downloading: %@", error);
                                                                          return;
                                                                      }
                                                                      myImage = [UIImage imageWithData:data];
                                                                      [self.collectionView reloadData];
                                                                  }];
        } else {
            myImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
        }
    } else {
        myImage = [UIImage imageNamed:@"avatar.png"];
    }
}
@end
