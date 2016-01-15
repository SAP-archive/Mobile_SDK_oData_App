//
//  CoreDataConverting.h
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.16..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SODataEntity.h"
#import "Constants.h"

/**
 *  Defines the interface for all CRM OData to CoreData Mapper classes
 */
@protocol CoreDataConverting <NSObject>

/**
 *  Instantiates a mapper with given type
 *
 *  @param type_in <#type_in description#>
 *
 *  @return <#return value description#>
 */
-(instancetype) initWithEntity:(id<SODataEntity>)entity_in;

// entity related
@property (strong, nonatomic, readonly) NSString* resourcePath;
@property (strong, nonatomic, readonly) NSString* editResourcePath;
@property (strong, nonatomic, readonly) NSString* typeName;

#pragma mark - Common set of CRM OData Entity specific properties
@property (strong, nonatomic, readonly) NSString* name;
@property (strong, nonatomic, readonly) NSString* short_description;

#pragma mark - Contact and Account related properties
@property (strong, nonatomic, readonly) NSString* function; // e.g. "Sales Representative"
@property (strong, nonatomic, readonly) NSString* company;
@property (strong, nonatomic, readonly) NSString* phone;

#pragma mark - Contact, Account, Appointment and Opportunity common properties
@property (strong, nonatomic, readonly) NSString* dueDate;

#pragma mark - Appointment related properties
@property (strong, nonatomic, readonly) NSString* responsible;
@property (strong, nonatomic, readonly) NSString* priority;

#pragma mark - Appointment and Opportunity related properties
@property (strong, nonatomic, readonly) NSString* comment;
@property (strong, nonatomic, readonly) NSString* status;

#pragma mark - Opportunity related properties
@property (strong, nonatomic, readonly) NSNumber* expectedRevenue;
@property (strong, nonatomic, readonly) NSString* startDate;

@end
