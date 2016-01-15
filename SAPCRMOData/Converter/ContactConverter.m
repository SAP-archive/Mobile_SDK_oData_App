//
//  ContactConverter.m
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.16..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import "ContactConverter.h"
#import "ConverterUtils.h"
#import "NSDate+Extension.h"

@import ObjectiveC;

@interface ContactConverter()

#pragma mark - Common set of CRM OData Entity specific properties
@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSString* lastName;
@property (strong, nonatomic) NSString* firstName;
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
 CRM_BUPA_ODATA.Contact
 {
 lastName: __NSCFConstantString
 firstName: __NSCFConstantString
 birthDate: (null)
 function: __NSCFConstantString
 company: __NSCFConstantString
 eTag: __NSCFString
 isMyContact: __NSCFBoolean
 title: __NSCFConstantString
 academicTitle: __NSCFConstantString
 fullName: __NSCFConstantString
 academicTitleID: __NSCFConstantString
 isMainContact: __NSCFBoolean
 accountID: __NSCFString
 department: __NSCFConstantString
 contactID: __NSCFString
 titleID: __NSCFConstantString
 }
*/
/*
<Contact: 0x7f88c16c3e80> (entity: Contact; id: 0x7f88c16c3f30 <x-coredata:///Contact/tE6B67EC0-E897-4393-8339-40039A35DF836> ; data: {
                           academicTitle = nil;
                           birthdate = nil;
                           category = nil;
                           company = "Crown Books";
                           "descript_ion" = "Crown Books";
                           firstName = nil;
                           fullName = nil;
                           function = "-";
                           id = 0;
                           isMine = nil;
                           lastName = nil;
                           name = "Wilbert C. Petty";
                           name1 = nil;
                           name2 = nil;
                           timestamp = nil;
                           title = nil;
                           toParent = "0x7f88c2ad4430 <x-coredata:///Collection/tE6B67EC0-E897-4393-8339-40039A35DF832>";
                           })
*/
@implementation ContactConverter

-(instancetype) initWithEntity:(id<SODataEntity>)entity_in
{
    self = [super init];
    
    if( self )
    {
        self.entity = entity_in;
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
    NSString* name = [ConverterUtils valueForKey:@"fullName" fromProperties:_entity.properties];
    if( name == nil || name.length == 0 )
    {
        NSString* first = [ConverterUtils valueForKey:@"firstName" fromProperties:_entity.properties];
        NSString* last = [ConverterUtils valueForKey:@"lastName" fromProperties:_entity.properties];
        name = [NSString stringWithFormat:@"%@ %@", first, last];
    }
    return name ? name : @"";
}

-(NSString*) firstName
{
    NSString* result = [ConverterUtils valueForKey:@"firstName" fromProperties:_entity.properties];
    return result ? result : @"";
}

-(NSString*) lastName
{
    NSString* result = [ConverterUtils valueForKey:@"lastName" fromProperties:_entity.properties];
    return result ? result : @"";
}


-(NSString*) short_description
{
    NSString* result = [ConverterUtils valueForKey:@"descript_ion" fromProperties:_entity.properties];
    return result ? result : @"";
}

-(NSString*) function
{
    NSString* result = [ConverterUtils valueForKey:@"function" fromProperties:_entity.properties];
    return result ? result : @"";
}

-(NSString*) company
{
    NSString* result = [ConverterUtils valueForKey:@"company" fromProperties:_entity.properties];
    return result ? result : @"";
}

-(NSString*) phone
{
    return @"+1 289 767 544";
//    return [ConverterUtils valueForKey:@"company" fromProperties:_entity.properties];
}

-(NSString*) dueDate
{
    //XXX fake it for now
    NSDate* dueDate = [NSDate dateWithTimeIntervalSinceNow:30*24*60*60];
    return [NSDate localizeDate:dueDate];
}

@end
