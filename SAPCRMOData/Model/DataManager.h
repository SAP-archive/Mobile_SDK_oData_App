//
//  DataManager.h
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.13..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DBObjects.h"
#import "Constants.h"

@interface DataManager : NSObject

/**
 *  Returns the Singleton instance
 */
+(DataManager*) sharedInstance;

/**
 *  Persists all changes to the database
 */
-(void) saveContext;

/**
 *  Rolls back changes
 */
-(void) rollback;

#pragma mark - Retrieving Data
/**
 *  Returns all items for all types orderd by given criteria
 *
 *  @param orderedBy_in name or creation date
 *
 *  @return dictionary< type : array<BaseItem*> >
 */
-(NSDictionary*) allItemsByTypeOrderedBy:(E_ORDER_TYPE)orderedBy_in;
/**
 *  Returns the list of items (contacts, deals, tasks, projects, etc) ordered by their name or creation date
 *
 *  @param orderedBy_in order can be name or creation date
 *
 *  @return list of contacts
 */
- (NSArray*) itemsOfType:(E_OBJECT_TYPE)type_in orderedBy:(E_ORDER_TYPE)orderedBy_in;

#pragma mark - Retrieving Data

/**
 *  Returns Account by ID
 *
 *  @param id_in <#id_in description#>
 *
 *  @return <#return value description#>
 */
-(Account*) accountForID:(NSNumber*)id_in;

/**
 *  Returns Contact by ID
 *
 *  @param id_in <#id_in description#>
 *
 *  @return <#return value description#>
 */
-(Contact*) contactForID:(NSNumber*)id_in;


/**
 *  Returns Appointment by ID
 *
 *  @param id_in <#id_in description#>
 *
 *  @return <#return value description#>
 */
-(Appointment*) appointmentForID:(NSNumber*)id_in;

/**
 *  Returns Opprotunity by ID
 *
 *  @param id_in <#id_in description#>
 *
 *  @return <#return value description#>
 */
-(Opportunity*) opportunityForID:(NSNumber*)id_in;

#pragma mark - In-memory Object Creation and Maintenance


/**
 *  Creates a new Collection object in memory; call saveContext after setup to persist it to DB
 *
 *  @return in-memory Collection instance; type, name and decription must be filled after init
 */
-(Collection*) insertedNewCollectionInMOC;

/**
 *  Creates a new Account object in memory; call saveContext after setup to persist it to DB
 *
 *  @return in-memory Account instance
 */
-(Account*) insertedNewAccountInMOC;


/**
 *  Creates a new Contact object in memory; call saveContext after setup to persist it to DB
 *
 *  @return in-memory Contact instance
 */
-(Contact*) insertedNewContactInMOC;


/**
 *  Creates a new Appointment object in memory; call saveContext after setup to persist it to DB
 *
 *  @return in-memory Appointment instance
 */
-(Appointment*) insertedNewAppointmentInMOC;

/**
 *  Creates a new Opportunity object in memory; call saveContext after setup to persist it to DB
 *
 *  @return in-memory Opportunity instance
 */
-(Opportunity*) insertedNewOpportunityInMOC;

@property( nonatomic, assign ) BOOL isForcedRefetch; ///< determines whether data must be refetched from the DB even if already loaded to memory

@end
