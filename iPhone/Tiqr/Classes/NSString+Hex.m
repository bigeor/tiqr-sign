//
//  NSString+Hex.m
//  Tiqr
//
//  Created by Fabrice Dewasmes on 7/17/14.
//  Copyright (c) 2014 Egeniq. All rights reserved.
//

#import "NSString+Hex.h"

@implementation NSString (Hex)
- (NSData *)dataFromHexString {
    const char *chars = [self UTF8String];
    int i = 0, len = self.length;
    
    NSMutableData *data = [NSMutableData dataWithCapacity:len / 2];
    char byteChars[3] = {'\0','\0','\0'};
    unsigned long wholeByte;
    
    while (i < len) {
        byteChars[0] = chars[i++];
        byteChars[1] = chars[i++];
        wholeByte = strtoul(byteChars, NULL, 16);
        [data appendBytes:&wholeByte length:1];
    }
    
    return data;
}
@end
