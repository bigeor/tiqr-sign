//
//  MultiIdentitiesChallenge.h
//  Tiqr
//
//  Created by Fabrice Dewasmes on 7/21/14.
//  Copyright (c) 2014 Neopixl. All rights reserved.
//

#import "Challenge-Protected.h"
#import "IdentityProvider.h"
#import "Identity.h"

@interface MultiIdentitiesChallenge : Challenge


/**
 * Error domain.
 */
extern NSString *const TIQRCErrorDomain;

enum {
    TIQRACUnknownError = 101,
    TIQRACInvalidQRTagError = 201,
    TIQRACUnknownIdentityProviderError = 202,
    TIQRACUnknownIdentityError = 203,
    TIQRACZeroIdentitiesForIdentityProviderError = 204,
    TIQRACIdentityBlockedError = 205
};


/**
 * Identity provider.
 */
@property (nonatomic, retain, readonly) IdentityProvider *identityProvider;

/**
 * Identity (might be nil if more than one match).
 */
@property (nonatomic, retain) Identity *identity;

/**
 * Matching identities.
 */
@property (nonatomic, retain, readonly) NSArray *identities;

/**
 * The service provider identifier (probably domain name).
 */
@property (nonatomic, copy, readonly) NSString *serviceProviderIdentifier;

/**
 * The display name for the service provider.
 */
@property (nonatomic, copy, readonly) NSString *serviceProviderDisplayName;

/**
 * Session key.
 */
@property (nonatomic, copy, readonly) NSString *sessionKey;

/**
 * The concerned challenge.
 */
@property (nonatomic, copy, readonly) NSString *challenge;

/**
 * The prefered protocol version the the challenge requires
 */
@property (nonatomic, copy, readonly) NSString *protocolVersion;

@end
