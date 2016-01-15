//
//  ConverterUtils.h
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.16..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ConverterUtils : NSObject

/**
 *  Extracts the value for given key from the property dictionary
 *
 *  @param key        <#key description#>
 *  @param properties <#properties description#>
 *
 *  @return key value or nil
 */
+ (id) valueForKey:(NSString*)key fromProperties:(NSDictionary*)properties;

@end
