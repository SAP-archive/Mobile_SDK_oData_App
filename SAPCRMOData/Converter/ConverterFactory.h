//
//  ConverterFactory.h
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.16..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreDataConverting.h"

@interface ConverterFactory : NSObject

/**
 *  Builds a converter of specified type
 *  @param type <#type description#>
 *
 *  @return <#return value description#>
 */
+(id<CoreDataConverting>) makeConverter:(E_OBJECT_TYPE)type withEntity:(id<SODataEntity>)entity;

@end
