//
//  SignInViewController.m
//  Zype
//
//  Created by ZypeTech on 3/2/15.
//  Copyright (c) 2015 Zype. All rights reserved.
//

#import <Crashlytics/Crashlytics.h>
#import "SignInViewController.h"
#import "SVProgressHUD.h"
#import "ACSTokenManager.h"
#import "ACSAlertViewManager.h"
#import "ACSDataManager.h"
#import "GAIDictionaryBuilder.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+UIView_CustomizeTheme.h"
#import "UIViewController+AC.h"

@interface SignInViewController ()

@property (nonatomic) bool isEditing;
@property (nonatomic) bool isSlideUp;
@property (nonatomic) int amountKeyboardSlide;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomBackgroundPaddingConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *centerCredentialsConstraintY;

@property (strong, nonatomic) IBOutlet UIView *credentialContainerView;
@property (strong, nonatomic) IBOutlet UIView *separateLineView;
@property (strong, nonatomic) IBOutlet UIButton *closeButton;
@property (strong, nonatomic) IBOutlet UIButton *signupButton;
@property (strong, nonatomic) IBOutlet UIImageView *arrowImageView;

@end

@implementation SignInViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.screenName = @"Sign In";
    // Do any additional setup after loading the view.
    [self registerForKeyboardNotifications];
    [self configureView];
}

- (void)viewDidLayoutSubviews {
    //add corners
//    UIBezierPath *maskPath;
//    maskPath = [UIBezierPath bezierPathWithRoundedRect:self.textFieldEmail.bounds
//                                     byRoundingCorners:(UIRectCornerTopLeft|UIRectCornerTopRight)
//                                           cornerRadii:CGSizeMake(13.0, 13.0)];
//    
//    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
//    maskLayer.frame = self.textFieldEmail.bounds;
//    maskLayer.path = maskPath.CGPath;
//    self.textFieldEmail.layer.mask = maskLayer;
//    
//    UIBezierPath *maskPathTwo = [UIBezierPath bezierPathWithRoundedRect:self.textFieldPassword.bounds
//                                                      byRoundingCorners:(UIRectCornerBottomLeft|UIRectCornerBottomRight)
//                                                            cornerRadii:CGSizeMake(13.0, 13.0)];
//    
//    CAShapeLayer *maskLayerTwo = [[CAShapeLayer alloc] init];
//    maskLayerTwo.frame = self.textFieldPassword.bounds;
//    maskLayerTwo.path = maskPathTwo.CGPath;
//    self.textFieldPassword.layer.mask = maskLayerTwo;
    
}

- (void)viewDidAppear:(BOOL)animated
{
    self.amountKeyboardSlide = [self keyboardPosition];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - keyboard actions

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    NSNumber *durationValue = info[UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration = durationValue.doubleValue;
    
    NSNumber *curveValue = info[UIKeyboardAnimationCurveUserInfoKey];
    UIViewAnimationCurve animationCurve = curveValue.intValue;
    
    // 568 284 81 216
    // 568 - 216 = 352 / 2 + 40
    // Create animation.
    
    self.bottomBackgroundPaddingConstraint.constant = kbSize.height;
    CGFloat height = self.view.frame.size.height / 2;
    CGFloat y = (height - kbSize.height) / 2 + 50;
    self.centerCredentialsConstraintY.constant = y;
    
    void (^animations)() = ^() {
        [self.view layoutIfNeeded];
    };
    
    //
    // Begin animation.
    
    [UIView animateWithDuration:animationDuration
                          delay:0.0
                        options:(animationCurve << 16)
                     animations:animations
                     completion:nil];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    self.bottomBackgroundPaddingConstraint.constant = 0.0f;
    self.centerCredentialsConstraintY.constant = 0.0f;
    [UIView animateWithDuration:0.2 animations:^{
        [self.view layoutIfNeeded];
    }];
}


#pragma mark - Init UI

- (void)configureView
{
    //change color for Sign In button
    [self.buttonSignIn tintCustomizeTheme];
    [self customizeAppearance];
    [self.buttonSignIn round:kViewCornerRounded];
    [self.credentialContainerView round:kViewCornerRounded];
    [self.credentialContainerView borderCustomizeTheme];
    self.separateLineView.backgroundColor = kUniversalGray;
    [self.textFieldEmail setAttributePlaceholder:@"Email"];
    [self.textFieldPassword setAttributePlaceholder:@"Password"];
    
    self.textFieldEmail.delegate = self;
    self.textFieldPassword.delegate = self;
    self.isEditing = NO;
    self.isSlideUp = NO;
    
    UIColor * currentColor = (kAppColorLight) ? kLightTintColor : kDarkTintColor;
    NSDictionary * attributes = @{NSForegroundColorAttributeName: currentColor,
                                  NSFontAttributeName: [UIFont fontWithName:@"Roboto-Medium" size:12.0f]};
    NSMutableAttributedString * attrstring = [[NSMutableAttributedString alloc] initWithString:@"Don't have an account? " attributes:@{NSForegroundColorAttributeName: kUniversalGray,
                                                                                                                                       NSFontAttributeName: [UIFont fontWithName:@"Roboto-Regular" size:12.0f]}];
    NSAttributedString * signupText = [[NSAttributedString alloc] initWithString:@"Sign up" attributes:attributes];
    [attrstring appendAttributedString:signupText];
    [self.signupButton setAttributedTitle:attrstring forState:UIControlStateNormal];
    
    NSString *arrowImageString = (kAppColorLight) ? @"arrow-light" : @"arrow-black";
    [self.arrowImageView setImage:[UIImage imageNamed:arrowImageString]];
    // Dismiss keyboard
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];
    tapRecognizer.cancelsTouchesInView = YES;
    [self.view addGestureRecognizer:tapRecognizer];
}

- (IBAction)dismissTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissKeyboard:(id)sender
{
    self.isEditing = NO;
    [self.view endEditing:YES];
}

#pragma mark - TextField delegate


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    self.isEditing = NO;
    [textField resignFirstResponder];
    return YES;
}
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    [self slideUp];
    return YES;
}
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    [self slideDown];
    return YES;
}

- (void)slideUp
{
    self.isEditing = YES;
    if (self.isEditing && !self.isSlideUp) {
        self.isSlideUp = YES;
        CGRect frame = self.view.frame;
        [UIView animateWithDuration:0.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.view.frame = CGRectMake(frame.origin.x, frame.origin.y - self.amountKeyboardSlide, frame.size.width, frame.size.height);
                         }
                         completion:nil];
    }
}
- (void)slideDown
{
    if (!self.isEditing) {
        self.isSlideUp = NO;
        CGRect frame = self.view.frame;
        [UIView animateWithDuration:0.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.view.frame = CGRectMake(frame.origin.x, frame.origin.y + self.amountKeyboardSlide, frame.size.width, frame.size.height);
                         }
                         completion:nil];
    }
}
- (int)keyboardPosition
{
    int result = 0;
    
    float viewHeight = self.view.frame.size.height;
    float textFieldPosition = self.buttonSignIn.frame.origin.y + self.buttonSignIn.frame.size.height + kKeyboardMargin;
    int amount = (int)viewHeight - (int)textFieldPosition;
    
    if (amount < kKeyboardHeight) result = kKeyboardHeight - amount;
    
    return result;
}


#pragma mark - Sign In

- (IBAction)signInTapped:(id)sender {
    
    if ([self isFormValid]) {
        
        [self dismissKeyboard:sender];
        [SVProgressHUD showWithStatus:kString_SigningIn];
        [self signInWithUsername:self.textFieldEmail.text WithPassword:self.textFieldPassword.text];
        
    }
    
}

- (BOOL)isFormValid{
    
    BOOL valid = YES;
    
    if ([self isEmailValid] == NO){
        
        [ACSAlertViewManager showAlertWithTitle:@"" WithMessage:kString_ErrorUsername];
        valid = NO;
        
    }
    else if ([self isPasswordValid] == NO){
        
        [ACSAlertViewManager showAlertWithTitle:@"" WithMessage:kString_ErrorPassword];
        valid = NO;
        
    }
    
    return valid;
    
}

- (BOOL)isEmailValid{
    
    return ![self.textFieldEmail.text isEqualToString:@""];
    
}

- (BOOL)isPasswordValid{
    
    return ![self.textFieldPassword.text isEqualToString:@""];
    
}

- (void)signInWithUsername:(NSString *)username WithPassword:(NSString *)password{
    
    [ACSDataManager loginWithUsername:username password:password block:^(BOOL success, NSError *error) {
        
        [SVProgressHUD dismiss];
        
        if (success == YES) {
            
            if (self != nil) {
                if (self.presentingViewController.presentingViewController != nil) {
                    [self.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                } else {
                    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                }
                //[self dismissViewControllerAnimated:YES completion:^{ }];
            }
            
        }else{
            
            [ACSAlertViewManager showAlertWithTitle:kString_TitleSignInFail WithMessage:kString_MessageSignInFail];
            
        }
        
    }];
    
}

- (IBAction)needHelpTapped:(id)sender {
    NSString *helpUrl = [[NSUserDefaults standardUserDefaults] stringForKey:kSettingKey_HelpUrl];
    if (helpUrl)
    {
        id tracker = [[GAI sharedInstance] defaultTracker];
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:kAnalyticsScreenNameSignIn action:kAnalyticsCategoryButtonPressed label:@"Help" value:nil] build]];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:helpUrl]];
    }
}


@end
