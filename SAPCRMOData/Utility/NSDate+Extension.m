//
//  NSObject+NSDate.m
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.16..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import "NSDate+Extension.h"

@implementation NSDate (NSDate_Extension)

+(NSString*) localizeDate:(NSDate*)date_in
{
    NSString* dateAsString = nil;
    
    static NSDateFormatter* dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        //        [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"GMT"]];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
        [dateFormatter setTimeZone:[NSTimeZone defaultTimeZone]];
        
    });
    
    dateAsString = [dateFormatter stringFromDate:date_in];
    return dateAsString;
}

+(NSDate*) dateFromString:(NSString*)dateString_in
{
    // convert date from string with format
    // yyyy-MM-ddTHH:mm:ss.SSS Z
    // 2014-10-11T12:16:37.000-07:00
    static NSDateFormatter* dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        //        [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"GMT"]];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
        [dateFormatter setTimeZone:[NSTimeZone defaultTimeZone]];
        
    });

    NSDate* detectedDate = [dateFormatter dateFromString:dateString_in];
    
    return detectedDate;
}

@end
