//
//  SecKeyWrapper+Utils.m
//  Tiqr
//
//  Created by Fabrice Dewasmes on 7/21/14.
//  Copyright (c) 2014 Egeniq. All rights reserved.
//

#import "SecKeyWrapper+Utils.h"
#import "IdentityProvider.h"

@implementation SecKeyWrapper (Utils)

+(void)resetKeychain {
    [self deleteAllKeysForSecClass:kSecClassGenericPassword];
    [self deleteAllKeysForSecClass:kSecClassInternetPassword];
    [self deleteAllKeysForSecClass:kSecClassCertificate];
    [self deleteAllKeysForSecClass:kSecClassKey];
    [self deleteAllKeysForSecClass:kSecClassIdentity];
}

+(void)deleteAllKeysForSecClass:(CFTypeRef)secClass {
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    [dict setObject:(__bridge id)secClass forKey:(__bridge id)kSecClass];
    OSStatus result = SecItemDelete((__bridge CFDictionaryRef) dict);
    NSAssert(result == noErr || result == errSecItemNotFound, @"Error deleting keychain data (%ld)", result);
}

+(void)printKeychain{
    NSLog(@"------- KEYCHAIN -------");
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  (__bridge id)kCFBooleanTrue, (__bridge id)kSecReturnAttributes,
                                  (__bridge id)kSecMatchLimitAll, (__bridge id)kSecMatchLimit,
                                  nil];
    
    NSArray *secItemClasses = [NSArray arrayWithObjects:
                               (__bridge id)kSecClassGenericPassword,
                               (__bridge id)kSecClassInternetPassword,
                               (__bridge id)kSecClassCertificate,
                               (__bridge id)kSecClassKey,
                               (__bridge id)kSecClassIdentity,
                               nil];
    for (id secItemClass in secItemClasses) {
        [query setObject:secItemClass forKey:(__bridge id)kSecClass];
        CFTypeRef result = NULL;
        SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
        NSLog(@"%@", (__bridge id)result);
        if (result != NULL) CFRelease(result);
    }
    NSLog(@"------- END KEYCHAIN -------");
}

-(void)setIdentity:(Identity *)identity{
    [self setIdentityIdentifier:identity.identifier identityProviderIdentifier:identity.identityProvider.identifier];
}

-(void)setIdentityIdentifier:(NSString *)identityIdentifier identityProviderIdentifier:(NSString *)identityProviderIdentifier{
    NSString *privtag = [NSString stringWithFormat:@"TIQRPRIV%@%@",identityIdentifier, identityProviderIdentifier];
    NSString *pubtag = [NSString stringWithFormat:@"TIQRPUB%@%@",identityIdentifier, identityProviderIdentifier];
    [self setPublicTag:[pubtag dataUsingEncoding:NSUTF8StringEncoding]];
    [self setPrivateTag:[privtag dataUsingEncoding:NSUTF8StringEncoding]];
}
@end
