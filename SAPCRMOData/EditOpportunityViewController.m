//
//  EditOpportunityViewController.m
//  SAPCRMOData
//
//  Created by Nyisztor, Karoly on 2015. 07. 29..
//  Copyright (c) 2015. SAP-SE. All rights reserved.
//

#import "EditOpportunityViewController.h"
#import "DataManager.h"
#import "UIColor+Extension.h"
#import "NSDate+Extension.h"

@interface EditOpportunityViewController ()

- (IBAction)onNameChanged:(UITextField *)sender;
- (IBAction)onRevenueChanged:(UITextField *)sender;
- (IBAction)onStatusChanged:(UITextField *)sender;
- (IBAction)onStartDateChanged:(UITextField *)sender;

- (IBAction)onSavePressed:(id)sender;
- (IBAction)onDeletePressed:(id)sender;
- (IBAction)onCancelPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *expRevenueField;
@property (weak, nonatomic) IBOutlet UITextField *statusField;
@property (weak, nonatomic) IBOutlet UITextField *startDateField;

@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@end

@implementation EditOpportunityViewController
{
    BOOL m_IsCreating; ///< indicates whether we are editing an existing entry or creating a new one
    
    NSString* m_OldName;
    NSString* m_NewName;
    NSNumber* m_OldExpRevenue;
    NSNumber* m_NewExpRevenue;
    NSString* m_OldStatus;
    NSString* m_NewStatus;
    NSDate* m_OldStartDate;
    NSDate* m_NewStartDate;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if( !self.opportunity )
    {
        m_NewName = m_OldName = @"";
        m_NewExpRevenue = m_OldExpRevenue = @(0);
        m_NewStatus = m_OldStatus = @"";
        
        _titleLabel.text = NSLocalizedString(@"New Opportinity", nil);
        _deleteButton.backgroundColor = [UIColor lightGrayColor];
        _deleteButton.enabled = NO;
        
        m_IsCreating = YES;
        self.opportunity = [[DataManager sharedInstance] insertedNewOpportunityInMOC];
    }
    else
    {
        m_NewName = m_OldName = _opportunity.name;
        m_NewExpRevenue = m_OldExpRevenue = _opportunity.expRevenue;
        m_NewStatus = m_OldStatus = _opportunity.status;
        m_NewStartDate = m_OldStartDate = _opportunity.startDate;
    }
    
    _nameField.text = m_OldName;
    _expRevenueField.text = m_OldExpRevenue.stringValue;
    _statusField.text = m_OldStatus;
    _startDateField.text = m_OldStartDate ? [NSDate localizeDate:m_OldStartDate] : @"";

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
- (IBAction)onNameChanged:(UITextField *)sender;
{
    m_NewName = sender.text;
    [self flipSaveButton];
}

- (IBAction)onRevenueChanged:(UITextField *)sender;
{
    m_NewExpRevenue = [NSNumber numberWithInteger: [sender.text integerValue]];
    [self flipSaveButton];
}

- (IBAction)onStatusChanged:(UITextField *)sender;
{
    m_NewStatus = sender.text;
    [self flipSaveButton];
}

- (IBAction)onStartDateChanged:(UITextField *)sender;
{
    m_NewStartDate = [NSDate dateFromString:sender.text];
    [self flipSaveButton];
}

- (IBAction)onSavePressed:(id)sender
{
    _opportunity.name = m_NewName ? m_NewName : @"";
    _opportunity.expRevenue = m_NewExpRevenue ? m_NewExpRevenue : @(0);
    _opportunity.status = m_NewStatus ? m_NewStatus : @"";
    _opportunity.startDate = m_NewStartDate;
    
    [[DataManager sharedInstance] saveContext];
    
    if( m_IsCreating )
    {
        if( _delegate && [_delegate respondsToSelector:@selector(shouldCreateOpportunity:)] )
        {
            [_delegate shouldCreateOpportunity:_opportunity];
        }
    }
    else
    {
        if( _delegate && [_delegate respondsToSelector:@selector(shouldUpdateOpportunity:)] )
        {
            [_delegate shouldUpdateOpportunity:_opportunity];
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
    if( _delegate && [_delegate respondsToSelector:@selector(shouldDeleteOpportunity:)] )
    {
        [_delegate shouldDeleteOpportunity:_opportunity];
    }
    
    [self dismiss];
}

#pragma mark - Helpers
-(void) flipSaveButton
{
    if( [m_OldName isEqualToString:m_NewName]
       && [m_OldExpRevenue isEqualToNumber:m_NewExpRevenue]
       && [m_OldStatus isEqualToString:m_NewStatus]
       && [m_OldStartDate isEqualToDate:m_NewStartDate])
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
