//
//  SecKeyWrapper+Utils.h
//  Tiqr
//
//  Created by Fabrice Dewasmes on 7/21/14.
//  Copyright (c) 2014 Egeniq. All rights reserved.
//

#import "SecKeyWrapper.h"
#import "Identity.h"

@interface SecKeyWrapper (Utils)
+(void)resetKeychain;
+(void)printKeychain;
-(void)setIdentity:(Identity *)identity;
-(void)setIdentityIdentifier:(NSString *)identityIdentifier identityProviderIdentifier:(NSString *)identityProviderIdentifier;
@end
