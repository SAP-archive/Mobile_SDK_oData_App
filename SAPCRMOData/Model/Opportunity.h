//
//  Opportunity.h
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.13..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BaseItem.h"

@interface Opportunity : BaseItem

@property (nonatomic, retain) NSNumber * expRevenue;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSDate * closeDate;
@property (nonatomic, retain) NSString * propability;
@property (nonatomic, retain) NSString * currPhaseText;
@property (nonatomic, retain) NSString * guid;
@property (nonatomic, retain) NSString * currency;

@end
