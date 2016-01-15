//
//  EditContactViewController.h
//  SAPCRMOData
//
//  Created by Nyisztor, Karoly on 2015. 07. 21..
//  Copyright (c) 2015. SAP-SE. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Contact;

@protocol ContactUpdating <NSObject>

-(void) shouldUpdateContact:(Contact*)contact_in;

-(void) shouldCreateContact:(Contact*)contact_in;

-(void) shouldDeleteContact:(Contact*)contact_in;

@end

@interface EditContactViewController : UIViewController

@property (assign, nonatomic) id<ContactUpdating> delegate;
@property (retain, nonatomic) Contact* contact;

@end
