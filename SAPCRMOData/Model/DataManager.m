//
//  DataManager.m
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.13..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import "DataManager.h"
@import CoreData;
@import UIKit;

static DataManager* sDataManagerInstance;

@interface DataManager()

@property(nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property(nonatomic, strong) NSManagedObjectModel* managedObjectModel;
@property(nonatomic, strong)NSPersistentStoreCoordinator* persistentStoreCoordinator;
@property (strong, nonatomic) NSMutableDictionary* listsByType; ///< List of native DB objects by type; key is E_OBJECT_TYPE
@property (strong, nonatomic) NSMutableArray* listsArray; ///< array<List*>

@end

@implementation DataManager

+(DataManager*) sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sDataManagerInstance = [[DataManager alloc] init];
    });
    
    return sDataManagerInstance;
}

-(instancetype) init
{
    self = [super init];
    if( self )
    {
        self.managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
        self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        
        // add the persistent store
        /*
        NSURL* applicationSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
        
        if( ![[NSFileManager defaultManager] fileExistsAtPath:applicationSupportURL.path ] )
        {
            NSError* fileSystemError = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:applicationSupportURL.path
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:&fileSystemError];
            if(fileSystemError)
            {
                NSLog(@"Error creating database directory %@", [fileSystemError localizedDescription]);
            }
        }
        NSURL* localStore = [applicationSupportURL URLByAppendingPathComponent:@"SwipeCRM.sqlite"];        
        */
        
        //        [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:localStore options:nil error:nil];
        
        // Create in-memory store
        NSError* error = nil;
        [_persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
        if( error )
        {
#ifdef DEBUG
            NSLog( @"Error while creating persistent store: %@\n%@", error, [error userInfo] );
#endif
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Persistent Store crate failed!", nil)
                                                                message:NSLocalizedString(@"Could not create store", nil)
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil, nil];
            [alertView show];

        }

        self.managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _managedObjectContext.persistentStoreCoordinator = _persistentStoreCoordinator;
        
//        _managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
        
        self.listsByType = [NSMutableDictionary dictionary];
    }
    return self;
}

-(void) saveContext
{
    if (_managedObjectContext != nil)
    {
        if ([_managedObjectContext hasChanges])
        {
			[_managedObjectContext performBlockAndWait:^{
                
				NSError *error = nil;
				if (![_managedObjectContext save:&error])
                {
#ifdef DEBUG
                    NSLog( @"Error while saving to DB: %@\n%@", error, [error userInfo] );
#endif
                    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Database update failed!", nil)
                                                                        message:NSLocalizedString(@"Could not save data", nil)
                                                                       delegate:nil
                                                              cancelButtonTitle:@"Ok"
                                                              otherButtonTitles:nil, nil];
                    [alertView show];
#ifdef DEBUG
                    // Replace this implementation with code to handle the error appropriately.
					// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
					NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
					abort();
#endif
				}
			}];
        }
    }
}


-(void) rollback
{
    if (_managedObjectContext)
    {
        if ([_managedObjectContext hasChanges])
        {
			[_managedObjectContext performBlockAndWait:^{
				[_managedObjectContext rollback];
#ifdef DEBUG
                NSLog(@"Changes rolled back!");
#endif
			}];
        }
    }
}

#pragma mark - Retrieving Data
-(NSDictionary*) allItemsByTypeOrderedBy:(E_ORDER_TYPE)orderedBy_in
{
    [self itemsOfType:ACCOUNTS orderedBy:orderedBy_in];
    [self itemsOfType:APPOINTMENTS orderedBy:orderedBy_in];
    [self itemsOfType:CONTACTS orderedBy:orderedBy_in];
    [self itemsOfType:DEALS orderedBy:orderedBy_in];
    [self itemsOfType:TASKS orderedBy:orderedBy_in];
    [self itemsOfType:CUSTOMERS orderedBy:orderedBy_in];
    [self itemsOfType:OPPORTUNITIES orderedBy:orderedBy_in];
    return _listsByType;
}

- (NSArray*) itemsOfType:(E_OBJECT_TYPE)type_in orderedBy:(E_ORDER_TYPE)orderedBy_in
{
    if( !_managedObjectContext )
    {
        return [NSArray array];
    }
    
    NSArray* items = _listsByType[@(type_in)];

    if( !items || _isForcedRefetch )
    {

        NSString* className = [self classNameForType:type_in];

        if( !className.length )
        {
            NSLog( @"%@", [NSString stringWithFormat:@"Could not create class name string for type %lu", type_in] );
            return [NSArray array];
        }
    
        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:className];
        NSSortDescriptor* sortDescriptor = [self sortDescriptorForOrder:orderedBy_in];
        
        [fetchRequest setSortDescriptors:@[sortDescriptor]];
        items = [self executeFetchRequest:fetchRequest];
        // add to dictionary
        if( items )
        {
            _listsByType[@(type_in)] = items;
        }
#ifdef DEBUG
        if( !items.count )
        {
            NSLog( @"%@", [NSString stringWithFormat:@"No items of type %lu found in the DB", type_in] );
        }
        
        for( BaseItem* item in items )
        {
            NSLog(@"Item %@ type=%lu createdAt=%@", item.name, type_in, item.timestamp);
        }
#endif
    }
    
    return items;
}

-(Account*) accountForID:(NSNumber*)id_in
{
    Account* result = nil;
    
    // fetch BaseItem
    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"id == %@", id_in];
    fetchRequest.predicate = predicate;
    
    NSArray* items = [self executeFetchRequest:fetchRequest];
    
#ifdef DEBUG
    if( items.count > 1 )
    {
        NSString* msg = [NSString stringWithFormat:@"Duplicate account entries found for ID %@", id_in];
        NSLog(@"%@", msg);
        //    NSAssert( items.count <= 0, @"There should be no more than 1 entries with a given ID" );
    }
#endif
    
    if( !items.count )
    {
#ifdef DEBUG
        NSString* msg = [NSString stringWithFormat:@"No persisted Account found for ID %@", id_in];
        NSLog(@"%@", msg);
#endif
    }
    else
    {
        result = items[0];
    }
    return result;
}

-(Contact*) contactForID:(NSNumber*)id_in
{
    Contact* result = nil;
    
    // fetch BaseItem
    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Contact"];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"id == %@", id_in];
    fetchRequest.predicate = predicate;

    NSArray* items = [self executeFetchRequest:fetchRequest];
    
#ifdef DEBUG
    if( items.count > 1 )
    {
        NSString* msg = [NSString stringWithFormat:@"Duplicate contact entries found for ID %@", id_in];
        NSLog(@"%@", msg);
//    NSAssert( items.count <= 0, @"There should be no more than 1 entries with a given ID" );
    }
#endif
    
    if( !items.count )
    {
#ifdef DEBUG
        NSString* msg = [NSString stringWithFormat:@"No persisted Contact found for ID %@", id_in];
        NSLog(@"%@", msg);
#endif
    }
    else
    {
        result = items[0];
    }
    return result;
}

-(Appointment*) appointmentForID:(NSNumber*)id_in
{
    Appointment* result = nil;
    
    // fetch BaseItem
    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Appointment"];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"id == %@", id_in];
    fetchRequest.predicate = predicate;
    
    NSArray* items = [self executeFetchRequest:fetchRequest];
    
#ifdef DEBUG
    if( items.count > 1 )
    {
        NSString* msg = [NSString stringWithFormat:@"Duplicate Appointment entries found for ID %@", id_in];
        NSLog(@"%@", msg);
        //    NSAssert( items.count <= 0, @"There should be no more than 1 entries with a given ID" );
    }
#endif
    
    if( !items.count )
    {
#ifdef DEBUG
        NSString* msg = [NSString stringWithFormat:@"No persisted Appointment found for ID %@", id_in];
        NSLog(@"%@", msg);
#endif
    }
    else
    {
        result = items[0];
    }
    return result;
}

-(Opportunity*) opportunityForID:(NSNumber*)id_in
{
    Opportunity* result = nil;
    
    // fetch BaseItem
    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Opportunity"];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"id == %@", id_in];
    fetchRequest.predicate = predicate;
    
    NSArray* items = [self executeFetchRequest:fetchRequest];
    
#ifdef DEBUG
    if( items.count > 1 )
    {
        NSString* msg = [NSString stringWithFormat:@"Duplicate Opportunity entries found for ID %@", id_in];
        NSLog(@"%@", msg);
        //    NSAssert( items.count <= 0, @"There should be no more than 1 entries with a given ID" );
    }
#endif
    
    if( !items.count )
    {
#ifdef DEBUG
        NSString* msg = [NSString stringWithFormat:@"No persisted Opportunity found for ID %@", id_in];
        NSLog(@"%@", msg);
#endif
    }
    else
    {
        result = items[0];
    }
    return result;
}

#pragma mark - In-memory Object Creation and Maintenance

-(Collection*) insertedNewCollectionInMOC
{
    return [self insertNewObjectOfType:[Collection class]];
}


-(Account*) insertedNewAccountInMOC
{
    return [self insertNewObjectOfType:[Account class]];
}

-(Contact*) insertedNewContactInMOC
{
    return [self insertNewObjectOfType:[Contact class]];
}

-(Appointment*) insertedNewAppointmentInMOC;
{
    return [self insertNewObjectOfType:[Appointment class]];
}

-(Opportunity*) insertedNewOpportunityInMOC;
{
    return [self insertNewObjectOfType:[Opportunity class]];
}

#pragma mark - Helpers
/**
 *  Helper for adding a new object of given class to the DB
 *
 *  @param class_in <#class_in description#>
 *
 *  @return <#return value description#>
 */
-(id) insertNewObjectOfType:(Class)class_in
{
    __block id retVal = nil;
    if( _managedObjectContext )
    {
        [_managedObjectContext performBlockAndWait:^{
            retVal = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(class_in) inManagedObjectContext:self.managedObjectContext];
        }];
    }
    return retVal;
}

/**
 *  Helper for executing a fetch request
 *
 *  @param request_in <#request_in description#>
 *
 *  @return <#return value description#>
 */
-(NSArray*) executeFetchRequest:(NSFetchRequest*)fetchRequest_in
{
    __block NSArray* retVal = nil;
    
    if( _managedObjectContext )
    {
        [_managedObjectContext performBlockAndWait:^{
            NSError* error = nil;
            retVal = [_managedObjectContext executeFetchRequest:fetchRequest_in error:&error];
#ifdef DEBUG
            if( error )
                NSLog( @"%@\n%@", error, [error userInfo] );
#endif
        }];
    }
    
    return retVal;
}

/**
 *  Creates a sort descriptor for given criteria
 *
 *  @param orderedBy_in <#orderedBy_in description#>
 *
 *  @return <#return value description#>
 */
-(NSSortDescriptor*) sortDescriptorForOrder:(E_ORDER_TYPE)orderedBy_in
{
    NSSortDescriptor* sortDescriptor = nil;
    switch( orderedBy_in )
    {
        case NAME:
        {
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
        } break;
        case DATE:
        {
            sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
        } break;
        default:
        {
            NSLog( @"Should not reach here" );
        }
    }
    return sortDescriptor;
}

/**
 *  Returns class name for given type
 *
 *  @param type_in <#type_in description#>
 *
 *  @return <#return value description#>
 */
-(NSString*) classNameForType:(E_OBJECT_TYPE)type_in
{
    NSString* className = nil;
    switch (type_in)
    {
        case ACCOUNTS:
        {
            className = NSStringFromClass([Account class]);
        } break;
        case CONTACTS:
        {
            className = NSStringFromClass([Contact class]);
        } break;
        case APPOINTMENTS:
        {
            className = NSStringFromClass([Appointment class]);
        } break;
        case OPPORTUNITIES:
        {
            className = NSStringFromClass([Opportunity class]);
        } break;
        default:
            break;
    }
    
    return className;
}

@end
