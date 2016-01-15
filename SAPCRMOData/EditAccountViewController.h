//
//  EditAccountViewController.h
//  SAPCRMOData
//
//  Created by Nyisztor, Karoly on 2015. 07. 13..
//  Copyright (c) 2015. SAP-SE. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Account;

@protocol AccountUpdating <NSObject>

-(void) shouldUpdateAccount:(Account*)account_in;

-(void) shouldCreateAccount:(Account*)account_in;

-(void) shouldDeleteAccount:(Account*)account_in;

@end

@interface EditAccountViewController : UIViewController

@property (assign, nonatomic) id<AccountUpdating> delegate;
@property (retain, nonatomic) Account* account;

@end
