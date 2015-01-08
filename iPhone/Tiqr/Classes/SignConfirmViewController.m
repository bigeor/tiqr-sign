//
//  SignConfirmViewController.m
//  Tiqr
//
//  Created by Fabrice Dewasmes on 7/16/14.
//  Copyright (c) 2014 Neopixl. All rights reserved.
//

#import "SignConfirmViewController-Protected.h"
#import "SignPINViewController.h"
#import "TiqrAppDelegate.h"
#import "MBProgressHUD.h"
#import "UIColor+TiQR.h"


@interface SignConfirmViewController ()
@property (nonatomic, retain) SignChallenge *challenge;
@end

@implementation SignConfirmViewController

- (id)initWithAuthenticationChallenge:(SignChallenge *)challenge {
    self = [super initWithNibName:@"SignConfirmViewController" bundle:nil];
	if (self != nil) {
		self.challenge = challenge;
	}
	
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([self.challenge isKindOfClass:[SignChallenge class]]){
        self.signConfirmLabel.text = NSLocalizedString(@"confirm_sign", @"Are you sure you want to sign?");
        self.signAsLabel.text = NSLocalizedString(@"you_will_sign_as", @"You will sign as:");
        self.title = NSLocalizedString(@"sign_title", @"Sign");
    } else if ([self.challenge isKindOfClass:[DecryptChallenge class]]){
        self.signConfirmLabel.text = NSLocalizedString(@"confirm_decrypt", @"Are you sure you want to decrypt?");
        self.signAsLabel.text = NSLocalizedString(@"you_will_decrypt_as", @"You will decrypt as:");
        self.title = NSLocalizedString(@"decrypt_title", @"Decrypt");
    }
    self.toLabel.text = NSLocalizedString(@"to_service_provider", @"to:");
    [self.okButton setTitle:NSLocalizedString(@"ok_button", @"OK") forState:UIControlStateNormal];
    self.okButton.layer.borderWidth = 1;
    self.okButton.layer.borderColor = [UIColor defaultTintColor].CGColor;
    self.okButton.layer.cornerRadius = 4;
    
    [self.cancelButton setTitle:NSLocalizedString(@"cancel_button", @"Cancel") forState:UIControlStateNormal];
    self.cancelButton.layer.borderWidth = 1;
    self.cancelButton.layer.borderColor = [UIColor defaultTintColor].CGColor;
    self.cancelButton.layer.cornerRadius = 4;
    
    
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"confirm_authentication_title", @"Authentication confirm back button title") style:UIBarButtonItemStyleBordered target:nil action:nil] autorelease];

    self.identityProviderLogoImageView.image = [[UIImage alloc] initWithData:self.challenge.identityProvider.logo];
    
    self.identityDisplayNameLabel.text = self.challenge.identity.displayName;
	self.identityProviderDisplayNameLabel.text = self.challenge.identityProvider.displayName;
	self.serviceProviderDisplayNameLabel.text = self.challenge.serviceProviderDisplayName;
	self.serviceProviderIdentifierLabel.text = self.challenge.serviceProviderIdentifier;
    
    
    
    // iOS 7
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
}

-(void)viewDidUnload{
    [self resetOutlets];
    [super viewDidUnload];
}

- (void)resetOutlets {
	self.identityProviderLogoImageView = nil;
	self.identityDisplayNameLabel = nil;
	self.identityProviderDisplayNameLabel = nil;
	self.serviceProviderDisplayNameLabel = nil;
	self.serviceProviderIdentifierLabel = nil;
    self.signConfirmLabel = nil;
    self.signAsLabel = nil;
    self.toLabel = nil;
    self.okButton = nil;
    self.cancelButton = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)ok {
    SignPINViewController *viewController = [[SignPINViewController alloc] initWithSignChallenge:self.challenge];
    viewController.managedObjectContext = self.managedObjectContext;
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];
}

- (IBAction)cancel:(id)sender {
    CryptoDataRequest *request = [[CryptoDataRequest alloc] initWithChallenge:self.challenge response:nil];
    [request setDelegate:self];
    [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];    
    [request sendCancel];
}

-(void)tiqrRequestDidFinish:(CryptoDataRequest *)request{
    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    [(TiqrAppDelegate *)[UIApplication sharedApplication].delegate popToStartViewControllerAnimated:YES];
}

-(void)tiqrRequest:(CryptoDataRequest *)request didFailWithError:(NSError *)error{
    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    [(TiqrAppDelegate *)[UIApplication sharedApplication].delegate popToStartViewControllerAnimated:YES];
    
}

- (void)dealloc {
    [_identityProviderLogoImageView release];
    [_identityDisplayNameLabel release];
    [_identityProviderDisplayNameLabel release];
    [_serviceProviderDisplayNameLabel release];
    [_serviceProviderIdentifierLabel release];
    [_signConfirmLabel release];
    [_signAsLabel release];
    [_okButton release];
    [_toLabel release];
    [_challenge release];
    [_managedObjectContext release];
    [_cancelButton release];
    [super dealloc];
}
@end
