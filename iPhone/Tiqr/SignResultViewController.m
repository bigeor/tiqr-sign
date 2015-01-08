    //
//  SignResultViewController.m
//  Tiqr
//
//  Created by Fabrice Dewasmes on 7/18/14.
//  Copyright (c) 2014 Egeniq. All rights reserved.
//

#import "SignResultViewController.h"
#import "MBProgressHUD.h"
#import "ErrorViewController.h"
#import "Identity+Utils.h"
#import "FooterController.h"
#import "TiqrAppDelegate.h"
#import "SignChallenge.h"
#import "DecryptChallenge.h"

@interface SignResultViewController () <UINavigationControllerDelegate>
@property (retain, nonatomic) IBOutlet UIImageView *checkMarkView;
@property (retain, nonatomic) IBOutlet UILabel *confirmationLabel;
@property (nonatomic, retain) FooterController *footerController;
@property (nonatomic, retain) CryptoChallenge *challenge;
@property (nonatomic, copy) NSString *response;

@property (nonatomic, assign) UINavigationController *currentNavigationController;

@end


@implementation SignResultViewController {
    BOOL didAppear;
    NSMutableArray *viewControllersToPush;
}

- (id)initWithSignChallenge:(CryptoChallenge *)challenge {
    self = [super init];
    if (self != nil) {
        self.challenge = challenge;
        self.footerController = [[[FooterController alloc] init] autorelease];
        
        didAppear = NO;
        viewControllersToPush = [[NSMutableArray alloc] init];
    }
	
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        didAppear = NO;
        viewControllersToPush = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self.challenge isKindOfClass:[SignChallenge class]]){
        self.confirmationLabel.text = NSLocalizedString(@"successfully_signed", @"Sign success confirmation message");
        self.title = NSLocalizedString(@"sign_title", @"Sign title");
    } else if ([self.challenge isKindOfClass:[DecryptChallenge class]]){
        self.confirmationLabel.text = NSLocalizedString(@"successfully_decrypted", @"Decryption success confirmation message");
        self.title = NSLocalizedString(@"decrypt_title", @"Decrypt title");
    }

    UIBarButtonItem *backButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)] autorelease];
    self.navigationItem.leftBarButtonItem = backButton;
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    [self setCurrentNavigationController:[self navigationController]];
    
    [self.footerController addToView:self.view];

    [_confirmationLabel setAlpha:0.0];
    
    self.checkMarkView.alpha = 0.0;
    self.checkMarkView.transform = CGAffineTransformMakeScale(0.7, 0.7);
    [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];    
    // Do any additional setup after loading the view from its nib.
    CryptoConfirmationRequest *request = [[CryptoConfirmationRequest alloc] initWithChallenge:self.challenge response:self.response];
    request.delegate = self;
    [request send];
}

- (void)done {
    [(TiqrAppDelegate *)[UIApplication sharedApplication].delegate popToStartViewControllerAnimated:YES];
}

- (void)tiqrRequestDidFinish:(CryptoConfirmationRequest *)request{
    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    [UIView animateWithDuration:0.8 animations:^{
        [_confirmationLabel setAlpha:1.0];

        self.checkMarkView.alpha = 1.0;
        self.checkMarkView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    }];
}

- (void)tiqrRequest:(CryptoConfirmationRequest *)request didFailWithError:(NSError *)error{
        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    [request release];
    
    switch ([error code]) {
        case TIQRSCRAccountBlockedError: {
            //self.challenge.identity.blocked = [NSNumber numberWithBool:YES];
            [self.managedObjectContext save:nil];
            UIViewController *viewController = [[ErrorViewController alloc] initWithTitle:self.title errorTitle:[error localizedDescription] errorMessage:[error localizedFailureReason]];
            
            // see navigationController:didShowViewController: implementation
            if(didAppear) {
                [self.navigationController pushViewController:viewController animated:NO];
            }
            else {
                [viewControllersToPush addObject:viewController];
            }
            
            [viewController release];
            break;
        }
        case TIQRSCRConnectionError:
        case TIQRSCRAccountBlockedErrorTemporary:
        case TIQRSCRInvalidResponseError:
        default: {
            
            UIViewController *viewController = [[ErrorViewController alloc] initWithTitle:self.title errorTitle:[error localizedDescription] errorMessage:[error localizedFailureReason]];
            
            // see navigationController:didShowViewController: implementation
            if(didAppear) {
                [self.navigationController pushViewController:viewController animated:NO];
            }
            else {
                [viewControllersToPush addObject:viewController];
            }
            
            
            [viewController release];
        }
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[self navigationController] setDelegate:self];

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    //Not the best way, but a simple trick to keep a reference (non retained) to the navigation controller
    //because it has already been set to nil
    [_currentNavigationController setDelegate:nil];
    
}

- (void)dealloc {
    [_confirmationLabel release];
    [_checkMarkView release];
    [viewControllersToPush release];
    [_footerController release];
    [_challenge release];
    
    _currentNavigationController = nil;
    
    [super dealloc];
}
- (void)viewDidUnload {
    [self setConfirmationLabel:nil];
    [self setCheckMarkView:nil];
    [super viewDidUnload];
}

#pragma mark - UINavigationController delegate methods

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    if(viewController==self) {
        didAppear = YES;
        
        if([viewControllersToPush count]>0) {
            
            int64_t delay = 0.2; // In seconds
            dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
            
            dispatch_after(time, dispatch_get_main_queue(), ^{
                for(UIViewController *viewController in viewControllersToPush) {
                    [[self navigationController] pushViewController:viewController
                                                           animated:NO];
                }
                
                [viewControllersToPush removeAllObjects];
            });
        }
    }

}

@end
