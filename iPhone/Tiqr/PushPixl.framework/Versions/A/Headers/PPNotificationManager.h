//
//  PPNotificationManager.h
//  PushPixl
//
//  Created by Yvan Moté on 29/04/13.
//  Copyright (c) 2013 Neopixl. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PPNotification;
@class PPQuietTime;

extern NSString *const PPNotificationManagerErrorKeyUserInfo;

extern NSString * const PPNotificationManagerDidSubscribe;
extern NSString * const PPNotificationManagerDidFailSubscription;
extern NSString * const PPNotificationManagerDidFailConsume;
extern NSString * const PPNotificationManagerDidUnsubscribe;
extern NSString * const PPNotificationManagerDidFailUnsubscription;
extern NSString * const PPNotificationManagerDidFailSendNotification;

@interface PPNotificationManager : NSObject

/**
 * Returns the deviceToken used previously in  method registerDeviceToken:forTags:whithBusinessId:withQuietTime:
 *
 * @return The device token.
 */
-(NSString*)deviceToken;


/**
 * Returns the shared PPNotificationManager instance. 
 *
 * @return The shared PPNotificationManager instance.
 */
+ (id)sharedPPNotificationManager;


/**
 * Perform teardown on the shared instance. This method should be called in -applicationWillTerminate: delegate method.
 */
+ (void)finish;


//Subscription methods (API methods)

/**
 * Perform a registration on PushPixl server. Everytime the user changes its tags or you receive a deviceToken when the application successfully registers with Apple Push Service (APS), you should call this method. You can call this method to change the alias asociated to a deviceToken (One deviceToken can only be associated one alias).
 * @param aDeviceToken The device token received when push notification registration has been successfull. If nil the method does nothing.
 * @param tags A list of tags. Can be empty or nil.
 * @param alias The alias used by the business part (e.g. "John's phone", "john.doe@mail.com"). Should not be nil or empty.
 * @param quietTime The quiet time used to specify when the user does not want to be notified. Can be nil.
 * @see PPQuietTime
 * @exception  NSInternalInconsistencyException If alias is empty or nil, an exception will be raised.
 */
- (void)registerDeviceToken:(NSData *)aDeviceToken
                    forTags:(NSArray *)tags
                  withAlias:(NSString *)alias
              withQuietTime:(PPQuietTime *)quietTime;

/**
 * Perform the unregistration process on PushPixl server for the device token given in parameter.
 * @param aDeviceToken The device token received when push notification registration has been successfull. If nil the method does nothing.
 */

- (void)unregisterDeviceToken:(NSData *)aDeviceToken;

/**
 * Confirm to the PushPixl server that a notification has been read. Before calling this method, make sure you have been registered by calling registerDeviceToken:forTags:withBusinessId:withQuietTime: method.
 * @param notificationDictionary The dictionary notification received in method -application:didReceiveRemoteNotification: or -application:didFinishLaunchingWithOptions: in UIApplicationDelegate.
 */

- (void)confirmReading:(NSDictionary *)notificationDictionary;


/**
 * Send an notification to myself.
 *
 *@param message The message that will be sent in the notification payload.
 */

- (void)notifyDeviceWithMessage:(NSString*)message;

@end
