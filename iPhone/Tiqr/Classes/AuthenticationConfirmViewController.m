/*
 * Copyright (c) 2010-2011 SURFnet bv
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of SURFnet bv nor the names of its contributors 
 *    may be used to endorse or promote products derived from this 
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "AuthenticationConfirmViewController.h"
#import "AuthenticationConfirmViewController-Protected.h"
#import "AuthenticationPINViewController.h"
#import "AuthenticationConfirmationRequest.h"
#import "MBProgressHUD.h"
#import "TiqrAppDelegate.h"
#import "UIColor+TiQR.h"


@interface AuthenticationConfirmViewController ()

@property (nonatomic, retain) AuthenticationChallenge *challenge;
@property (nonatomic, retain) IBOutlet UILabel *loginConfirmLabel;
@property (nonatomic, retain) IBOutlet UILabel *loggedInAsLabel;
@property (nonatomic, retain) IBOutlet UILabel *toLabel;
@property (nonatomic, retain) IBOutlet UIButton *okButton;
@property (retain, nonatomic) IBOutlet UIButton *cancelButton;
@property (nonatomic, assign) BOOL didTappedOk;

@end

@implementation AuthenticationConfirmViewController

@synthesize challenge=challenge_;
@synthesize managedObjectContext=managedObjectContext_;
@synthesize identityProviderLogoImageView=identityProviderLogoImageView_, identityDisplayNameLabel=identityDisplayNameLabel_, identityProviderDisplayNameLabel=identityProviderDisplayNameLabel_, serviceProviderDisplayNameLabel=serviceProviderDisplayNameLabel_, serviceProviderIdentifierLabel=serviceProviderIdentifierLabel_;
@synthesize loginConfirmLabel=loginConfirmLabel_, loggedInAsLabel=loggedInAsLabel_,toLabel=toLabel_, okButton=okButton_;

- (id)initWithAuthenticationChallenge:(AuthenticationChallenge *)challenge {
    self = [super initWithNibName:@"AuthenticationConfirmView" bundle:nil];
	if (self != nil) {
		self.challenge = challenge;
	}
	
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
    self.loginConfirmLabel.text = NSLocalizedString(@"confirm_authentication", @"Are you sure you want to login?");
    self.loggedInAsLabel.text = NSLocalizedString(@"you_will_be_logged_in_as", @"You will be logged in as:");
    self.toLabel.text = NSLocalizedString(@"to_service_provider", @"to:");
    [self.okButton setTitle:NSLocalizedString(@"ok_button", @"OK") forState:UIControlStateNormal];
    self.okButton.layer.borderWidth = 1;
    self.okButton.layer.borderColor = [UIColor defaultTintColor].CGColor;
    self.okButton.layer.cornerRadius = 4;
    
    self.cancelButton.layer.borderWidth = 1;
    self.cancelButton.layer.borderColor = [UIColor defaultTintColor].CGColor;
    self.cancelButton.layer.cornerRadius = 4;
    
    self.title = NSLocalizedString(@"authentication_title", @"Login title");
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"confirm_authentication_title", @"Authentication confirm back button title") style:UIBarButtonItemStyleBordered target:nil action:nil] autorelease];        

	self.identityProviderLogoImageView.image = [[UIImage alloc] initWithData:self.challenge.identityProvider.logo];
	self.identityDisplayNameLabel.text = self.challenge.identity.displayName;
	self.identityProviderDisplayNameLabel.text = self.challenge.identityProvider.displayName;	
	self.serviceProviderDisplayNameLabel.text = self.challenge.serviceProviderDisplayName;
	self.serviceProviderIdentifierLabel.text = self.challenge.serviceProviderIdentifier;
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
}

- (void)ok {
    
    //On the iPhone 4 it may happen that two tap are handled
    //(it means two pushViewController and a crash "nested push animation can result in corrupted navigation bar")
    if(!_didTappedOk) {
        [self setDidTappedOk:YES];
        
        AuthenticationPINViewController *viewController = [[AuthenticationPINViewController alloc] initWithAuthenticationChallenge:self.challenge];
        viewController.managedObjectContext = self.managedObjectContext;
        [self.navigationController pushViewController:viewController animated:YES];
        [viewController release];
    }

}

- (IBAction)cancel:(id)sender {
    AuthenticationConfirmationRequest *request = [[AuthenticationConfirmationRequest alloc] initWithChallenge:self.challenge response:nil];
    [request setDelegate:self];
    [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    [request sendCancel];
}

-(void)tiqrRequestDidFinish:(TiQRRequest *)request{
    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    [(TiqrAppDelegate *)[UIApplication sharedApplication].delegate popToStartViewControllerAnimated:YES];
}

-(void)tiqrRequest:(TiQRRequest *)request didFailWithError:(NSError *)error{
    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    [(TiqrAppDelegate *)[UIApplication sharedApplication].delegate popToStartViewControllerAnimated:YES];
}

- (void)resetOutlets {
	self.identityProviderLogoImageView = nil;
	self.identityDisplayNameLabel = nil;
	self.identityProviderDisplayNameLabel = nil;
	self.serviceProviderDisplayNameLabel = nil;
	self.serviceProviderIdentifierLabel = nil;
    self.loggedInAsLabel = nil;
    self.loginConfirmLabel = nil;
    self.toLabel = nil;
    self.okButton = nil;
}

- (void)viewDidUnload {
    [self resetOutlets];
    [self setCancelButton:nil];
    [super viewDidUnload];
}

- (void)dealloc {
    [self resetOutlets];
    
    self.challenge = nil;
    self.managedObjectContext = nil;

    [_cancelButton release];
    [super dealloc];	
}

@end