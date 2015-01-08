//
//  CryptoChallenge.m
//  Tiqr
//
//  Created by Fabrice Dewasmes on 7/25/14.
//  Copyright (c) 2014 Egeniq. All rights reserved.
//

#import "CryptoChallenge-Protected.h"


@implementation CryptoChallenge


- (void)parseRawChallengeWithSuccessBlock:(void(^)(void))successBlock failureBlock:(void(^)(void))failureBlock{
    [super parseRawChallengeWithSuccessBlock:successBlock failureBlock:failureBlock];
    
}

-(NSData *)performCryptoOperation{
    NSAssert(YES, @"You shouldn't try to perform this operation directly rather than using subclasses redefinition.");
    return nil;
}




@end
