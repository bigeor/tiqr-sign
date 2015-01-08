//
//  TiQRRequest.h
//  Tiqr
//
//  Created by Fabrice Dewasmes on 7/28/14.
//  Copyright (c) 2014 Egeniq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Challenge.h"


/**
 * Error domain.
 */
extern NSString *const TIQRRErrorDomain;

/**
 * Authentication attempts left (NSNumber).
 * 0 means the account is blocked.
 */
extern NSString *const TIQRRAttemptsLeftErrorKey;


enum {
    TIQRRUnknownError = 101,
    TIQRRConnectionError = 201,
    TIQRRInvalidChallengeError = 301,
    TIQRRInvalidRequestError = 302,
    TIQRRInvalidResponseError = 303,
    TIQRRInvalidUserError = 304,
    TIQRRAccountBlockedError = 305,
    TIQRRAccountBlockedErrorTemporary = 306
};

@class TiQRRequest;

@protocol TiQRRequestDelegate <NSObject>

@required
- (void)tiqrRequestDidFinish:(TiQRRequest *)request;
- (void)tiqrRequest:(TiQRRequest *)request didFailWithError:(NSError *)error;

@end

@interface TiQRRequest : NSObject <NSURLConnectionDelegate>{
    
}

@property (nonatomic, assign) id<TiQRRequestDelegate> delegate;

- (id)initWithChallenge:(Challenge *)challenge response:(NSString *)response;
- (void)send;
- (void)sendCancel;
- (void)success:(NSDictionary *)body;
- (NSString *)requestBody;
- (NSURL *)requestURL;


@end
