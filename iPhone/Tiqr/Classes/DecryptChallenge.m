//
//  SignChallenge.m
//  Tiqr
//
//  Created by Fabrice Dewasmes on 7/16/14.
//  Copyright (c) 2014 Neopixl. All rights reserved.
//

#import "DecryptChallenge-Protected.h"
#import "IdentityProvider+Utils.h"
#import "Identity+Utils.h"
#import "SecKeyWrapper+Utils.h"
#import "NSString+Hex.h"
#import "NSData+Hex.h"

@implementation DecryptChallenge

- (void)parseRawChallengeWithSuccessBlock:(void(^)(void))successBlock failureBlock:(void(^)(void))failureBlock{
    self.scheme = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TIQRDecryptURLScheme"];
    [super parseRawChallengeWithSuccessBlock:successBlock failureBlock:failureBlock];
}

-(NSData *)performCryptoOperation{
    if (self.result == ChallengeResultCancelled){
        return nil;
    }
    [[SecKeyWrapper sharedWrapper] setIdentity:self.identity];
    OSStatus status;
    NSData *result = [[SecKeyWrapper sharedWrapper] unwrapSymmetricKey:self.inputData status:&status];
    if (status == noErr){
        self.result = ChallengeResultOK;
    } else {
        self.result = ChallengeResultError;
    }
    return result;
}

-(NSString *)url{
    return self.identityProvider.decryptionUrl;
}
@end
