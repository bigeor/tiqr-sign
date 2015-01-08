/*
 * Copyright (c) 2010-2011 SURFnet bv
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of SURFnet bv nor the names of its contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "TiQRRequest.h"
#import "NotificationRegistration.h"
#import "JSONKit.h"

#import <Security/Security.h>

#import "AuthenticationChallenge.h"

NSString *const TIQRRErrorDomain = @"org.tiqr.acr";
NSString *const TIQRRAttemptsLeftErrorKey = @"AttempsLeftErrorKey";

@interface TiQRRequest ()



@property (nonatomic, retain) Challenge *challenge;
@property (nonatomic, copy) NSString *response;
@property (nonatomic, retain) NSMutableData *data;
@property (nonatomic, copy) NSString *protocolVersion;

@property (nonatomic, retain) NSURLConnection *currentUrlConnection;

@end

@implementation TiQRRequest

@synthesize delegate=delegate_;
@synthesize challenge=challenge_;
@synthesize response=response_;
@synthesize data=data_;

- (id)initWithChallenge:(Challenge *)challenge response:(NSString *)response {
    self = [super init];
    if (self != nil) {
        self.challenge = challenge;
        self.response = response;
    }
    
    return self;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.data setLength:0];
    
    NSDictionary* headers = [(NSHTTPURLResponse *)response allHeaderFields];
    if ([headers objectForKey:@"X-TIQR-Protocol-Version"]) {
        self.protocolVersion = [headers objectForKey:@"X-TIQR-Protocol-Version"];
    } else {
        self.protocolVersion = @"1";
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.data appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)connectionError {
    [self setCurrentUrlConnection:nil];
    self.data = nil;
    
    NSString *title = NSLocalizedString(@"no_connection", @"No connection error title");
    NSString *message = NSLocalizedString(@"no_active_internet_connection.", @"You appear to have no active Internet connection.");
    NSMutableDictionary *details = [NSMutableDictionary dictionary];
    [details setValue:title forKey:NSLocalizedDescriptionKey];
    [details setValue:message forKey:NSLocalizedFailureReasonErrorKey];
    [details setValue:connectionError forKey:NSUnderlyingErrorKey];
    
    NSError *error = [NSError errorWithDomain:TIQRRErrorDomain code:TIQRRConnectionError userInfo:details];
    [self.delegate tiqrRequest:self didFailWithError:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    if (self.protocolVersion != nil && [self.protocolVersion intValue] > 1) {
        // Parse JSON result
        NSDictionary *result = [[JSONDecoder decoder] objectWithData:self.data];
        self.data = nil;
        
        NSInteger responseCode = [[result valueForKey:@"responseCode"] intValue];
        if (responseCode == ChallengeResponseCodeSuccess) {
            [self success:result];
            [self.delegate tiqrRequestDidFinish:self];
        } else {
            NSError *error = [self parseErrorResponse:responseCode responseBody:result];
            [self.delegate tiqrRequest:self didFailWithError:error];
        }
    } else {
        // Parse String result
        NSString *response = [[NSString alloc] initWithBytes:[self.data bytes] length:[self.data length] encoding:NSUTF8StringEncoding];
        if ([response isEqualToString:@"OK"]) {
            [self.delegate tiqrRequestDidFinish:self];
        } else {
            NSError *error = [self parseV1ErrorResponse:response];
            [self.delegate tiqrRequest:self didFailWithError:error];
        }
        [response release];
    }
    
    [self setCurrentUrlConnection:nil];
}

-(void)success:(NSDictionary *)body{
    
}

-(NSError *)parseErrorResponse:(NSInteger)responseCode responseBody:(NSDictionary *)body{
    NSInteger code = TIQRRUnknownError;
    NSString *title = NSLocalizedString(@"unknown_error", @"Unknown error title");
    NSString *message = NSLocalizedString(@"error_auth_unknown_error", @"Unknown error message");
    NSNumber *attemptsLeft = nil;
    if (responseCode == ChallengeResponseCodeAccountBlocked) {
        if ([body valueForKey:@"duration"] != nil) {
            NSNumber *duration = [NSNumber numberWithInt:[[body valueForKey:@"duration"] intValue]];
            code = TIQRRAccountBlockedErrorTemporary;
            title = NSLocalizedString(@"error_auth_account_blocked_temporary_title", @"INVALID_RESPONSE error title (account blocked temporary)");
            message = [NSString stringWithFormat:NSLocalizedString(@"error_auth_account_blocked_temporary_message", @"INVALID_RESPONSE error message (account blocked temporary"), duration];
        } else {
            code = TIQRRAccountBlockedError;
            title = NSLocalizedString(@"error_auth_account_blocked_title", @"INVALID_RESPONSE error title (0 attempts left)");
            message = NSLocalizedString(@"error_auth_account_blocked_message", @"INVALID_RESPONSE error message (0 attempts left)");
        }
    } else if (responseCode == ChallengeResponseCodeInvalidChallenge) {
        code = TIQRRInvalidChallengeError;
        title = NSLocalizedString(@"error_auth_invalid_challenge_title", @"INVALID_CHALLENGE error title");
        message = NSLocalizedString(@"error_auth_invalid_challenge_message", @"INVALID_CHALLENGE error message");
    } else if (responseCode == ChallengeResponseCodeInvalidRequest) {
        code = TIQRRInvalidRequestError;
        title = NSLocalizedString(@"error_auth_invalid_request_title", @"INVALID_REQUEST error title");
        message = NSLocalizedString(@"error_auth_invalid_request_message", @"INVALID_REQUEST error message");
    } else if (responseCode == ChallengeResponseCodeInvalidUsernamePasswordPin) {                    code = TIQRRInvalidResponseError;
        if ([body valueForKey:@"attemptsLeft"] != nil) {
            attemptsLeft = [NSNumber numberWithInt:[[body valueForKey:@"attemptsLeft"] intValue]];
            if ([attemptsLeft intValue] > 1) {
                title = NSLocalizedString(@"error_auth_wrong_pin", @"INVALID_RESPONSE error title (> 1 attempts left)");
                message = NSLocalizedString(@"error_auth_x_attempts_left", @"INVALID_RESPONSE error message (> 1 attempts left)");
                message = [NSString stringWithFormat:message, [attemptsLeft intValue]];
            } else if ([attemptsLeft intValue] == 1) {
                title = NSLocalizedString(@"error_auth_wrong_pin", @"INVALID_RESPONSE error title (1 attempt left)");
                message = NSLocalizedString(@"error_auth_one_attempt_left", @"INVALID_RESPONSE error message (1 attempt left)");
            } else {
                title = NSLocalizedString(@"error_auth_account_blocked_title", @"INVALID_RESPONSE error title (0 attempts left)");
                message = NSLocalizedString(@"error_auth_account_blocked_message", @"INVALID_RESPONSE error message (0 attempts left)");
            }
        } else {
            title = NSLocalizedString(@"error_auth_wrong_pin", @"INVALID_RESPONSE error title (infinite attempts left)");
            message = NSLocalizedString(@"error_auth_infinite_attempts_left", @"INVALID_RESPONSE erorr message (infinite attempts left)");
        }
        
    } else if (responseCode == ChallengeResponseCodeInvalidUser) {
        code = TIQRRInvalidUserError;
        title = NSLocalizedString(@"error_auth_invalid_account", @"INVALID_USERID error title");
        message = NSLocalizedString(@"error_auth_invalid_account_message", @"INVALID_USERID error message");
    }
    
    NSString *serverMessage = [body valueForKey:@"message"];
    if (serverMessage) {
        message = serverMessage;
    }
    
    NSMutableDictionary *details = [NSMutableDictionary dictionary];
    [details setValue:title forKey:NSLocalizedDescriptionKey];
    [details setValue:message forKey:NSLocalizedFailureReasonErrorKey];
    if (attemptsLeft != nil) {
        [details setValue:attemptsLeft forKey:TIQRRAttemptsLeftErrorKey];
    }
    
    NSError *error = [NSError errorWithDomain:TIQRRErrorDomain code:code userInfo:details];
    return error;
}

- (NSError *)parseV1ErrorResponse:(NSString *)response{
    NSInteger code = TIQRRUnknownError;
    NSString *title = NSLocalizedString(@"unknown_error", @"Unknown error title");
    NSString *message = NSLocalizedString(@"error_auth_unknown_error", @"Unknown error message");
    NSNumber *attemptsLeft = nil;
    if ([response isEqualToString:@"ACCOUNT_BLOCKED"]) {
        code = TIQRRAccountBlockedError;
        title = NSLocalizedString(@"error_auth_account_blocked_title", @"INVALID_RESPONSE error title (0 attempts left)");
        message = NSLocalizedString(@"error_auth_account_blocked_message", @"INVALID_RESPONSE error message (0 attempts left)");
    } else if ([response isEqualToString:@"INVALID_CHALLENGE"]) {
        code = TIQRRInvalidChallengeError;
        title = NSLocalizedString(@"error_auth_invalid_challenge_title", @"INVALID_CHALLENGE error title");
        message = NSLocalizedString(@"error_auth_invalid_challenge_message", @"INVALID_CHALLENGE error message");
    } else if ([response isEqualToString:@"INVALID_REQUEST"]) {
        code = TIQRRInvalidRequestError;
        title = NSLocalizedString(@"error_auth_invalid_request_title", @"INVALID_REQUEST error title");
        message = NSLocalizedString(@"error_auth_invalid_request_message", @"INVALID_REQUEST error message");
    } else if ([response length]>=17 && [[response substringToIndex:17] isEqualToString:@"INVALID_RESPONSE:"]) {
        attemptsLeft = [NSNumber numberWithInt:[[response substringFromIndex:17] intValue]];
        code = TIQRRInvalidResponseError;
        if ([attemptsLeft intValue] > 1) {
            title = NSLocalizedString(@"error_auth_wrong_pin", @"INVALID_RESPONSE error title (> 1 attempts left)");
            message = NSLocalizedString(@"error_auth_x_attempts_left", @"INVALID_RESPONSE error message (> 1 attempts left)");
            message = [NSString stringWithFormat:message, [attemptsLeft intValue]];
        } else if ([attemptsLeft intValue] == 1) {
            title = NSLocalizedString(@"error_auth_wrong_pin", @"INVALID_RESPONSE error title (1 attempt left)");
            message = NSLocalizedString(@"error_auth_one_attempt_left", @"INVALID_RESPONSE error message (1 attempt left)");
        } else {
            title = NSLocalizedString(@"error_auth_account_blocked_title", @"INVALID_RESPONSE error title (0 attempts left)");
            message = NSLocalizedString(@"error_auth_account_blocked_message", @"INVALID_RESPONSE error message (0 attempts left)");
        }
    } else if ([response isEqualToString:@"INVALID_USERID"]) {
        code = TIQRRInvalidUserError;
        title = NSLocalizedString(@"error_auth_invalid_account", @"INVALID_USERID error title");
        message = NSLocalizedString(@"error_auth_invalid_account_message", @"INVALID_USERID error message");
    }
    
    NSMutableDictionary *details = [NSMutableDictionary dictionary];
    [details setValue:title forKey:NSLocalizedDescriptionKey];
    [details setValue:message forKey:NSLocalizedFailureReasonErrorKey];
    if (attemptsLeft != nil) {
        [details setValue:attemptsLeft forKey:TIQRRAttemptsLeftErrorKey];
    }
    
    NSError *error = [NSError errorWithDomain:TIQRRErrorDomain code:code userInfo:details];
    return error;
}

- (void)send {
    NSString *body = [self requestBody];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[self requestURL]];
	[request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
	[request setTimeoutInterval:5.0];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:TIQR_PROTOCOL_VERSION forHTTPHeaderField:@"X-TIQR-Protocol-Version"];
    
    self.data = [NSMutableData data];
	NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [self setCurrentUrlConnection:urlConnection];
    [urlConnection release];
    [request release];
}

- (void)sendCancel {
    [self.challenge cancel];
	[self send];
}

-(NSString *)requestBody{
    return @"";
}

-(NSURL *)requestURL{
    return nil;
}

- (void)dealloc {
    self.challenge = nil;
    self.response = nil;
    self.data = nil;
    [_currentUrlConnection release], _currentUrlConnection = nil;
    [super dealloc];
}

#pragma mark - NSURLConnection

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {

    OSStatus            err;
    BOOL                allowConnection;
    CFArrayRef          policies;
    //NSMutableArray *    certificates;
    SecTrustRef         newTrust;
    SecTrustResultType  newTrustResult = kSecTrustResultOtherError;
    
    allowConnection = NO;
    
    policies = NULL;
    newTrust = NULL;
    
    IdentityProvider *identityProvider = nil;
    
    //trick to get identityProvider
    if([[self challenge] respondsToSelector:@selector(identityProvider)]) {
        identityProvider = [[self challenge] performSelector:@selector(identityProvider)
                                                  withObject:nil];
    }
    
    do
    {
        SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
        if (serverTrust == nil)
            break; // failed
        
        SecCertificateRef certRef = nil;
        
        NSData *serverCertificate = [identityProvider serverCertificate];
        
        if([serverCertificate length]>0) {
            certRef = SecCertificateCreateWithData(kCFAllocatorDefault, (CFDataRef)serverCertificate);
        }

        if (certRef == nil) {
            
            NSString *title = NSLocalizedString(@"unkown_error", @"Unknown error");
            NSString *message = NSLocalizedString(@"error_auth_unknown_identity_provider.", @"Unknown identity provider, please enrol first");
            NSMutableDictionary *details = [NSMutableDictionary dictionary];
            [details setValue:title forKey:NSLocalizedDescriptionKey];
            [details setValue:message forKey:NSLocalizedFailureReasonErrorKey];
            
            NSError *error = [NSError errorWithDomain:TIQRRErrorDomain code:TIQRRConnectionError userInfo:details];
            
            if([delegate_ respondsToSelector:@selector(tiqrRequest:didFailWithError:)]) {
                [delegate_ tiqrRequest:self didFailWithError:error];
            }
                        
            break; // failed
        }
        
        SecCertificateRef evalCertArray[1] = { certRef }; //1
        CFArrayRef cfCertRef = CFArrayCreate ((CFAllocatorRef) NULL,(void *)evalCertArray, 1, &kCFTypeArrayCallBacks);

        SecPolicyRef searchRef = SecPolicyCreateSSL(true, (CFStringRef)challenge.protectionSpace.host);
        
        err = SecTrustCreateWithCertificates(
                                             cfCertRef,
                                             searchRef,
                                             &newTrust
                                             );
        
        if(err == noErr) {
            err = SecTrustSetAnchorCertificates(newTrust, cfCertRef);
        }
        
        if (err == noErr) {
            err = SecTrustEvaluate(newTrust, &newTrustResult);
        }
        
        if(newTrustResult==kSecTrustResultRecoverableTrustFailure) {
            CFDataRef errDataRef = SecTrustCopyExceptions(newTrust);
            
            SecTrustSetExceptions(newTrust, errDataRef);
            SecTrustEvaluate(newTrust, &newTrustResult);
            
            CFRelease(errDataRef);
        }
        
        
        if (err == noErr) {
            allowConnection = (newTrustResult == kSecTrustResultProceed) ||
            (newTrustResult == kSecTrustResultUnspecified);
        }
        
        NSURLCredential *newCredential = [NSURLCredential credentialForTrust:newTrust];
        
        CFRelease(newTrust);
        
        if (allowConnection) {
            // Athentication succeeded:
            
            return [[challenge sender] useCredential:newCredential
                          forAuthenticationChallenge:challenge];
        } else {
            break;
        }
    } while (0);
    
    // Authentication failed:
    return [[challenge sender] cancelAuthenticationChallenge:challenge];
}



@end
