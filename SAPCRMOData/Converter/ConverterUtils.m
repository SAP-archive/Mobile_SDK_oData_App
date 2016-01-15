//
//  ConverterUtils.m
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.16..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import "ConverterUtils.h"
#import "SODataPropertyDefault.h"
#import "SAPStoreManager.h"

@implementation ConverterUtils

+ (id) valueForKey:(NSString*)key fromProperties:(NSDictionary*)properties
{
//    NSString* result = nil;
    SODataPropertyDefault* property = properties[key];
    
//    result = [SAPOnlineStoreFacade sharedInstance].demoMode ? property.name : (NSString*)property.value;
    return property.value;
}

@end
