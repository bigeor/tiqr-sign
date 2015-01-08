//
//  MultiIdentitiesChallenge.m
//  Tiqr
//
//  Created by Fabrice Dewasmes on 7/21/14.
//  Copyright (c) 2014 Neopixl. All rights reserved.
//

#import "MultiIdentitiesChallenge-Protected.h"
#import "IdentityProvider+Utils.h"
#import "Identity+Utils.h"
#import "SecKeyWrapper+Utils.h"



@implementation MultiIdentitiesChallenge

NSString *const TIQRCErrorDomain = @"org.tiqr.mic";

- (void)parseRawChallengeWithSuccessBlock:(void(^)(void))successBlock failureBlock:(void(^)(void))failureBlock{
    [super parseRawChallengeWithSuccessBlock:successBlock failureBlock:failureBlock];
	NSURL *url = [NSURL URLWithString:self.rawChallenge];
    
	if (url == nil || ![url.scheme isEqualToString:self.scheme] || [url.pathComponents count] < 3) {
        NSString *errorTitle = NSLocalizedString(@"error_auth_invalid_qr_code", @"Invalid QR tag title");
        NSString *errorMessage = NSLocalizedString(@"error_auth_invalid_challenge_message", @"Invalid QR tag message");
        NSDictionary *details = [NSDictionary dictionaryWithObjectsAndKeys:errorTitle, NSLocalizedDescriptionKey, errorMessage, NSLocalizedFailureReasonErrorKey, nil];
        self.error = [NSError errorWithDomain:TIQRCErrorDomain code:TIQRACInvalidQRTagError userInfo:details];
        failureBlock();
		return;
	}
    
	IdentityProvider *identityProvider = [IdentityProvider findIdentityProviderWithIdentifier:url.host inManagedObjectContext:self.managedObjectContext];
	if (identityProvider == nil) {
        NSString *errorTitle = NSLocalizedString(@"error_auth_unknown_identity", @"No account title");
        NSString *errorMessage = NSLocalizedString(@"error_auth_no_identities_for_identity_provider", @"No account message");
        NSDictionary *details = [NSDictionary dictionaryWithObjectsAndKeys:errorTitle, NSLocalizedDescriptionKey, errorMessage, NSLocalizedFailureReasonErrorKey, nil];
        self.error = [NSError errorWithDomain:TIQRCErrorDomain code:TIQRACUnknownIdentityProviderError userInfo:details];
        failureBlock();
		return;
	}
	
	if (url.user != nil) {
		Identity *identity = [Identity findIdentityWithIdentifier:url.user forIdentityProvider:identityProvider inManagedObjectContext:self.managedObjectContext];
		if (identity == nil) {
            NSString *errorTitle = NSLocalizedString(@"error_auth_invalid_account", @"Unknown account title");
            NSString *errorMessage = NSLocalizedString(@"error_auth_invalid_account_message", @"Unknown account message");
            NSDictionary *details = [NSDictionary dictionaryWithObjectsAndKeys:errorTitle, NSLocalizedDescriptionKey, errorMessage, NSLocalizedFailureReasonErrorKey, nil];
            self.error = [NSError errorWithDomain:TIQRCErrorDomain code:TIQRACUnknownIdentityError userInfo:details];
            failureBlock();
            return;
		}
		
		self.identities = [NSArray arrayWithObject:identity];
		self.identity = identity;
	} else {
		NSArray *identities = [Identity findIdentitiesForIdentityProvider:identityProvider inManagedObjectContext:self.managedObjectContext];
		if (identities == nil || [identities count] == 0) {
            NSString *errorTitle = NSLocalizedString(@"error_auth_invalid_account", @"No account title");
            NSString *errorMessage = NSLocalizedString(@"error_auth_invalid_account_message", @"No account message");
            NSDictionary *details = [NSDictionary dictionaryWithObjectsAndKeys:errorTitle, NSLocalizedDescriptionKey, errorMessage, NSLocalizedFailureReasonErrorKey, nil];
            self.error = [NSError errorWithDomain:TIQRCErrorDomain code:TIQRACZeroIdentitiesForIdentityProviderError userInfo:details];
            failureBlock();
            return;
		}
		
		self.identities = identities;
		self.identity = [identities count] == 1 ? [identities objectAtIndex:0] : nil;
	}
	
    if (self.identity != nil && [self.identity.blocked boolValue]) {
        NSString *errorTitle = NSLocalizedString(@"error_auth_account_blocked_title", @"Account blocked title");
        NSString *errorMessage = NSLocalizedString(@"error_auth_account_blocked_message", @"Account blocked message");
        NSDictionary *details = [NSDictionary dictionaryWithObjectsAndKeys:errorTitle, NSLocalizedDescriptionKey, errorMessage, NSLocalizedFailureReasonErrorKey, nil];
        self.error = [NSError errorWithDomain:TIQRCErrorDomain code:TIQRACIdentityBlockedError userInfo:details];
    }
    
    if (self.identity != nil){
        [[SecKeyWrapper sharedWrapper] setIdentity:self.identity];
    }

    
	self.identityProvider = identityProvider;
    self.sessionKey = [url.pathComponents objectAtIndex:1];
    self.challenge = [url.pathComponents objectAtIndex:2];
    if ([url.pathComponents count] > 3) {
        self.serviceProviderDisplayName = [url.pathComponents objectAtIndex:3];
    } else {
        self.serviceProviderDisplayName = NSLocalizedString(@"error_auth_unknown_identity_provider", @"Unknown");
    }
    self.serviceProviderIdentifier = @"";
    
    if ([url.pathComponents count] > 4) {
        self.protocolVersion = [url.pathComponents objectAtIndex:4];
    } else {
        self.protocolVersion = @"1";
    }
    
    NSString *regex = @"^http(s)?://.*";
    NSPredicate *protocolPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    
    if (url.query != nil && [url.query length] > 0 && [protocolPredicate evaluateWithObject:[self decodeURL:url.query]] == YES) {
        self.returnUrl = [self decodeURL:url.query];
    } else {
        self.returnUrl = nil;
    }
    
    if (successBlock != nil){
        successBlock();
    }
}



- (void)dealloc {
	self.identityProvider = nil;
	self.sessionKey = nil;
	self.challenge = nil;
	self.identities = nil;
	self.identity = nil;
	
	[super dealloc];
}

@end
