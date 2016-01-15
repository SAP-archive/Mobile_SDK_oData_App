//
//  OpportunityCollectionViewCell.h
//  SAPCRMOData
//
//  Created by Nyisztor, Karoly on 2015. 01. 14..
//  Copyright (c) 2015. SAP-SE. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OpportunityCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *revenue;
@property (weak, nonatomic) IBOutlet UILabel *status;
@property (weak, nonatomic) IBOutlet UILabel *startDate;
@property (weak, nonatomic) IBOutlet UILabel *endDate;
@property (weak, nonatomic) IBOutlet UILabel *comments;

@end
