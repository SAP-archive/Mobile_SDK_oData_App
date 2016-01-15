//
//  Account.h
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.13..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BaseItem.h"

@interface Account : BaseItem

@property (nonatomic, retain) NSString * name1;
@property (nonatomic, retain) NSString * name2;
@property (nonatomic, retain) NSString * category;
@property (nonatomic, retain) NSDate * birthdate;
@property (nonatomic, retain) NSNumber * isMine;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * academicTitle;
@property (nonatomic, retain) NSString * fullName;

@end
