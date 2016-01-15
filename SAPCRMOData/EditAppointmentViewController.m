//
//  EditAppointmentViewController.m
//  SAPCRMOData
//
//  Created by Nyisztor, Karoly on 2015. 07. 29..
//  Copyright (c) 2015. SAP-SE. All rights reserved.
//

#import "EditAppointmentViewController.h"
#import "DataManager.h"
#import "UIColor+Extension.h"
#import "NSDate+Extension.h"

@interface EditAppointmentViewController ()

- (IBAction)onResponsibleChanged:(UITextField *)sender;   ///< name1
- (IBAction)onPriorityChanged:(UITextField *)sender;    ///< name2
- (IBAction)onStatusChanged:(UITextField *)sender;
- (IBAction)onDueDateChanged:(UITextField *)sender;
- (IBAction)onCommentsChanged:(UITextField *)sender;

- (IBAction)onSavePressed:(id)sender;
- (IBAction)onDeletePressed:(id)sender;
- (IBAction)onCancelPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextField *responsibleField;
@property (weak, nonatomic) IBOutlet UITextField *priorityField;
@property (weak, nonatomic) IBOutlet UITextField *statusField;
@property (weak, nonatomic) IBOutlet UITextField *dueDateField;
@property (weak, nonatomic) IBOutlet UITextField *commentsField;

@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@end

@implementation EditAppointmentViewController
{
    BOOL m_IsCreating; ///< indicates whether we are editing an existing entry or creating a new one
    
    NSString* m_OldResponsible;
    NSString* m_NewResponsible;
    NSString* m_OldPriority;
    NSString* m_NewPriority;
    NSString* m_OldStatus;
    NSString* m_NewStatus;
    NSDate* m_OldDueDate;
    NSDate* m_NewDueDate;
    NSString* m_OldComments;
    NSString* m_NewComments;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if( !self.appointment )
    {
        m_NewResponsible = m_OldResponsible = @"";
        m_NewPriority = m_OldPriority = @"";
        m_NewStatus = m_OldStatus = @"";
        
        _titleLabel.text = NSLocalizedString(@"New Appointment", nil);
        _deleteButton.backgroundColor = [UIColor lightGrayColor];
        _deleteButton.enabled = NO;
        
        m_IsCreating = YES;
        self.appointment = [[DataManager sharedInstance] insertedNewAppointmentInMOC];
    }
    else
    {
        m_NewResponsible = m_OldResponsible = _appointment.responsible;
        m_NewPriority = m_OldPriority = _appointment.priority;
        m_NewStatus = m_OldStatus = _appointment.status;
        m_NewDueDate = m_OldDueDate = _appointment.endDate;
        m_OldComments = m_NewComments = _appointment.note;
    }
    
    _responsibleField.text = m_OldResponsible;
    _priorityField.text = m_OldPriority;
    _statusField.text = m_OldStatus;
    _dueDateField.text = m_OldDueDate ? [NSDate localizeDate:m_OldDueDate] : @"";
    _commentsField.text = m_OldComments;
    // save button initially inactive
    _saveButton.backgroundColor = [UIColor lightGrayColor];
    _saveButton.enabled = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (IBAction)onResponsibleChanged:(UITextField *)sender
{
    m_NewResponsible = sender.text;
    [self flipSaveButton];
}

- (IBAction)onPriorityChanged:(UITextField *)sender
{
    m_NewPriority = sender.text;
    [self flipSaveButton];
}

- (IBAction)onStatusChanged:(UITextField *)sender
{
    m_NewStatus = sender.text;
    [self flipSaveButton];
}

- (IBAction)onDueDateChanged:(UITextField *)sender
{
    // switch to date picker 
    m_NewDueDate = [NSDate dateFromString:sender.text];
    [self flipSaveButton];
}

- (IBAction)onCommentsChanged:(UITextField *)sender
{
    m_NewComments = sender.text;
    [self flipSaveButton];
}

- (IBAction)onSavePressed:(id)sender
{
    _appointment.responsible = m_NewResponsible ? m_NewResponsible : @"";
    _appointment.priority = m_NewPriority ? m_NewPriority : @"";
    _appointment.status = m_NewStatus ? m_NewStatus : @"";
    _appointment.endDate = m_NewDueDate;
    
    [[DataManager sharedInstance] saveContext];
    
    if( m_IsCreating )
    {
        if( _delegate && [_delegate respondsToSelector:@selector(shouldCreateAppointment:)] )
        {
            [_delegate shouldCreateAppointment:_appointment];
        }
    }
    else
    {
        if( _delegate && [_delegate respondsToSelector:@selector(shouldUpdateAppointment:)] )
        {
            [_delegate shouldUpdateAppointment:_appointment];
        }
    }
    
    [self dismiss];
}

- (IBAction)onCancelPressed:(id)sender
{
    [[DataManager sharedInstance] rollback];
    
    [self dismiss];
}

- (IBAction)onDeletePressed:(id)sender
{
    if( _delegate && [_delegate respondsToSelector:@selector(shouldDeleteAppointment:)] )
    {
        [_delegate shouldDeleteAppointment:_appointment];
    }
    
    [self dismiss];
}

#pragma mark - Helpers
-(void) flipSaveButton
{
    if( [m_OldResponsible isEqualToString:m_NewResponsible]
       && [m_OldPriority isEqualToString:m_NewPriority]
       && [m_OldStatus isEqualToString:m_NewStatus]
       && [m_OldDueDate isEqualToDate:m_NewDueDate]
       && [m_OldComments isEqualToString:m_NewComments])
    {
        _saveButton.backgroundColor = [UIColor lightGrayColor];
        _saveButton.enabled = NO;
    }
    else
    {
        _saveButton.backgroundColor = [UIColor deepPurpleColor];
        _saveButton.enabled = YES;
    }
}

-(void) dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
