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

#import "Challenge-Protected.h"
#import "EnrollmentChallenge.h"
#import "EnrollmentChallenge-Protected.h"
#import "JSONKit.h"
#import "Identity+Utils.h"
#import "IdentityProvider+Utils.h"

typedef void(^successBlock)(NSData *data);
typedef void(^failureBlock)(NSError *error);


NSString *const TIQRECErrorDomain = @"org.tiqr.ec";

@interface EnrollmentChallenge () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, assign) BOOL allowFiles;
@property (nonatomic, retain) NSURLConnection *currentUrlConnection;

@property (nonatomic, copy) successBlock currentSuccessBlock;
@property (nonatomic, copy) failureBlock currentFailureBlock;
@property (nonatomic, retain) NSMutableData *currentData;

//Private redefinition of accessors
@property (nonatomic, copy) NSData *certificateData;

@end

@implementation EnrollmentChallenge

@synthesize identityProviderIdentifier=identityProviderIdentifier_, identityProviderDisplayName=identityProviderDisplayName_, identityProviderAuthenticationUrl=identityProviderAuthenticationUrl_, identityProviderInfoUrl=indentityProviderInfoUrl_;
@synthesize identityProviderOcraSuite=identityProviderOcraSuite_, identityProviderLogo=identityProviderLogo_, identityProvider=identityProvider_;
@synthesize identityIdentifier=identityIdentifier_, identityDisplayName=identityDisplayName_, identitySecret=identitySecret_, identityPIN=identityPIN_, identity=identity_;
@synthesize enrollmentUrl=enrollmentUrl_;
@synthesize returnUrl=returnUrl_;
@synthesize allowFiles=allowFiles_;
@synthesize identityMetadataUrl=identityMetadataUrl_, identitySignatureUrl=identitySignatureUrl_;

- (id)initWithRawChallenge:(NSString *)challenge managedObjectContext:(NSManagedObjectContext *)context allowFiles:(BOOL)allowFiles {
    self = [super initWithRawChallenge:challenge managedObjectContext:context autoParse:NO];
    if (self != nil) {
        self.scheme = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TIQREnrollmentURLScheme"];
        self.allowFiles = allowFiles;
		//[self parseRawChallengeWithSuccessBlock:nil failureBlock:nil];
	}
	
	return self;
}

- (id)initWithRawChallenge:(NSString *)challenge managedObjectContext:(NSManagedObjectContext *)context {
    return [self initWithRawChallenge:challenge managedObjectContext:context allowFiles:NO];
}

- (BOOL)isValidMetadata:(NSDictionary *)metadata {
    // TODO: service => identityProvider 
	if ([metadata valueForKey:@"service"] == nil ||
		[metadata valueForKey:@"identity"] == nil) {
		return NO;
	}

	// TODO: improve validation
    
	return YES;
}

- (void)downloadAsynchronously:(NSURL *)url success:(successBlock)success failure:(failureBlock)failure {
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [self setCurrentSuccessBlock:success];
    [self setCurrentFailureBlock:failure];
    
    NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [self setCurrentUrlConnection:urlConnection];
    [urlConnection release];
}


- (NSData *)downloadSynchronously:(NSURL *)url error:(NSError **)error {
	NSURLResponse *response = nil;
	NSURLRequest *request = [NSURLRequest requestWithURL:url];

	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:error];
	return data;
}

- (BOOL)assignIdentityProviderMetadata:(NSDictionary *)metadata {
	self.identityProviderIdentifier = [[metadata objectForKey:@"identifier"] description];
	self.identityProvider = [IdentityProvider findIdentityProviderWithIdentifier:self.identityProviderIdentifier inManagedObjectContext:self.managedObjectContext];
    
    if(nil!=_certificateData) {
        [identityProvider_ setServerCertificate:_certificateData];
    }
    
    NSURL *logoUrl = [NSURL URLWithString:[[metadata objectForKey:@"logoUrl"] description]];
	NSError *error = nil;
	NSData *logo = [self downloadSynchronously:logoUrl error:&error];
	if (error != nil) {
        NSString *errorTitle = NSLocalizedString(@"error_enroll_logo_error_title", @"No identity provider logo");
        NSString *errorMessage = NSLocalizedString(@"error_enroll_logo_error", @"No identity provider logo message");
        NSDictionary *details = [NSDictionary dictionaryWithObjectsAndKeys:errorTitle, NSLocalizedDescriptionKey, errorMessage, NSLocalizedFailureReasonErrorKey, error, NSUnderlyingErrorKey, nil];
        self.error = [NSError errorWithDomain:TIQRECErrorDomain code:TIQRECIdentityProviderLogoError userInfo:details];
        return NO;
    }
		
	self.identityProviderDisplayName =  [[metadata objectForKey:@"displayName"] description];
	self.identityProviderAuthenticationUrl = [[metadata objectForKey:@"authenticationUrl"] description];
	self.identityProviderInfoUrl = [[metadata objectForKey:@"infoUrl"] description];
    self.identityProviderOcraSuite = [[metadata objectForKey:@"ocraSuite"] description];
    self.identityProviderLogo = logo;
    self.identityMetadataUrl = [[metadata objectForKey:@"metadataUrl"] description];
    self.identitySignatureUrl = [[metadata objectForKey:@"signatureUrl"] description];
    self.identityDecryptionUrl = [[metadata objectForKey:@"decryptionUrl"] description];
	
	return YES;
}

- (BOOL)assignIdentityMetadata:(NSDictionary *)metadata {
	self.identityIdentifier = [[metadata objectForKey:@"identifier"] description];
	self.identityDisplayName = [[metadata objectForKey:@"displayName"] description];
	self.identitySecret = nil;
	
	if (self.identityProvider != nil) {
		Identity *identity = [Identity findIdentityWithIdentifier:self.identityIdentifier forIdentityProvider:self.identityProvider inManagedObjectContext:self.managedObjectContext];
                   
        if (identity != nil) {
            NSString *errorTitle = NSLocalizedString(@"error_enroll_already_enrolled_title", @"Account already activated");
            NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"error_enroll_already_enrolled", @"Account already activated message"), self.identityDisplayName, self.identityProviderDisplayName];
            NSDictionary *details = [NSDictionary dictionaryWithObjectsAndKeys:errorTitle, NSLocalizedDescriptionKey, errorMessage, NSLocalizedFailureReasonErrorKey, nil];
            self.error = [NSError errorWithDomain:TIQRECErrorDomain code:TIQRECAccountAlreadyExistsError userInfo:details];        
			return NO;			
		}
	}
								 
	return YES;
}

- (void)parseRawChallengeWithSuccessBlock:(void(^)(void))successBlock failureBlock:(void(^)(void))failureBlock{
    self.scheme = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TIQREnrollmentURLScheme"];
    NSURL *fullURL = [NSURL URLWithString:self.rawChallenge];
    if (fullURL == nil || ![fullURL.scheme isEqualToString:self.scheme]) {
        NSString *errorTitle = NSLocalizedString(@"error_enroll_invalid_qr_code", @"Invalid QR tag title");
        NSString *errorMessage = NSLocalizedString(@"error_enroll_invalid_response", @"Invalid QR tag message");
        NSDictionary *details = [NSDictionary dictionaryWithObjectsAndKeys:errorTitle, NSLocalizedDescriptionKey, errorMessage, NSLocalizedFailureReasonErrorKey, nil];
        self.error = [NSError errorWithDomain:TIQRECErrorDomain code:TIQRECInvalidQRTagError userInfo:details];
        failureBlock();
		return;        
    }
    
	NSURL *url = [NSURL URLWithString:[self.rawChallenge substringFromIndex:13]];
    if (url == nil) {
        NSString *errorTitle = NSLocalizedString(@"error_enroll_invalid_qr_code", @"Invalid QR tag title");
        NSString *errorMessage = NSLocalizedString(@"error_enroll_invalid_response", @"Invalid QR tag message");
        NSDictionary *details = [NSDictionary dictionaryWithObjectsAndKeys:errorTitle, NSLocalizedDescriptionKey, errorMessage, NSLocalizedFailureReasonErrorKey, nil];
        self.error = [NSError errorWithDomain:TIQRECErrorDomain code:TIQRECInvalidQRTagError userInfo:details];
        failureBlock();
		return;        
    }
    
	if (![url.scheme isEqualToString:@"http"] && ![url.scheme isEqualToString:@"https"] && ![url.scheme isEqualToString:@"file"]) {
        NSString *errorTitle = NSLocalizedString(@"error_enroll_invalid_qr_code", @"Invalid QR tag title");
        NSString *errorMessage = NSLocalizedString(@"error_enroll_invalid_response", @"Invalid QR tag message");
        NSDictionary *details = [NSDictionary dictionaryWithObjectsAndKeys:errorTitle, NSLocalizedDescriptionKey, errorMessage, NSLocalizedFailureReasonErrorKey, nil];
        self.error = [NSError errorWithDomain:TIQRECErrorDomain code:TIQRECInvalidQRTagError userInfo:details];
        failureBlock();
		return;
	} else if ([url.scheme isEqualToString:@"file"] && !self.allowFiles) {
        NSString *errorTitle = NSLocalizedString(@"error_enroll_invalid_qr_code", @"Invalid QR tag title");
        NSString *errorMessage = NSLocalizedString(@"error_enroll_invalid_response", @"Invalid QR tag message");
        NSDictionary *details = [NSDictionary dictionaryWithObjectsAndKeys:errorTitle, NSLocalizedDescriptionKey, errorMessage, NSLocalizedFailureReasonErrorKey, nil];
        self.error = [NSError errorWithDomain:TIQRECErrorDomain code:TIQRECInvalidQRTagError userInfo:details];
        failureBlock();
		return;
	}
    
    
	NSError *error = nil;
	//NSData *data = [self downloadSynchronously:url error:&error];
    
    __block __weak EnrollmentChallenge *weakSelf = self;
    
    [self downloadAsynchronously:url success:^(NSData *data) {
        
        NSDictionary *metadata = nil;
        
        @try {
            id object = [data objectFromJSONData];
            if ([object isKindOfClass:[NSDictionary class]]) {
                metadata = object;
            }
        } @catch (NSException *exception) {
            metadata = nil;
        }
        
        if (metadata == nil || error != nil || ![self isValidMetadata:metadata]) {
            NSString *errorTitle = NSLocalizedString(@"error_enroll_invalid_response_title", @"Invalid response title");
            NSString *errorMessage = NSLocalizedString(@"error_enroll_invalid_response", @"Invalid response message");
            NSDictionary *details = [NSDictionary dictionaryWithObjectsAndKeys:errorTitle, NSLocalizedDescriptionKey, errorMessage, NSLocalizedFailureReasonErrorKey, error, NSUnderlyingErrorKey, nil];
            weakSelf.error = [NSError errorWithDomain:TIQRECErrorDomain code:TIQRECInvalidResponseError userInfo:details];
            failureBlock();
            return ;
        }
        
        
        NSMutableDictionary *identityProviderMetadata = [NSMutableDictionary dictionaryWithDictionary:[metadata objectForKey:@"service"]];
        if (![weakSelf assignIdentityProviderMetadata:identityProviderMetadata]) {
            failureBlock();
            return;
        }
        
        NSDictionary *identityMetadata = [metadata objectForKey:@"identity"];
        if (![weakSelf assignIdentityMetadata:identityMetadata]) {
            failureBlock();
            return;
        }
        
        NSString *regex = @"^http(s)?://.*";
        NSPredicate *protocolPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
        
        if (url.query != nil && [url.query length] > 0 && [protocolPredicate evaluateWithObject:url.query] == YES) {
            weakSelf.returnUrl = [weakSelf decodeURL:url.query];
        } else {
            weakSelf.returnUrl = nil;
        }
        
        weakSelf.returnUrl = nil; // TODO: support return URL url.query == nil || [url.query length] == 0 ? nil : url.query;
        weakSelf.enrollmentUrl = [[identityProviderMetadata objectForKey:@"enrollmentUrl"] description];
        
        
        weakSelf.secretSize = [[[metadata objectForKey:@"service"] objectForKey:@"secretSize"] unsignedIntegerValue];
        weakSelf.pubkeySize = [[[metadata objectForKey:@"service"] objectForKey:@"pubkeySize"] unsignedIntegerValue];
        
        successBlock();

        
    } failure:^(NSError *error) {
        NSString *errorTitle = NSLocalizedString(@"no_connection", @"No connection title");
        NSString *errorMessage = NSLocalizedString(@"internet_connection_required", @"You need an Internet connection to activate your account. Please try again later.");
        NSDictionary *details = [NSDictionary dictionaryWithObjectsAndKeys:errorTitle, NSLocalizedDescriptionKey, errorMessage, NSLocalizedFailureReasonErrorKey, error, NSUnderlyingErrorKey, nil];
        weakSelf.error = [NSError errorWithDomain:TIQRECErrorDomain code:TIQRECConnectionError userInfo:details];
        failureBlock();
    }];
    
    /*
	if (error != nil) {
        NSString *errorTitle = NSLocalizedString(@"no_connection", @"No connection title");
        NSString *errorMessage = NSLocalizedString(@"internet_connection_required", @"You need an Internet connection to activate your account. Please try again later.");
        NSDictionary *details = [NSDictionary dictionaryWithObjectsAndKeys:errorTitle, NSLocalizedDescriptionKey, errorMessage, NSLocalizedFailureReasonErrorKey, error, NSUnderlyingErrorKey, nil];
        self.error = [NSError errorWithDomain:TIQRECErrorDomain code:TIQRECConnectionError userInfo:details];
        failureBlock();
		return;
	}
    

	NSDictionary *metadata = nil;
	
	@try {
        id object = [data objectFromJSONData];
        if ([object isKindOfClass:[NSDictionary class]]) {
            metadata = object;
        }
	} @catch (NSException *exception) {
        metadata = nil;
    } 

	if (metadata == nil || error != nil || ![self isValidMetadata:metadata]) {
        NSString *errorTitle = NSLocalizedString(@"error_enroll_invalid_response_title", @"Invalid response title");
        NSString *errorMessage = NSLocalizedString(@"error_enroll_invalid_response", @"Invalid response message");
        NSDictionary *details = [NSDictionary dictionaryWithObjectsAndKeys:errorTitle, NSLocalizedDescriptionKey, errorMessage, NSLocalizedFailureReasonErrorKey, error, NSUnderlyingErrorKey, nil];
        self.error = [NSError errorWithDomain:TIQRECErrorDomain code:TIQRECInvalidResponseError userInfo:details];        
		return;        
	}
	
	NSMutableDictionary *identityProviderMetadata = [NSMutableDictionary dictionaryWithDictionary:[metadata objectForKey:@"service"]];
	if (![self assignIdentityProviderMetadata:identityProviderMetadata]) {
		return;
	}

	NSDictionary *identityMetadata = [metadata objectForKey:@"identity"];	
	if (![self assignIdentityMetadata:identityMetadata]) {
		return;
	}
    
    NSString *regex = @"^http(s)?://.*";
    NSPredicate *protocolPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    
    if (url.query != nil && [url.query length] > 0 && [protocolPredicate evaluateWithObject:url.query] == YES) {
        self.returnUrl = [self decodeURL:url.query];
    } else {
        self.returnUrl = nil;
    }
	
	self.returnUrl = nil; // TODO: support return URL url.query == nil || [url.query length] == 0 ? nil : url.query;	
	self.enrollmentUrl = [[identityProviderMetadata objectForKey:@"enrollmentUrl"] description];
    
    
    self.secretSize = [[[metadata objectForKey:@"service"] objectForKey:@"secretSize"] unsignedIntegerValue];
    self.pubkeySize = [[[metadata objectForKey:@"service"] objectForKey:@"pubkeySize"] unsignedIntegerValue];
    
    successBlock();
     */
}

- (void)dealloc {
    self.identityProviderIdentifier = nil;
    self.identityProviderDisplayName = nil;
    self.identityProviderAuthenticationUrl = nil;
    self.identityProviderInfoUrl = nil;
    self.identityProviderOcraSuite = nil;
    self.identityProviderLogo = nil;
    self.identityProvider = nil;
    self.identityIdentifier = nil;
    self.identityDisplayName = nil;
    self.identitySecret = nil;
    self.identityPIN = nil;
    self.identity = nil;
    self.enrollmentUrl = nil;
    self.returnUrl = nil;
    self.identityMetadataUrl = nil;
    self.identitySignatureUrl = nil;
    self.identityDecryptionUrl = nil;
    self.secretSize = 0;
    self.pubkeySize = 0;
    
    [_certificateData release], _certificateData = nil;
    
    [super dealloc];
}

#pragma mark - NSURLConnection delegate

-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge{
    
    
    OSStatus            err;
    BOOL                allowConnection;
    CFArrayRef          policies;
    NSMutableArray *    certificates;
    SecTrustRef         newTrust;
    SecTrustResultType  newTrustResult = kSecTrustResultOtherError;
    
    allowConnection = NO;
    
    policies = NULL;
    newTrust = NULL;
    
    
    do
    {
        SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
        if (serverTrust == nil)
            break; // failed
        
        err = SecTrustCopyPolicies(serverTrust, &policies);
        
        if (err == errSecSuccess) {
            NSLog(@"Success");
        }
        
        SecTrustResultType trustResult;
        OSStatus status = SecTrustEvaluate(serverTrust, &trustResult);
        if (!(errSecSuccess == status))
            break; // fatal error in trust evaluation -> failed
        
        certificates = [NSMutableArray array];
        
        //Get the first certificate
        SecCertificateRef serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
        
        if (serverCertificate == nil)
            break; // failed
        
        [certificates addObject:(__bridge id)serverCertificate];
        
        CFDataRef serverCertificateData = SecCertificateCopyData(serverCertificate);
        if (serverCertificateData == nil)
            break; // failed
                
        SecCertificateRef evalCertArray[1] = { serverCertificate }; //1
        CFArrayRef cfCertRef = CFArrayCreate ((CFAllocatorRef) NULL,(void *)evalCertArray, 1, &kCFTypeArrayCallBacks);
        
        SecPolicyRef searchRef = SecPolicyCreateSSL(true, (CFStringRef)challenge.protectionSpace.host);
        
        err = SecTrustCreateWithCertificates(
                                             cfCertRef,
                                             searchRef,
                                             &newTrust
                                             );
        
        CFRelease(searchRef);
        
        if (err == noErr) {
            err = SecTrustEvaluate(serverTrust, &newTrustResult);
        }
        
        if(newTrustResult==kSecTrustResultRecoverableTrustFailure) {
            CFDataRef errDataRef = SecTrustCopyExceptions(serverTrust);
            
            SecTrustSetExceptions(serverTrust, errDataRef);
            SecTrustEvaluate(serverTrust, &newTrustResult);
            
            CFRelease(errDataRef);
        }
        
        if (err == noErr) {
            allowConnection = (newTrustResult == kSecTrustResultProceed) ||
            (newTrustResult == kSecTrustResultUnspecified);
        }
        
        NSURLCredential *newCredential = [NSURLCredential credentialForTrust:newTrust];
        
        CFRelease(newTrust);

        [self setCertificateData:(__bridge id)serverCertificateData];
        
        CFRelease(serverCertificateData);
        
        if (allowConnection) {
            // Authentication succeeded:
            
            return [[challenge sender] useCredential:newCredential
                          forAuthenticationChallenge:challenge];
            
            //return [[challenge sender] performDefaultHandlingForAuthenticationChallenge:challenge];
            
            //return [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
            
            /*
            return [[challenge sender] useCredential:newCredential
                          forAuthenticationChallenge:challenge];
             */
        } else {
            break;
        }
    } while (0);
    
    // Authentication failed:
    return [[challenge sender] cancelAuthenticationChallenge:challenge];
    
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
    
    NSLog(@"connectionShouldUseCredentialStorage : %@",connection);
    
    return NO;
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if(nil!=_currentFailureBlock) {
        _currentFailureBlock(error);
    }
    
    [self setCurrentUrlConnection:nil];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    NSMutableData *data = [[NSMutableData alloc] init];
    [self setCurrentData:data];
    [data release];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if(nil!=_currentSuccessBlock) {
        _currentSuccessBlock(_currentData);
    }
    
    [self setCurrentUrlConnection:nil];
}

#pragma mark - NSURLConnection data delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_currentData appendData:data];
}



@end