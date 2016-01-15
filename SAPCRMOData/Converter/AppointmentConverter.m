//
//  AppointmentConverter.m
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.16..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import "AppointmentConverter.h"
#import "ConverterUtils.h"
#import "NSDate+Extension.h"

@import ObjectiveC;

@interface AppointmentConverter()

#pragma mark - Common set of CRM OData Entity specific properties
@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSString* short_description;

#pragma mark - Appointment related properties
@property (strong, nonatomic) NSString* responsible;
@property (strong, nonatomic) NSString* priority;

#pragma mark - Appointment and Opportunity related properties
@property (strong, nonatomic) NSString* comment;
@property (strong, nonatomic) NSString* status;

#pragma mark - Contact, Account, Appointment and Opportunity common properties
@property (strong, nonatomic) NSString* dueDate;

// cut here
#pragma mark - Contact and Account related properties
@property (strong, nonatomic) NSString* function;
@property (strong, nonatomic) NSString* company;
@property (strong, nonatomic) NSString* phone;

#pragma mark - Opportunity related properties
@property (strong, nonatomic) NSNumber* expectedRevenue;
@property (strong, nonatomic) NSString* startDate;

@property (strong, nonatomic) id<SODataEntity> entity;

@end

// Raw structure
/*
 CRM_BUPA_ODATA.Appointment {
 Status: __NSCFString
 ToDate: __NSTaggedDate
 HasAttachment: __NSCFBoolean
 AccountTxt: __NSCFString
 Responsible: __NSCFConstantString
 ContactTxt: __NSCFString
 PrivatFlag: __NSCFBoolean
 MyOwn: __NSCFBoolean
 Location: __NSCFString
 Account: __NSCFString
 ContactAccount: __NSCFString
 ResponsArea: __NSCFConstantString
 ToOffset: __NSCFNumber
 Note: __NSCFString
 Description: __NSCFString
 ChangedAt: __NSTaggedDate
 PriorityTxt: __NSCFConstantString
 ResponsibleTxt: __NSCFString
 StatusTxt: __NSCFString
 AllDay: __NSCFBoolean
 Contact: __NSCFString
 Priority: __NSCFString
 FromOffset: __NSCFNumber
 Guid: SODataGuid
 FromDate: __NSTaggedDate
 }
 */
@implementation AppointmentConverter

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
    NSString* result = [ConverterUtils valueForKey:@"Description" fromProperties:_entity.properties];
    if( !result )
    {
        result = @"-";
    }
    return result;
}

-(NSString*) short_description
{
    NSString* result = [NSDate localizeDate:[ConverterUtils valueForKey:@"FromDate" fromProperties:_entity.properties]];
    if( !result )
    {
        result = @"-";
    }
    return result;
}

-(NSString*) responsible
{
    NSString* result = [ConverterUtils valueForKey:@"Responsible" fromProperties:_entity.properties];
    if( !result )
    {
        result = @"-";
    }
    return result;
}

-(NSString*) priority
{
    NSString* result = [ConverterUtils valueForKey:@"PriorityTxt" fromProperties:_entity.properties];
    if( !result )
    {
        result = @"-";
    }
    return result;
}

-(NSString*) status
{
    NSString* result = [ConverterUtils valueForKey:@"Status" fromProperties:_entity.properties];
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
    NSString* result = [ConverterUtils valueForKey:@"Note" fromProperties:_entity.properties];
    if( !result )
    {
        result = @"-";
    }
    return result;
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
            [self setValue:@"-" forKey:propertyName];
        }
        free(propertyArray);
    }
}

@end
