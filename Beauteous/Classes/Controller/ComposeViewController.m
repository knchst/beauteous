//
//  ComposeViewController.m
//  Beauteous
//
//  Created by Kenichi Saito on 7/29/15.
//  Copyright (c) 2015 Kenichi Saito. All rights reserved.
//

#import "ComposeViewController.h"
#import "PreviewViewController.h"
#import "NoteManager.h"
#import "BOUtility.h"
#import "BOConst.h"
#import "Note.h"
#import "CustomRFToolbarButton.h"
#import "BOParseManager.h"

#import "RFKeyBoardToolbar.h"
#import <Realm/Realm.h>
#import "SVProgressHUD.h"
#import "EDHFontSelector.h"
#import <Bolts/Bolts.h>

@interface ComposeViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) CustomRFToolbarButton *image;
@end

@implementation ComposeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (_isChat) {
        self.title = [NSString stringWithFormat:@"To %@", self.user[@"username"]];
    } else {
        self.title = @"New";
    }
    
    [self setUpToolBar];
    
    [[EDHFontSelector sharedSelector] applyToTextView:self.textView];
    
    [self.textView becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    CGRect keyboardFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    self.bottomConstraint.constant = keyboardFrame.size.height;
    
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    self.bottomConstraint.constant = 0;
    
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)preview:(id)sender
{
    PreviewViewController *previewVC = [[BOUtility storyboard] instantiateViewControllerWithIdentifier:@"Preview"];
    previewVC.htmlString = _textView.text;
    self.navigationItem.backBarButtonItem = [BOUtility blankBarButton];
    [self.navigationController pushViewController:previewVC animated:YES];
}

- (IBAction)done:(id)sender
{
    
    if (_isChat) {
        // send action
        __weak typeof(self) weakSelf = self;
        
        NSString *message = [NSString stringWithFormat:@"I will send note to %@.", self.user[@"username"]];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Confirm" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            [weakSelf sendNote];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        }];
        
        [alert addAction:ok];
        [alert addAction:cancel];
        
        [self.navigationController presentViewController:alert animated:YES completion:nil];
        
    } else {
        
        NSMutableDictionary *note = [NSMutableDictionary dictionary];
        
        if (_textView.text.length <= 0) {
            note[@"title"] = @"No title";
        } else {
            note[@"title"] = [_textView.text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]][0];
        }
        
        note[@"planeString"] = _textView.text;
        note[@"htmlString"] = [BOUtility renderHTMLWithString:_textView.text];
        note[@"created_at"] = [NSDate date];
        note[@"updated_at"] = [NSDate date];
        note[@"photoUrl"] = [[NoteManager sharedManager] detectPhotoURLWithString:_textView.text];
        
        [[NoteManager sharedManager] saveNoteWithDictionary:note];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)sendNote
{
    __weak typeof(self) weakSelf = self;
    NSMutableDictionary *note = [NSMutableDictionary dictionary];
    
    if (_textView.text.length <= 0) {
        note[@"title"] = @"No title";
    } else {
        note[@"title"] = [_textView.text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]][0];
    }
    
    note[@"planeString"] = _textView.text;
    note[@"htmlString"] = [BOUtility renderHTMLWithString:_textView.text];
    note[@"photoUrl"] = [[NoteManager sharedManager] detectPhotoURLWithString:_textView.text];
    
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    [SVProgressHUD show];
    [[BOParseManager sharedManager] sendNoteWithUsername:self.user[@"username"] andNote:note andBlock:^(NSError *error) {
        if (error) {
            NSString *errorString = [error userInfo][@"error"];
            NSLog(@"%@", errorString);
            [SVProgressHUD showErrorWithStatus:errorString];
        } else {
            [SVProgressHUD showSuccessWithStatus:@"You have sent note."];
            
            NSString *message = [NSString stringWithFormat:@"You recieved note from %@", [PFUser currentUser].username];
            
            NSDictionary *data = @{
                                   @"alert" : message,
                                   @"badge" : @"Increment",
                                   @"sound" : @"default"
                                   };
            
            PFUser *user = (PFUser*)weakSelf.user;
            
            PFQuery *pushQuery = [PFInstallation query];
            [pushQuery whereKey:@"user" equalTo:user];
            
            PFPush *push = [[PFPush alloc] init];
            [push setQuery:pushQuery];
            [push setData:data];
            [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
                NSLog(@"Push error is %@", error);
                [weakSelf dismissViewControllerAnimated:YES completion:nil];
            }];
        }
    }];
}

- (void)setUpToolBar
{
    // - / \ : ; ( ) ¥ & @ . , [ ] { } # % ^ * + = _ | ~ < > $ ? ! `
    
    CustomRFToolbarButton *backCaret = [CustomRFToolbarButton buttonWithTitle:@"◁"];
    CustomRFToolbarButton *forwardCaret  = [CustomRFToolbarButton buttonWithTitle:@"▷"];
    CustomRFToolbarButton *paste  = [CustomRFToolbarButton buttonWithTitle:@"Paste"];
    CustomRFToolbarButton *header = [CustomRFToolbarButton buttonWithTitle:@"Header"];
    CustomRFToolbarButton *quote  = [CustomRFToolbarButton buttonWithTitle:@"Quote"];
    CustomRFToolbarButton *table  = [CustomRFToolbarButton buttonWithTitle:@"Table"];
    self.image                    = [CustomRFToolbarButton buttonWithTitle:@"Image"];
    CustomRFToolbarButton *link   = [CustomRFToolbarButton buttonWithTitle:@"Link"];
    CustomRFToolbarButton *list   = [CustomRFToolbarButton buttonWithTitle:@"List"];
    CustomRFToolbarButton *italic = [CustomRFToolbarButton buttonWithTitle:@"Italic"];
    CustomRFToolbarButton *bold   = [CustomRFToolbarButton buttonWithTitle:@"Bold"];
    CustomRFToolbarButton *code   = [CustomRFToolbarButton buttonWithTitle:@"Code"];
    
    CustomRFToolbarButton *hyphen = [CustomRFToolbarButton buttonWithTitle:@"-"];
    CustomRFToolbarButton *slash = [CustomRFToolbarButton buttonWithTitle:@"/"];
    CustomRFToolbarButton *back_slash = [CustomRFToolbarButton buttonWithTitle:@"\\"];
    CustomRFToolbarButton *colon = [CustomRFToolbarButton buttonWithTitle:@":"];
    CustomRFToolbarButton *semi_colon = [CustomRFToolbarButton buttonWithTitle:@";"];
    CustomRFToolbarButton *open_parenthesis = [CustomRFToolbarButton buttonWithTitle:@"("];
    CustomRFToolbarButton *close_parenthesis = [CustomRFToolbarButton buttonWithTitle:@")"];
    CustomRFToolbarButton *yen = [CustomRFToolbarButton buttonWithTitle:@"¥"];
    CustomRFToolbarButton *and = [CustomRFToolbarButton buttonWithTitle:@"&"];
    CustomRFToolbarButton *at = [CustomRFToolbarButton buttonWithTitle:@"@"];
    CustomRFToolbarButton *dot = [CustomRFToolbarButton buttonWithTitle:@"."];
    CustomRFToolbarButton *comma = [CustomRFToolbarButton buttonWithTitle:@","];
    CustomRFToolbarButton *open_bracket = [CustomRFToolbarButton buttonWithTitle:@"["];
    CustomRFToolbarButton *close_bracket = [CustomRFToolbarButton buttonWithTitle:@"]"];
    CustomRFToolbarButton *open_curly_bracket = [CustomRFToolbarButton buttonWithTitle:@"{"];
    CustomRFToolbarButton *close_curly_bracket = [CustomRFToolbarButton buttonWithTitle:@"}"];
    CustomRFToolbarButton *hash = [CustomRFToolbarButton buttonWithTitle:@"#"];
    CustomRFToolbarButton *percent = [CustomRFToolbarButton buttonWithTitle:@"%"];
    CustomRFToolbarButton *caret = [CustomRFToolbarButton buttonWithTitle:@"^"];
    CustomRFToolbarButton *asterisk = [CustomRFToolbarButton buttonWithTitle:@"*"];
    CustomRFToolbarButton *plus = [CustomRFToolbarButton buttonWithTitle:@"+"];
    CustomRFToolbarButton *equal = [CustomRFToolbarButton buttonWithTitle:@"="];
    CustomRFToolbarButton *under_bar = [CustomRFToolbarButton buttonWithTitle:@"_"];
    CustomRFToolbarButton *pipe = [CustomRFToolbarButton buttonWithTitle:@"|"];
    CustomRFToolbarButton *tilde = [CustomRFToolbarButton buttonWithTitle:@"~"];
    CustomRFToolbarButton *less_than = [CustomRFToolbarButton buttonWithTitle:@"<"];
    CustomRFToolbarButton *more_than = [CustomRFToolbarButton buttonWithTitle:@">"];
    CustomRFToolbarButton *dollar = [CustomRFToolbarButton buttonWithTitle:@"$"];
    CustomRFToolbarButton *question = [CustomRFToolbarButton buttonWithTitle:@"?"];
    CustomRFToolbarButton *exclamation = [CustomRFToolbarButton buttonWithTitle:@"!"];
    CustomRFToolbarButton *grave = [CustomRFToolbarButton buttonWithTitle:@"`"];
    CustomRFToolbarButton *double_quote = [CustomRFToolbarButton buttonWithTitle:@"\""];
    CustomRFToolbarButton *single_quote = [CustomRFToolbarButton buttonWithTitle:@"'"];
    
    [backCaret addEventHandler:^{
        [self backCaret];
    } forControlEvents:UIControlEventTouchUpInside];
    [forwardCaret addEventHandler:^{
        [self forwardCaret];
    } forControlEvents:UIControlEventTouchUpInside];
    [paste addEventHandler:^{
        UIPasteboard *paste = [UIPasteboard generalPasteboard];
        NSString *string = [paste valueForPasteboardType:@"public.text"];
        if (string.length > 0) {
            [_textView insertText:string];
        } else {
            return;
        }
    } forControlEvents:UIControlEventTouchUpInside];
    [header addEventHandler:^{
        [_textView insertText:@"#"];
    } forControlEvents:UIControlEventTouchUpInside];
    [quote addEventHandler:^{
        [_textView insertText:@">"];
    } forControlEvents:UIControlEventTouchUpInside];
    [table addEventHandler:^{
        [_textView insertText:@"|  |"];
        UITextRange *range = _textView.selectedTextRange;
        UITextPosition *position = [_textView positionFromPosition:range.start
                                                            offset:-2];
        _textView.selectedTextRange = [_textView textRangeFromPosition:position
                                                            toPosition:position];
    } forControlEvents:UIControlEventTouchUpInside];
    __weak ComposeViewController *weakSelf = self;
    [_image addEventHandler:^{
        [weakSelf showActionSheet];
    } forControlEvents:UIControlEventTouchUpInside];
    [link addEventHandler:^{
        [_textView insertText:@"[]()"];
        UITextRange *range = _textView.selectedTextRange;
        UITextPosition *position = [_textView positionFromPosition:range.start
                                                            offset:-3];
        _textView.selectedTextRange = [_textView textRangeFromPosition:position
                                                            toPosition:position];
    } forControlEvents:UIControlEventTouchUpInside];
    [list addEventHandler:^{
        [_textView insertText:@"- "];
    } forControlEvents:UIControlEventTouchUpInside];
    [italic addEventHandler:^{
        // Do anything in this block here
        [_textView insertText:@"__"];
        UITextRange *range = _textView.selectedTextRange;
        UITextPosition *position = [_textView positionFromPosition:range.start
                                                            offset:-1];
        _textView.selectedTextRange = [_textView textRangeFromPosition:position
                                                            toPosition:position];
    } forControlEvents:UIControlEventTouchUpInside];
    [bold addEventHandler:^{
        // Do anything in this block here
        [_textView insertText:@"****"];
        UITextRange *range = _textView.selectedTextRange;
        UITextPosition *position = [_textView positionFromPosition:range.start
                                                            offset:-2];
        _textView.selectedTextRange = [_textView textRangeFromPosition:position
                                                            toPosition:position];
    } forControlEvents:UIControlEventTouchUpInside];
    [code addEventHandler:^{
        // Do anything in this block here
        [_textView insertText:@"``"];
        UITextRange *range = _textView.selectedTextRange;
        UITextPosition *position = [_textView positionFromPosition:range.start
                                                            offset:-1];
        _textView.selectedTextRange = [_textView textRangeFromPosition:position
                                                            toPosition:position];
    } forControlEvents:UIControlEventTouchUpInside];
    
    [hyphen addEventHandler:^{
        [_textView insertText:@"-"];
    } forControlEvents:UIControlEventTouchUpInside];
    [slash addEventHandler:^{
        [_textView insertText:@"/"];
    } forControlEvents:UIControlEventTouchUpInside];
    [back_slash addEventHandler:^{
        [_textView insertText:@"\\"];
    } forControlEvents:UIControlEventTouchUpInside];
    [colon addEventHandler:^{
        [_textView insertText:@":"];
    } forControlEvents:UIControlEventTouchUpInside];
    [semi_colon addEventHandler:^{
        [_textView insertText:@";"];
    } forControlEvents:UIControlEventTouchUpInside];
    [open_parenthesis addEventHandler:^{
        [_textView insertText:@"("];
    } forControlEvents:UIControlEventTouchUpInside];
    [close_parenthesis addEventHandler:^{
        [_textView insertText:@")"];
    } forControlEvents:UIControlEventTouchUpInside];
    [yen addEventHandler:^{
        [_textView insertText:@"¥"];
    } forControlEvents:UIControlEventTouchUpInside];
    [and addEventHandler:^{
        [_textView insertText:@"&"];
    } forControlEvents:UIControlEventTouchUpInside];
    [at addEventHandler:^{
        [_textView insertText:@"@"];
    } forControlEvents:UIControlEventTouchUpInside];
    [dot addEventHandler:^{
        [_textView insertText:@"."];
    } forControlEvents:UIControlEventTouchUpInside];
    [comma addEventHandler:^{
        [_textView insertText:@","];
    } forControlEvents:UIControlEventTouchUpInside];
    [open_bracket addEventHandler:^{
        [_textView insertText:@"["];
    } forControlEvents:UIControlEventTouchUpInside];
    [close_bracket addEventHandler:^{
        [_textView insertText:@"]"];
    } forControlEvents:UIControlEventTouchUpInside];
    [open_curly_bracket addEventHandler:^{
        [_textView insertText:@"{"];
    } forControlEvents:UIControlEventTouchUpInside];
    [close_curly_bracket addEventHandler:^{
        [_textView insertText:@"}"];
    } forControlEvents:UIControlEventTouchUpInside];
    [hash addEventHandler:^{
        [_textView insertText:@"#"];
    } forControlEvents:UIControlEventTouchUpInside];
    [caret addEventHandler:^{
        [_textView insertText:@"^"];
    } forControlEvents:UIControlEventTouchUpInside];
    [asterisk addEventHandler:^{
        [_textView insertText:@"*"];
    } forControlEvents:UIControlEventTouchUpInside];
    [plus addEventHandler:^{
        [_textView insertText:@"+"];
    } forControlEvents:UIControlEventTouchUpInside];
    [equal addEventHandler:^{
        [_textView insertText:@"="];
    } forControlEvents:UIControlEventTouchUpInside];
    [under_bar addEventHandler:^{
        [_textView insertText:@"_"];
    } forControlEvents:UIControlEventTouchUpInside];
    [pipe addEventHandler:^{
        [_textView insertText:@"|"];
    } forControlEvents:UIControlEventTouchUpInside];
    [tilde addEventHandler:^{
        [_textView insertText:@"~"];
    } forControlEvents:UIControlEventTouchUpInside];
    [less_than addEventHandler:^{
        [_textView insertText:@"<"];
    } forControlEvents:UIControlEventTouchUpInside];
    [more_than addEventHandler:^{
        [_textView insertText:@">"];
    } forControlEvents:UIControlEventTouchUpInside];
    [percent addEventHandler:^{
        [_textView insertText:@"%"];
    } forControlEvents:UIControlEventTouchUpInside];
    [dollar addEventHandler:^{
        [_textView insertText:@"$"];
    } forControlEvents:UIControlEventTouchUpInside];
    [question addEventHandler:^{
        [_textView insertText:@"?"];
    } forControlEvents:UIControlEventTouchUpInside];
    [exclamation addEventHandler:^{
        [_textView insertText:@"!"];
    } forControlEvents:UIControlEventTouchUpInside];
    [grave addEventHandler:^{
        [_textView insertText:@"`"];
    } forControlEvents:UIControlEventTouchUpInside];
    [double_quote addEventHandler:^{
        [_textView insertText:@"\""];
    } forControlEvents:UIControlEventTouchUpInside];
    [single_quote addEventHandler:^{
        [_textView insertText:@"'"];
    } forControlEvents:UIControlEventTouchUpInside];
    
    
    // Create an RFKeyboardToolbar, adding all of your buttons, and set it as your inputAcessoryView
    self.textView.inputAccessoryView = [RFKeyboardToolbar toolbarWithButtons:@[
                                                                           backCaret,
                                                                           forwardCaret,
                                                                           paste,
                                                                           header,
                                                                           quote,
                                                                           _image,
                                                                           table,
                                                                           link,
                                                                           list,
                                                                           italic,
                                                                           bold,
                                                                           code,
                                                                           hyphen,
                                                                           slash,
                                                                           back_slash,
                                                                           colon,
                                                                           semi_colon,
                                                                           open_parenthesis,
                                                                           close_parenthesis,
                                                                           yen,
                                                                           and,
                                                                           at,
                                                                           dot,
                                                                           comma,
                                                                           open_bracket,
                                                                           close_bracket,
                                                                           open_curly_bracket,
                                                                           close_curly_bracket,
                                                                           hash,
                                                                           percent,
                                                                           caret,
                                                                           asterisk,
                                                                           plus,
                                                                           equal,
                                                                           under_bar,
                                                                           pipe,
                                                                           tilde,
                                                                           less_than,
                                                                           more_than,
                                                                           dollar,
                                                                           question,
                                                                           exclamation,
                                                                           grave,
                                                                           double_quote,
                                                                           single_quote
                                                                           ]];
}

- (void)showActionSheet
{
    UIAlertController *ac = [[UIAlertController alloc] init];
    
    if ([BOUtility checkDevice]) {
        
        ac.popoverPresentationController.sourceView = self.textView;
        
        CGRect rect = CGRectMake(_image.frame.origin.x + _image.frame.size.width / 2, _textView.frame.size.height, 0, 0);
        
        ac.popoverPresentationController.sourceRect = rect;
    }
    
    UIAlertAction *urlAction = [UIAlertAction actionWithTitle:@"URL"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           [_textView insertText:@"![]()"];
                                                           UITextRange *range = _textView.selectedTextRange;
                                                           UITextPosition *position = [_textView positionFromPosition:range.start
                                                                                                               offset:-3];
                                                           _textView.selectedTextRange = [_textView textRangeFromPosition:position
                                                                                                               toPosition:position];
                                                       }];
    
    __weak ComposeViewController *weakSelf = self;
    
    UIAlertAction * pickerAction = [UIAlertAction actionWithTitle:@"Library"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [weakSelf showImagePicker];
                                                          }];
    
    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {
                                                          }];
    
    
    [ac addAction:urlAction];
    [ac addAction:pickerAction];
    [ac addAction:cancelAction];
    
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)showImagePicker
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.delegate = self;
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self presentViewController:imagePickerController animated:YES completion:nil];
        }];
        
    } else {
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Please allow Beauteous to use your PhotoLibrary"
                                                                    message:@""
                                                             preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction * action) {
                                                                 
                                                             }];
        UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:@"Settings"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                                               }];
        [ac addAction:cancelAction];
        [ac addAction:settingsAction];
        
        [self presentViewController:ac animated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    [SVProgressHUD showWithStatus:@"Uploading.."];
    
    NSData *imageData = [BOUtility resizeImageWithImage:info[UIImagePickerControllerOriginalImage]];

    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyyMMddHHmmss"];
    NSString *filename = [NSString stringWithFormat:@"image-%@.png", [format stringFromDate:[NSDate date]]];
    
    PFFile *image = [PFFile fileWithName:filename data:imageData];
    
    PFObject *file = [PFObject objectWithClassName:@"Photos"];
    file[@"image"] = image;
    
    __weak ComposeViewController *weakSelf = self;
    
    [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
        if (succeeded) {
            [weakSelf addImageURL:image.url];
        } else {
            [SVProgressHUD dismiss];
            [SVProgressHUD showErrorWithStatus:@"Error.."];
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        }
    }];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addImageURL:(NSString*)url
{
    NSMutableString *string = [NSMutableString stringWithString:_textView.text];
    [string insertString:[NSString stringWithFormat:@"![](%@)", url] atIndex:_textView.selectedRange.location];
    _textView.text = string;
    [SVProgressHUD dismiss];
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

- (void)backCaret
{
    UITextRange *range = _textView.selectedTextRange;
    UITextPosition *position = [_textView positionFromPosition:range.start offset:-1];
    _textView.selectedTextRange = [_textView textRangeFromPosition:position toPosition:position];
}

- (void)forwardCaret
{
    UITextRange *range = _textView.selectedTextRange;
    UITextPosition *position = [_textView positionFromPosition:range.start offset:1];
    _textView.selectedTextRange = [_textView textRangeFromPosition:position toPosition:position];
}

- (void)dealloc
{
    
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
