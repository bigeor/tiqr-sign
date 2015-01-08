//
//  DataToSignViewController.h
//  Tiqr
//
//  Created by Fabrice Dewasmes on 7/17/14.
//  Copyright (c) 2014 Egeniq. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CryptoChallenge.h"
#import "CryptoConfirmationRequest.h"


@interface DataToSignViewController : UIViewController <TiQRRequestDelegate>

/**
 * Managed object context.
 */
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

/**
 * Initializes the controller with the given sign challenge.
 *
 * @param challenge sign challenge
 *
 * @return initialized controller instance
 */
- (id)initWithSignChallenge:(CryptoChallenge *)challenge;

@end
