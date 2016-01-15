//
//  BaseItem.h
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.13..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface BaseItem : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSString * descript_ion;
@property (nonatomic, retain) NSManagedObject *toParent;

@property (nonatomic, retain) NSString * resourcePath;
@property (nonatomic, retain) NSString * editResourcePath;
@property (nonatomic, retain) NSString * typeName;

@end
