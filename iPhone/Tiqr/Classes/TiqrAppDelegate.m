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

#import "TiqrAppDelegate.h"
#import "AuthenticationChallenge.h"
#import "EnrollmentChallenge.h"
#import "SignChallenge.h"
#import "DecryptChallenge.h"
#import "IdentitySelectorViewController.h"
#import "AuthenticationConfirmViewController.h"
#import "EnrollmentConfirmViewController.h"
#import "SignConfirmViewController.h"
#import "ScanViewController.h"
#import "Identity+Utils.h"
#import "NotificationRegistration.h"
#import "Reachability.h"
#import "ScanViewController.h"
#import "StartViewController.h"
#import "ErrorViewController.h"
#import "UIColor+TiQR.h"
#import <PushPixl/PushPixl.h>
#import <HockeySDK/HockeySDK.h>
#import "NSData+Hex.h"
#import "MBProgressHUD.h"

#import <PushPixl/PPPushPixlAppDelegate.h>

@interface TiqrAppDelegate () <PPPushPixlAppDelegate, IdentitySelectorDelegate>

@property (nonatomic, retain, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readwrite) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readwrite) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, retain) Challenge *challenge;

- (BOOL)handleAuthenticationChallenge:(NSString *)rawChallenge;
- (BOOL)handleEnrollmentChallenge:(NSString *)rawChallenge;
- (NSURL *)applicationDocumentsDirectory;
- (void)saveContext;

@end

@implementation TiqrAppDelegate

@synthesize window=window_;
@synthesize managedObjectContext=managedObjectContext_;
@synthesize managedObjectModel=managedObjectModel_;
@synthesize persistentStoreCoordinator=persistentStoreCoordinator_;
@synthesize navigationController=navigationController_;
@synthesize startViewController=startViewController_;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"3de002f642e4a733a31f47cf8e6c4736"];
    [[BITHockeyManager sharedHockeyManager] startManager];
    
    //Disabled
    /*
    [[BITHockeyManager sharedHockeyManager].authenticator
     authenticateInstallation];
     */

    self.startViewController.managedObjectContext = self.managedObjectContext;
    
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];	
	BOOL showInstructions = 
        [defaults objectForKey:@"show_instructions_preference"] == nil || 
        [defaults boolForKey:@"show_instructions_preference"];		
    
    BOOL allIdentitiesBlocked = [Identity allIdentitiesBlockedInManagedObjectContext:self.managedObjectContext];  
    
	if (!allIdentitiesBlocked && !showInstructions) {
		ScanViewController *scanViewController = [[ScanViewController alloc] init];   
        scanViewController.managedObjectContext = self.managedObjectContext;
        [self.navigationController pushViewController:scanViewController animated:NO];
        [scanViewController release];
    }

    [self.window setRootViewController:self.navigationController];
    [self.window makeKeyAndVisible];
    
    if ([self.navigationController.navigationBar respondsToSelector:@selector(barTintColor)]) {
        self.navigationController.navigationBar.barTintColor = [UIColor defaultTintColor];
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    }

	NSDictionary *info = [launchOptions valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
	if (info != nil) {
        [[PPNotificationManager sharedPPNotificationManager] confirmReading:info];
		return [self handleRawChallenge:[info valueForKey:@"challenge"]];
	}
    
    #if !TARGET_IPHONE_SIMULATOR
    /*
	NSString *url = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"SANotificationRegistrationURL"];
	if (url != nil && [url length] > 0) {
		[application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeSound];
	}
     */
    #endif
    
    [[application keyWindow] setTintColor:[UIColor whiteColor]];
    
    if([application respondsToSelector:@selector(registerForRemoteNotifications)]) {
        //Register iOS 8.x and later
        [application registerForRemoteNotifications];
    }
    else {
        //Register iOS 7 and earlier
        [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeBadge];
    }
	
    return YES;
}

- (void)popToStartViewControllerAnimated:(BOOL)animated {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];	
    BOOL showInstructions = [defaults objectForKey:@"show_instructions_preference"] == nil || [defaults boolForKey:@"show_instructions_preference"];
    BOOL allIdentitiesBlocked = [Identity allIdentitiesBlockedInManagedObjectContext:self.managedObjectContext];  
    
    if (allIdentitiesBlocked || showInstructions) {
        [self.navigationController popToRootViewControllerAnimated:animated];
    } else {
        UIViewController *scanViewController = [self.navigationController.viewControllers objectAtIndex:1];
        [self.navigationController popToViewController:scanViewController animated:animated];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	[self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self saveContext];
}

#pragma mark - Push Notification handler methods

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    
    NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken : %@",deviceToken);
    
    NSString *deviceName = [[UIDevice currentDevice] name];
    
    [[PPNotificationManager sharedPPNotificationManager] registerDeviceToken:deviceToken forTags:nil withAlias:deviceName withQuietTime:[PPQuietTime quietTimeWithStartHour:23 startMinute:00 endHour:23 endMinute:30]];
    [[NotificationRegistration sharedInstance] setNotificationToken:[deviceToken hexStringValue]];
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
    [[PPNotificationManager sharedPPNotificationManager] confirmReading:userInfo];
    
    [self handleRawChallenge:[userInfo valueForKey:@"challenge"]];
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    NSLog(@"didFailToRegisterForRemoteNotificationsWithError !!!! %@", [error localizedDescription]);
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    NSLog(@"didRegisterUserNotificationSettings : %@",notificationSettings);
}

#pragma mark -
#pragma mark Authentication / enrollment challenge

- (BOOL)handleRawChallenge:(NSString *)rawChallenge {
    
    NSString *authenticationScheme = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TIQRAuthenticationURLScheme"];
    NSString *enrollmentScheme = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TIQREnrollmentURLScheme"];
    NSString *signScheme = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TIQRSignURLScheme"];
    NSString *decryptionScheme = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TIQRDecryptURLScheme"];
    
    NSURL *url = [NSURL URLWithString:rawChallenge];
    if (url != nil && [url.scheme isEqualToString:authenticationScheme]) {
        return [self handleAuthenticationChallenge:rawChallenge];
    } else if (url != nil && [url.scheme isEqualToString:enrollmentScheme]) {
        return [self handleEnrollmentChallenge:rawChallenge];
    } else if (url != nil && [url.scheme isEqualToString:signScheme]) {
        return [self handleSignChallenge:rawChallenge];
    } else if (url != nil && [url.scheme isEqualToString:decryptionScheme]) {
        return [self handleDecryptChallenge:rawChallenge];
    } else {
        //Invalid
    }
    
    return NO;
}

- (BOOL)handleAuthenticationChallenge:(NSString *)rawChallenge {
    UIViewController *firstViewController = [self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers count] > 1 ? 1 : 0];
    [self.navigationController popToViewController:firstViewController animated:NO];
	
    __block __weak TiqrAppDelegate *weakSelf = self;

	__block AuthenticationChallenge *challenge = [[AuthenticationChallenge alloc] initWithRawChallenge:rawChallenge managedObjectContext:self.managedObjectContext];
    
    [self setChallenge:challenge];
    
    [challenge parseRawChallengeWithSuccessBlock:^{
        
        
        NSString *errorTitle = challenge.isValid ? nil : [challenge.error localizedDescription];
        NSString *errorMessage = challenge.isValid ? nil : [challenge.error localizedFailureReason];

        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
            
            if (challenge != nil && errorTitle == nil) {

                UIViewController *viewController = nil;
                if (challenge.identity != nil) {
                   AuthenticationConfirmViewController *authenticationConfirmViewController = [[AuthenticationConfirmViewController alloc] initWithAuthenticationChallenge:challenge];
                    [authenticationConfirmViewController setManagedObjectContext:[self managedObjectContext]];
                    viewController = authenticationConfirmViewController;
                } else {
                    IdentitySelectorViewController *identitySelectorViewController = [[IdentitySelectorViewController alloc] initWithChallenge:challenge];
                    [identitySelectorViewController setDelegate:self];
                    [identitySelectorViewController setManagedObjectContext:[self managedObjectContext]];
                    viewController = identitySelectorViewController;
                }
                
                [weakSelf.navigationController pushViewController:viewController animated:NO];
                
                [viewController release];
            
            } else {
                ErrorViewController *viewController = [[ErrorViewController alloc] initWithTitle:@"" errorTitle:errorTitle errorMessage:errorMessage];
                [weakSelf.navigationController pushViewController:viewController animated:YES];
                [viewController release];
            }
            
            
            [challenge release];
        });

        
    } failureBlock:^{
        
        NSError *error = challenge.error;
        NSString *title = NSLocalizedString(@"login_title", @"Login navigation title");
        ErrorViewController *viewController = [[ErrorViewController alloc] initWithTitle:title errorTitle:[error localizedDescription] errorMessage:[error localizedFailureReason]];
        [weakSelf.navigationController pushViewController:viewController animated:NO];
        [viewController release];
        
        [challenge release];

    }];
    
    return YES;
}

- (BOOL)handleEnrollmentChallenge:(NSString *)rawChallenge {
    UIViewController *firstViewController = [self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers count] > 1 ? 1 : 0];
    [self.navigationController popToViewController:firstViewController animated:NO];
    
    __block __weak TiqrAppDelegate *weakSelf = self;
    
	__block EnrollmentChallenge *challenge = [[EnrollmentChallenge alloc] initWithRawChallenge:rawChallenge
                                                                  managedObjectContext:self.managedObjectContext];
    
    [self setChallenge:challenge];
    
    [challenge parseRawChallengeWithSuccessBlock:^{
        
        if (!challenge.isValid) {
            NSError *error = challenge.error;
            NSString *title = NSLocalizedString(@"enrollment_confirmation_header_title", @"Account activation title");
            ErrorViewController *viewController = [[ErrorViewController alloc] initWithTitle:title errorTitle:[error localizedDescription] errorMessage:[error localizedFailureReason]];
            [weakSelf.navigationController pushViewController:viewController animated:NO];
            [viewController release];
            return;
        }
        
        UIViewController *viewController = [[EnrollmentConfirmViewController alloc] initWithEnrollmentChallenge:challenge];
        [weakSelf.navigationController pushViewController:viewController animated:NO];

        [viewController release];
        
        [challenge release];
        
    } failureBlock:^{
        
        NSError *error = challenge.error;
        NSString *title = NSLocalizedString(@"enrollment_confirmation_header_title", @"Account activation title");
        ErrorViewController *viewController = [[ErrorViewController alloc] initWithTitle:title errorTitle:[error localizedDescription] errorMessage:[error localizedFailureReason]];
        [weakSelf.navigationController pushViewController:viewController animated:NO];
        [viewController release];
        
        [challenge release];
    }];
    
    return YES;
}

- (BOOL)handleSignChallenge:(NSString *)rawChallenge {
    SignChallenge *challenge = [[SignChallenge alloc] initWithRawChallenge:rawChallenge managedObjectContext:self.managedObjectContext];
    return [self handleSignOrDecryptFromChallenge:challenge];
}


- (BOOL)handleDecryptChallenge:(NSString *)rawChallenge {
    DecryptChallenge *challenge = [[DecryptChallenge alloc] initWithRawChallenge:rawChallenge managedObjectContext:self.managedObjectContext];
    return [self handleSignOrDecryptFromChallenge:challenge];
}

- (BOOL)handleSignOrDecryptFromChallenge:(Challenge *)challenge {
    __block __weak TiqrAppDelegate *weakSelf = self;
    
    [self setChallenge:challenge];
    
    [challenge parseRawChallengeWithSuccessBlock:^{
        
        NSString *errorTitle = challenge.isValid ? nil : [challenge.error localizedDescription];
        NSString *errorMessage = challenge.isValid ? nil : [challenge.error localizedFailureReason];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
            
            if (challenge != nil && errorTitle == nil) {
                
                UIViewController *viewController = nil;
                
                SignChallenge *signChallenge = (SignChallenge *)challenge;
                if (signChallenge.identity == nil) {
                    IdentitySelectorViewController *identityViewController = [[IdentitySelectorViewController alloc] initWithChallenge:signChallenge];
                    [identityViewController setDelegate:self];
                    identityViewController.managedObjectContext = self.managedObjectContext;
                    viewController = identityViewController;
                } else {
                    SignConfirmViewController *confirmViewController = [[SignConfirmViewController alloc] initWithAuthenticationChallenge:signChallenge];
                    confirmViewController.managedObjectContext = self.managedObjectContext;
                    viewController = confirmViewController;
                }
                
                [weakSelf.navigationController pushViewController:viewController
                                                     animated:YES];
                
                [viewController release];
                
            } else {
                ErrorViewController *viewController = [[ErrorViewController alloc] initWithTitle:@"" errorTitle:errorTitle errorMessage:errorMessage];
                [weakSelf.navigationController pushViewController:viewController animated:YES];
                [viewController release];
            }
            
            
            [challenge release];
        });
        
        
        
    } failureBlock:^{
        
        NSError *error = challenge.error;
        NSString *title = NSLocalizedString(@"login_title", @"Login navigation title");
        ErrorViewController *viewController = [[ErrorViewController alloc] initWithTitle:title errorTitle:[error localizedDescription] errorMessage:[error localizedFailureReason]];
        [weakSelf.navigationController pushViewController:viewController animated:NO];
        [viewController release];
        
        [challenge release];
        
    }];

    return YES;
}


#pragma mark -
#pragma mark Handle open URL

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    NSString *authenticationScheme = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TIQRAuthenticationURLScheme"]; 
    NSString *enrollmentScheme = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TIQREnrollmentURLScheme"]; 
    
	if ([url.scheme isEqualToString:authenticationScheme]) {
		return [self handleAuthenticationChallenge:[url description]];
	} else if ([url.scheme isEqualToString:enrollmentScheme]) {
		return [self handleEnrollmentChallenge:[url description]];
	} else {
		return NO;
	}
}

#pragma mark -
#pragma mark Remote notifications
/*
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	[[NotificationRegistration sharedInstance] sendRequestWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	NSLog(@"Remote notification registration error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)info {
	[self handleAuthenticationChallenge:[info valueForKey:@"challenge"]];
} */

#pragma mark -
#pragma mark Core Data stack

- (void)saveContext {
    NSError *error = nil;
	NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}  

- (NSManagedObjectContext *)managedObjectContext {
    if (managedObjectContext_ != nil) {
        return managedObjectContext_;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext_ = [[NSManagedObjectContext alloc] init];
        [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext_;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel_ != nil) {
        return managedObjectModel_;
    }
	
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"Tiqr" ofType:@"momd"];
	if (modelPath == nil) {
		modelPath = [[NSBundle mainBundle] pathForResource:@"Tiqr" ofType:@"mom"];
	}
	
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    managedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return managedObjectModel_;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (persistentStoreCoordinator_ != nil) {
        return persistentStoreCoordinator_;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Tiqr.sqlite"];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];    
    
    NSError *error = nil;
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return persistentStoreCoordinator_;
}

#pragma mark - 
#pragma mark Connection handling
- (BOOL)hasConnection {   
    return (![Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable);
}


#pragma mark -
#pragma mark Application's Documents directory

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
}

- (void)dealloc {
    self.navigationController = nil;
    self.managedObjectContext = nil;
    self.managedObjectModel = nil;
    self.persistentStoreCoordinator = nil;
    self.window = nil;

    [super dealloc];
}

#pragma mark - IdentitySelectorViewController delegate methods

- (void)identitySelectorViewController:(IdentitySelectorViewController *)viewController didFinishWithIdentity:(Identity *)identity forChallenge:(MultiIdentitiesChallenge *)challenge {
    
    [[self navigationController] popToRootViewControllerAnimated:NO];
    [self pushViewControllerForChallenge:challenge];
}

- (void)pushViewControllerForChallenge:(Challenge *)challenge {
    if ([challenge isKindOfClass:[AuthenticationChallenge class]]) {
        AuthenticationChallenge *authenticationChallenge = (AuthenticationChallenge *)challenge;
        if (authenticationChallenge.identity == nil) {
            IdentitySelectorViewController *identityViewController = [[IdentitySelectorViewController alloc] initWithChallenge:authenticationChallenge];
            identityViewController.managedObjectContext = self.managedObjectContext;
            identityViewController.delegate = self;
            [[self navigationController] presentViewController:identityViewController
                                                      animated:YES
                                                    completion:nil];
            
            
            //[self presentModalViewController:identityViewController animated:YES];
            [identityViewController release];
            
        } else {
            AuthenticationConfirmViewController *confirmViewController = [[AuthenticationConfirmViewController alloc] initWithAuthenticationChallenge:authenticationChallenge];
            confirmViewController.managedObjectContext = self.managedObjectContext;
            [self.navigationController pushViewController:confirmViewController animated:YES];
            [confirmViewController release];
        }
    } else if ([challenge isKindOfClass:[EnrollmentChallenge class]]){
        EnrollmentChallenge *enrollmentChallenge = (EnrollmentChallenge *)challenge;
        EnrollmentConfirmViewController *confirmViewController = [[EnrollmentConfirmViewController alloc] initWithEnrollmentChallenge:enrollmentChallenge];
        confirmViewController.managedObjectContext = self.managedObjectContext;
        [self.navigationController pushViewController:confirmViewController animated:YES];
        [confirmViewController release];
    } else {
        SignChallenge *signChallenge = (SignChallenge *)challenge;
        if (signChallenge.identity == nil) {
            IdentitySelectorViewController *identityViewController = [[IdentitySelectorViewController alloc] initWithChallenge:signChallenge];
            identityViewController.managedObjectContext = self.managedObjectContext;
            identityViewController.delegate = self;
            
            [[self navigationController] presentViewController:identityViewController
                                                      animated:YES
                                                    completion:nil];
            
            
            //[self presentModalViewController:identityViewController animated:YES];
            [identityViewController release];
        } else {
            SignConfirmViewController *confirmViewController = [[SignConfirmViewController alloc] initWithAuthenticationChallenge:signChallenge];
            confirmViewController.managedObjectContext = self.managedObjectContext;
            [self.navigationController pushViewController:confirmViewController animated:YES];
            [confirmViewController release];
        }
    }
}

#pragma mark - PushPixl App delegate methods

- (BOOL)isAppInReleaseMode {
    
    BOOL isAppInReleaseMode = YES;
    
#ifdef DEBUG
    isAppInReleaseMode = NO;
#endif
    
    return isAppInReleaseMode;
}

@end

@implementation NSURLRequest(DataController)

/*
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host
{
    return NO;
    //return YES;
}
*/
 
@end
