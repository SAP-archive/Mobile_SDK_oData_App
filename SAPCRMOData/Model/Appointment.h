//
//  Appointment.h
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.13..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BaseItem.h"

@interface Appointment : BaseItem

@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSString * responsible;
@property (nonatomic, retain) NSNumber * isMine;
@property (nonatomic, retain) NSString * descript_ion;
@property (nonatomic, retain) NSString * note;
@property (nonatomic, retain) NSDate * changedAt;
@property (nonatomic, retain) NSString * priority;
@property (nonatomic, retain) NSNumber * isAllDay;
@property (nonatomic, retain) NSDate * startDate;

@end
