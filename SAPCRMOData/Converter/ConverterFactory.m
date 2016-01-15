//
//  ConverterFactory.m
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.16..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import "ConverterFactory.h"
#import "CoreDataConverting.h"
#import "AccountConverter.h"
#import "AppointmentConverter.h"
#import "ContactConverter.h"
#import "OpportunityConverter.h"

@implementation ConverterFactory

//static NSMutableDictionary* sConvertersByType;
//
//+(void) initialize
//{
//    sConvertersByType = [NSMutableDictionary dictionary];
//}

+(id<CoreDataConverting>) makeConverter:(E_OBJECT_TYPE)type withEntity:(id<SODataEntity>)entity
{
//    id<CoreDataConverting> result = sConvertersByType[@(type)];
    id<CoreDataConverting> result = nil;
    //    if( !result )
    //    {
    switch( type )
    {
        case CONTACTS:
        {
            result = [[ContactConverter alloc] initWithEntity:entity];
        } break;
        case ACCOUNTS:
        {
            result = [[AccountConverter alloc] initWithEntity:entity];
        } break;
        case APPOINTMENTS:
        {
            result = [[AppointmentConverter alloc] initWithEntity:entity];
        } break;
        case OPPORTUNITIES:
        {
            result = [[OpportunityConverter alloc] initWithEntity:entity];
        } break;
        default:
        {
            // enhance with new types as required
        } break;
    }
    
    return result;
}

@end
