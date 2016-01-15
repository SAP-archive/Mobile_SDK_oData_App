//
//  NSObject+NSDate.h
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.16..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (NSDate_Extension)

/**
 * Builds a localized string "yyyy-MM-dd HH:mm:ss" from a date
 */
+(NSString*) localizeDate:(NSDate*)date_in;

/**
 *  Converts a date string with format yyyy-MM-dd HH:mm:ss to NSDate
 *
 *  @param dateString_in <#dateString_in description#>
 *
 *  @return <#return value description#>
 */
+(NSDate*) dateFromString:(NSString*)dateString_in;
@end