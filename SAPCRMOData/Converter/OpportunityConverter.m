//
//  OpportunityConverter.m
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.16..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import "OpportunityConverter.h"
#import "ConverterUtils.h"
#import "NSDate+Extension.h"

@import ObjectiveC;

@interface OpportunityConverter()

#pragma mark - Common set of CRM OData Entity specific properties
@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSString* short_description;

#pragma mark - Appointment and Opportunity related properties
@property (strong, nonatomic) NSString* comment;
@property (strong, nonatomic) NSString* status;

#pragma mark - Contact, Account, Appointment and Opportunity common properties
@property (strong, nonatomic) NSString* dueDate;

#pragma mark - Opportunity related properties
@property (strong, nonatomic) NSNumber* expectedRevenue;
@property (strong, nonatomic) NSString* startDate;

// cut here
#pragma mark - Contact and Account related properties
@property (strong, nonatomic) NSString* function;
@property (strong, nonatomic) NSString* company;
@property (strong, nonatomic) NSString* phone;

#pragma mark - Appointment related properties
@property (strong, nonatomic) NSString* responsible;
@property (strong, nonatomic) NSString* priority;

@property (strong, nonatomic) id<SODataEntity> entity;

@end

// Raw structure
/*
 CRM_BUPA_ODATA.Opportunity
 {
 expRevenue: NSDecimalNumber
 status: __NSCFString
 closingDate: __NSTaggedDate
 startDate: __NSTaggedDate
 probability: __NSCFString
 objectId: __NSCFString
 currPhaseText: __NSCFConstantString
 Guid: SODataGuid
 currency: __NSCFString
 description: __NSCFString
 statusText: __NSCFString
 }
 */
@implementation OpportunityConverter

-(instancetype) initWithEntity:(id<SODataEntity>)entity_in
{
    self = [super init];
    
    if( self )
    {
        self.entity = entity_in;
//        [self initProps];
    }
    return self;
}

-(NSString*) resourcePath
{
    return _entity.resourcePath;
}

-(NSString*) editResourcePath
{
    return _entity.editResourcePath;
}

-(NSString*) typeName
{
    return _entity.typeName;
}

-(NSString*) name
{
    NSString* result = [ConverterUtils valueForKey:@"description" fromProperties:_entity.properties];
    return result ? result : @"-";
}

-(NSString*) short_description
{
    NSString* result = [ConverterUtils valueForKey:@"statusText" fromProperties:_entity.properties];
    return result ? result : @"-";
}

-(NSNumber*) expectedRevenue
{
    NSDecimalNumber* revenue = [ConverterUtils valueForKey:@"expRevenue" fromProperties:_entity.properties];
    return revenue ? revenue : @(0);
}

-(NSString*) startDate
{
    // XXX fake it for now
    NSDate* date = [NSDate date];
    return [NSDate localizeDate:date];
}

-(NSString*) status
{
    NSString* result = [ConverterUtils valueForKey:@"status" fromProperties:_entity.properties];
    result = [self mapStatusToString:result];
    return result ? result : @"-";
}

/**
 *  Maps CRM status codes to user-friendly strings
 *
 *  @param status_in status string code (e.g. E0001)
 *
 *  @return user friendly string (e.g. Open)
 */
-(NSString*) mapStatusToString:(NSString*)status_in
{
    if( !status_in || status_in.length == 0)
    {
        return nil;
    }

    NSDictionary* statusCodeStrings = @{ @"E0001" : @"Open",
                                         @"E0002" : @"In Process",
                                         @"E0003" : @"Completed" };
    return statusCodeStrings[status_in];
}

-(NSString*) dueDate
{
    // XXX fake it for now
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:30*24*60*60];
    return [NSDate localizeDate:date];
}

-(NSString*) comment
{
    NSString* result = [ConverterUtils valueForKey:@"statusText" fromProperties:_entity.properties];
    return result ? result : @"-";
}

/**
 *  Inits all props to defaults
 */
-(void) initProps
{
    @autoreleasepool
    {
        uint propertyCount = 0;
        objc_property_t* propertyArray = class_copyPropertyList([self class], &propertyCount);
        for (NSUInteger i = 0; i < propertyCount; ++i)
        {
            objc_property_t property = propertyArray[i];
            NSString* propertyName = [[NSString alloc] initWithUTF8String:property_getName(property)];
            // handle types different from NSString
            {
                if( [propertyName isEqualToString:@"expectedRevenue"] )
                {
                    _expectedRevenue = @(0);
                    continue;
                }
            }
            [self setValue:@"" forKey:propertyName];
        }
        free(propertyArray);
    }
}

@end
