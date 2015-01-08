//
//  MultiIdentitiesChallenge-Protected.h
//  Tiqr
//
//  Created by Fabrice Dewasmes on 7/21/14.
//  Copyright (c) 2014 Egeniq. All rights reserved.
//


#import "MultiIdentitiesChallenge.h"

@interface MultiIdentitiesChallenge ()

@property (nonatomic, retain) IdentityProvider *identityProvider;
@property (nonatomic, retain) NSArray *identities;
@property (nonatomic, copy) NSString *serviceProviderIdentifier;
@property (nonatomic, copy) NSString *serviceProviderDisplayName;
@property (nonatomic, copy) NSString *sessionKey;
@property (nonatomic, copy) NSString *challenge;
@property (nonatomic, copy) NSString *returnUrl;
@property (nonatomic, copy) NSString *protocolVersion;


@end




