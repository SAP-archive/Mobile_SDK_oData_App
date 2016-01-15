//
//  Collection.h
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.13..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BaseItem;

@interface Collection : NSManagedObject

@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSString * collectionName;
@property (nonatomic, retain) NSData * thumbnail;
@property (nonatomic, retain) NSString * descript_ion;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSSet *toItems;
@end

@interface Collection (CoreDataGeneratedAccessors)

- (void)addToItemsObject:(BaseItem *)value;
- (void)removeToItemsObject:(BaseItem *)value;
- (void)addToItems:(NSSet *)values;
- (void)removeToItems:(NSSet *)values;

@end
