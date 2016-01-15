//
//  AccountConverter.m
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.16..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import "AccountConverter.h"
#import "ConverterUtils.h"
#import "NSDate+Extension.h"

@import ObjectiveC;

@interface AccountConverter()

#pragma mark - Common set of CRM OData Entity specific properties
@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSString* short_description;

#pragma mark - Contact and Account related properties
@property (strong, nonatomic) NSString* function;
@property (strong, nonatomic) NSString* company;
@property (strong, nonatomic) NSString* phone;

#pragma mark - Contact, Account, Appointment and Opportunity common properties
@property (strong, nonatomic) NSString* dueDate;

#pragma mark - Appointment related properties
@property (strong, nonatomic) NSString* responsible;
@property (strong, nonatomic) NSString* priority;

#pragma mark - Appointment and Opportunity related properties
@property (strong, nonatomic) NSString* comment;
@property (strong, nonatomic) NSString* status;

#pragma mark - Opportunity related properties
@property (strong, nonatomic) NSNumber* expectedRevenue;
@property (strong, nonatomic) NSString* startDate;

@property (strong, nonatomic) id<SODataEntity> entity;

@end

// Raw structure
/*
 CRM_BUPA_ODATA.Account
 {
 name2: __NSCFConstantString
 category: __NSCFString
 birthDate: (null)
 eTag: __NSCFString
 isMyAccount: __NSCFBoolean
 title: __NSCFConstantString
 name1: __NSCFConstantString
 academicTitle: __NSCFConstantString
 fullName: __NSCFConstantString
 academicTitleID: __NSCFConstantString
 accountID: __NSCFString
 titleID: __NSCFConstantString
 }
 */
@implementation AccountConverter

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
    NSString* result = [ConverterUtils valueForKey:@"accountID" fromProperties:_entity.properties];
    return result ? result : @"-";
}

-(NSString*) short_description
{
    NSString* result = [ConverterUtils valueForKey:@"fullName" fromProperties:_entity.properties];
    return result ? result : @"-";
}

-(NSString*) function
{
    NSString* result = [ConverterUtils valueForKey:@"title" fromProperties:_entity.properties];
    return result ? result : @"-";
}

-(NSString*) phone
{
    // !!! placeholder
    return @"+1 289 767 544";
}

-(NSString*) dueDate
{
    //XXX fake it for now
    NSDate* dueDate = [NSDate dateWithTimeIntervalSinceNow:30*24*60*60];
    return [NSDate localizeDate:dueDate];
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
