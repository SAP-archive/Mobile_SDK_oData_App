//
//  EditOpportunityViewController.h
//  SAPCRMOData
//
//  Created by Nyisztor, Karoly on 2015. 07. 29..
//  Copyright (c) 2015. SAP-SE. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Opportunity;

@protocol OpportunityUpdating <NSObject>

-(void) shouldUpdateOpportunity:(Opportunity*)opportunity_in;

-(void) shouldCreateOpportunity:(Opportunity*)opportunity_in;

-(void) shouldDeleteOpportunity:(Opportunity*)opportunity_in;

@end


@interface EditOpportunityViewController : UIViewController

@property (assign, nonatomic) id<OpportunityUpdating> delegate;
@property (retain, nonatomic) Opportunity* opportunity;

@end
