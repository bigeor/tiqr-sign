//
//  SignConfirmViewController.h
//  Tiqr
//
//  Created by Fabrice Dewasmes on 7/16/14.
//  Copyright (c) 2014 Egeniq. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SignChallenge.h"
#import "DecryptChallenge.h"
#import "CryptoDataRequest.h"

@interface SignConfirmViewController : UIViewController <TiQRRequestDelegate>

/**
 * Managed object context.
 */
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

/**
 * Initializes the controller for the given authentication challenge.
 *
 * @param challenge authentication challenge
 *
 * @return initialized controller instance
 */
- (id)initWithAuthenticationChallenge:(SignChallenge *)challenge;

@end
