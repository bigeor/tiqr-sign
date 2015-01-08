/*
 * Copyright (c) 2014 Neopixl SA
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

#import "SignPINViewController.h"
#import "DataToSignViewController.h"
#import "OCRAWrapper.h"
#import "OCRAWrapper_v1.h"
#import "SecretStore.h"
#import "MBProgressHUD.h"
#import "Identity+Utils.h"
#import "ErrorViewController.h"
#import "OCRAProtocol.h"
#import "CryptoChallenge-Protected.h"

@interface SignPINViewController ()

@property (nonatomic, retain) CryptoChallenge *challenge;
@property (nonatomic, copy) NSString *response;
@property (nonatomic, copy) NSString *PIN;

@end

@implementation SignPINViewController

@synthesize managedObjectContext=managedObjectContext_;
@synthesize challenge=challenge_;
@synthesize response=response_;

- (id)initWithSignChallenge:(CryptoChallenge *)challenge {
    self = [super init];
    if (self != nil) {
        self.challenge = challenge;
        self.delegate = self;
    }
	
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"enter_pin", @"PIN");
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"enter_pin", @"Sign PIN back button title") style:UIBarButtonItemStyleBordered target:nil action:nil] autorelease];
    self.subtitle = NSLocalizedString(@"login_intro", @"Authentication PIN title");
    self.description = NSLocalizedString(@"enter_four_digit_pin", @"You need to enter your 4-digit PIN to login.");
}

- (void)tiqrRequestDidFinish:(CryptoDataRequest *)request {
    [self.challenge.identity upgradeWithPIN:self.PIN];
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        // Hmm, saving failed, but keychain has already been updated!
        NSLog(@"Saving error after upgrade: %@", error);
    }
    self.PIN = nil;

	[MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];    
    [request release];
    DataToSignViewController *viewController = [[DataToSignViewController alloc] initWithSignChallenge:self.challenge];
    viewController.managedObjectContext = self.managedObjectContext;
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];   
}

- (void)tiqrRequest:(CryptoDataRequest *)request didFailWithError:(NSError *)error {
    self.PIN = nil;

	[MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    [request release];
    
    switch ([error code]) {
        case TIQRSCRConnectionError:{
            UIViewController *viewController = [[ErrorViewController alloc] initWithTitle:self.title errorTitle:[error localizedDescription] errorMessage:[error localizedFailureReason]];
            [self.navigationController pushViewController:viewController animated:YES];
            [viewController release];
            break;
        }
        case TIQRSCRAccountBlockedErrorTemporary: {
            UIViewController *viewController = [[ErrorViewController alloc] initWithTitle:self.title errorTitle:[error localizedDescription] errorMessage:[error localizedFailureReason]];
            [self.navigationController pushViewController:viewController animated:YES];
            [viewController release];
            break;
        }
        case TIQRSCRAccountBlockedError: {
            //self.challenge.identity.blocked = [NSNumber numberWithBool:YES];
            [self.managedObjectContext save:nil];
            UIViewController *viewController = [[ErrorViewController alloc] initWithTitle:self.title errorTitle:[error localizedDescription] errorMessage:[error localizedFailureReason]];
            [self.navigationController pushViewController:viewController animated:YES];
            [viewController release];
            break;
        }            
        case TIQRSCRInvalidResponseError: {
            NSNumber *attemptsLeft = [[error userInfo] objectForKey:TIQRRAttemptsLeftErrorKey];
            if (attemptsLeft != nil && [attemptsLeft intValue] == 0) {
                [self.managedObjectContext save:nil];
                UIViewController *viewController = [[ErrorViewController alloc] initWithTitle:self.title errorTitle:[error localizedDescription] errorMessage:[error localizedFailureReason]];
                [self.navigationController pushViewController:viewController animated:YES];
                [viewController release];
            } else {
                [self clear];
                [self showErrorWithTitle:[error localizedDescription] message:[error localizedFailureReason]];
            }
            break;
        }
        default: {
            UIViewController *viewController = [[ErrorViewController alloc] initWithTitle:self.title errorTitle:[error localizedDescription] errorMessage:[error localizedFailureReason]];
            [self.navigationController pushViewController:viewController animated:YES];
            [viewController release];
        }
    }
}

- (NSString *)calculateOTPResponseForPIN:(NSString *)PIN {
	SecretStore *store = [SecretStore secretStoreForIdentity:self.challenge.identity.identifier identityProvider:self.challenge.identityProvider.identifier];
    
    NSObject<OCRAProtocol> *ocra;
    if (self.challenge.protocolVersion && [self.challenge.protocolVersion intValue] >= 2) {
        ocra = [[OCRAWrapper alloc] init];
    } else {
        ocra = [[OCRAWrapper_v1 alloc] init];
    }
    
    NSError *error = nil;
    NSString *response = [ocra generateOCRA:self.challenge.identityProvider.ocraSuite secret:[store secretForPIN:PIN salt:self.challenge.identity.salt initializationVector:self.challenge.identity.initializationVector] challenge:self.challenge.challenge sessionKey:self.challenge.sessionKey error:&error];
    if (response == nil) {
        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
        UIViewController *viewController = [[ErrorViewController alloc] 
                                            initWithTitle:@"Error" 
                                            errorTitle:[error localizedDescription] 
                                            errorMessage:[error localizedFailureReason]];
        [self.navigationController pushViewController:viewController animated:YES];
        [viewController release];
    }

    return response;
}

- (void)PINViewController:(PINViewController *)pinViewController didFinishWithPIN:(NSString *)PIN {
    self.response = [self calculateOTPResponseForPIN:PIN];
    if (self.response == nil) {
        return;
    }
    self.PIN = PIN;

	[MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];    
    CryptoDataRequest *request = [[CryptoDataRequest alloc] initWithChallenge:self.challenge response:self.response];
    request.delegate = self;
    [request send];
}

- (void)dealloc {
    self.challenge = nil;
    self.response = nil;
    self.managedObjectContext = nil;
    self.PIN = nil;
    [super dealloc];
}

@end