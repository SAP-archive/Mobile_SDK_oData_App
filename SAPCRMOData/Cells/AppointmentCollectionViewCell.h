//
//  AppointmentCollectionViewCell.h
//  SAPCRMOData
//
//  Created by Nyisztor, Karoly on 2015. 01. 14..
//  Copyright (c) 2015. SAP-SE. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppointmentCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *responsible;
@property (weak, nonatomic) IBOutlet UILabel *priority;
@property (weak, nonatomic) IBOutlet UILabel *status;
@property (weak, nonatomic) IBOutlet UILabel *dueDate;
@property (weak, nonatomic) IBOutlet UILabel *comments;

@end
