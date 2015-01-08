//
//  CryptoChallenge.h
//  Tiqr
//
//  Created by Fabrice Dewasmes on 7/25/14.
//  Copyright (c) 2014 Neopixl. All rights reserved.
//

#import "MultiIdentitiesChallenge.h"


@interface CryptoChallenge : MultiIdentitiesChallenge

@property (nonatomic, copy, readonly) NSString *inputText;
@property (nonatomic, copy, readonly) NSData *inputData;


-(NSData *)performCryptoOperation;


@end
