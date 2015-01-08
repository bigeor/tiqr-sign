//
//  PPQuietTime.h
//  PushPixl
//
//  Created by Yvan Moté on 29/04/13.
//  Copyright (c) 2013 Neopixl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPQuietTime : NSObject

/**
 * Returns the start time value.
 *
 * @return The start time value (e.g. 22:00:00UTC+02:00).
 */

@property (nonatomic, readonly) NSString *startTimeValue;

/**
 * Returns the end time.
 *
 * @return The end time (e.g. 08:00:00UTC+02:00).
 */

@property (nonatomic, readonly) NSString *endTimeValue;

/**
 * Return a new quietTime with startTime and endTime filled with the current TimeZone of the device
 *
 * @param startHour The start hour when the user should not be disturbed (e.g. 22 as 22h or 10pm). The start hour should be equal or more than 0 and less than 24.
 * @param startMinute The start minute when the user should not be disturbed (e.g. 0 for 0 minute). The start minute value should be equal or more than 0 and less than 60.
 * @param endHour The end hour when the user should not be disturbed (e.g. 6 as 6h or 6am). The end hour value should be equal or more than 0 and less than 24.
 * @param endMinute The end minute when the user should not be disturbed (e.g. 0 for 0 minute). The end minute value should be equal or more than 0 and less than 60.
 * @return a new quietTime with startTime and endTime filled with the current TimeZone of the device.
 * @exception  NSInternalInconsistencyException If values (startHour, startMinute, endHour or endMinute) are incorrects, an exception will be raised.
 */

+ (PPQuietTime *)quietTimeWithStartHour:(NSInteger)startHour
                            startMinute:(NSInteger)startMinute
                                endHour:(NSInteger)endHour
                              endMinute:(NSInteger)endMinute;

@end
