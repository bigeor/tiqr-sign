//
//  CryptoChallenge-Protected.h
//  Tiqr
//
//  Created by Fabrice Dewasmes on 7/25/14.
//  Copyright (c) 2014 Neopixl. All rights reserved.
//

#import "CryptoChallenge.h"
#import "MultiIdentitiesChallenge-Protected.h"

enum {
    TIQRSCRUnknownError = 101,
    TIQRSCRConnectionError = 201,
    TIQRSCRInvalidChallengeError = 301,
    TIQRSCRInvalidRequestError = 302,
    TIQRSCRInvalidResponseError = 303,
    TIQRSCRInvalidUserError = 304,
    TIQRSCRAccountBlockedError = 305,
    TIQRSCRAccountBlockedErrorTemporary = 306
};

@interface CryptoChallenge ()

@property (nonatomic, copy, readwrite) NSString *inputText;
@property (nonatomic, copy, readwrite) NSData *inputData;


@end