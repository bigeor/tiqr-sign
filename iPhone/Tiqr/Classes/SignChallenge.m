//
//  SignChallenge.m
//  Tiqr
//
//  Created by Fabrice Dewasmes on 7/16/14.
//  Copyright (c) 2014 Neopixl. All rights reserved.
//

#import "SignChallenge-Protected.h"
#import "IdentityProvider+Utils.h"
#import "Identity+Utils.h"
#import "SecKeyWrapper+Utils.h"
#import "NSString+Hex.h"
#import "NSData+Hex.h"


@implementation SignChallenge


- (void)parseRawChallengeWithSuccessBlock:(void(^)(void))successBlock failureBlock:(void(^)(void))failureBlock{
    self.scheme = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TIQRSignURLScheme"];
    [super parseRawChallengeWithSuccessBlock:successBlock failureBlock:failureBlock];
}

-(NSData *)performCryptoOperation{
    if (self.result == ChallengeResultCancelled){
        return nil;
    }
    [[SecKeyWrapper sharedWrapper] setIdentity:self.identity];
    OSStatus status;
    if (self.inputData == nil){
        self.result = ChallengeResultError;
        return nil;
    }
    NSData *result = [[SecKeyWrapper sharedWrapper] getSignatureBytes:self.inputData status:&status];
    if (status == noErr){
        self.result = ChallengeResultOK;
    } else {
        self.result = ChallengeResultError;
    }
    return result;
}

-(NSString *)url{
    return self.identityProvider.signatureUrl;
}

@end
