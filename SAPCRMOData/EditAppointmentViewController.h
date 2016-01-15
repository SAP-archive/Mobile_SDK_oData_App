//
//  EditAppointmentViewController.h
//  SAPCRMOData
//
//  Created by Nyisztor, Karoly on 2015. 07. 29..
//  Copyright (c) 2015. SAP-SE. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Appointment;

@protocol AppointmentUpdating <NSObject>

-(void) shouldUpdateAppointment:(Appointment*)appointment_in;

-(void) shouldCreateAppointment:(Appointment*)appointment_in;

-(void) shouldDeleteAppointment:(Appointment*)appointment_in;

@end


@interface EditAppointmentViewController : UIViewController

@property (assign, nonatomic) id<AppointmentUpdating> delegate;
@property (retain, nonatomic) Appointment* appointment;

@end
