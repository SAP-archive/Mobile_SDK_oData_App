//
//  ContactCollectionViewCell.h
//  SAPCRMOData
//
//  Created by Nyisztor, Karoly on 2015. 01. 09..
//  Copyright (c) 2015. SAP-SE. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *jobTitle;
@property (weak, nonatomic) IBOutlet UILabel *company;
@property (weak, nonatomic) IBOutlet UITextView *phone;
@property (weak, nonatomic) IBOutlet UILabel *dueDate;

@end
