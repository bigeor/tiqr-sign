//
//  SignRequest.m
//  Tiqr
//
//  Created by Fabrice Dewasmes on 7/18/14.
//  Copyright (c) 2014 Neopixl. All rights reserved.
//

#import "CryptoConfirmationRequest.h"
#import "JSONKit.h"
#import "NotificationRegistration.h"
#import "NSData+Hex.h"

@interface CryptoConfirmationRequest ()

@property (nonatomic, retain) CryptoChallenge *challenge;
@property (nonatomic, copy) NSString *response;

@end

@implementation CryptoConfirmationRequest

-(NSString *)requestBody{
    NSData *data = [self.challenge performCryptoOperation];
    NSString *escapedSessionKey = [self.challenge.sessionKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
    NSString *response = @"";
    if (data != nil){
        response = [data hexStringValue];
    }
    
	NSString *body = [NSString stringWithFormat:@"sessionKey=%@&response=%@&responseCode=%d", escapedSessionKey, response, [self.challenge result]];
    return body;
}

-(NSURL *)requestURL{
    return [NSURL URLWithString:self.challenge.url];
}
@end

