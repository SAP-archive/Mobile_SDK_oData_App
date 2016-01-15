//
//  EditContactViewController.m
//  SAPCRMOData
//
//  Created by Nyisztor, Karoly on 2015. 07. 21..
//  Copyright (c) 2015. SAP-SE. All rights reserved.
//

#import "EditContactViewController.h"
#import "DataManager.h"
#import "UIColor+Extension.h"

@interface EditContactViewController ()

- (IBAction)onFirstNameChanged:(UITextField *)sender;
- (IBAction)onLastNameChanged:(UITextField *)sender;
- (IBAction)onCompanyChanged:(UITextField *)sender;
- (IBAction)onRoleChanged:(UITextField *)sender;

- (IBAction)onSavePressed:(id)sender;
- (IBAction)onCancelPressed:(id)sender;
- (IBAction)onDeletePressed:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextField *firstNameField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameField;
@property (weak, nonatomic) IBOutlet UITextField *companyField;
@property (weak, nonatomic) IBOutlet UITextField *roleField;

@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@end

@implementation EditContactViewController
{
    BOOL m_IsCreating; ///< indicates whether we are editing an existing entry or creating a new one
    
    NSString* m_OldFirstName;
    NSString* m_NewFirstName;
    NSString* m_OldLastName;
    NSString* m_NewLastName;
    NSString* m_OldCompany;
    NSString* m_NewCompany;
    NSString* m_OldRole;
    NSString* m_NewRole;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if( !self.contact )
    {
        m_NewFirstName = m_OldFirstName = @"";
        m_NewLastName = m_OldLastName = @"";
        m_NewCompany = m_OldCompany = @"";
        m_NewRole = m_OldRole = @"";

        _titleLabel.text = NSLocalizedString(@"New Contact", nil);
        _deleteButton.backgroundColor = [UIColor lightGrayColor];
        _deleteButton.enabled = NO;
        
        m_IsCreating = YES;
        self.contact = [[DataManager sharedInstance] insertedNewContactInMOC];
    }
    else
    {
        m_NewFirstName = m_OldFirstName = _contact.firstName;
        m_NewLastName = m_OldLastName = _contact.lastName;
        m_NewCompany = m_OldCompany = _contact.company;
        m_NewRole = m_OldRole = _contact.function;
        
        // XXX: tweak for missing first and last name
        if( (m_OldFirstName.length == 0) && (m_OldLastName.length == 0) )
        {
            NSString* fullname = _contact.name;
            if( fullname.length )
            {
                NSArray* names = [fullname componentsSeparatedByString:@" "];
                if( names.count >= 2 )
                {
                    m_NewFirstName = m_OldFirstName = names[0];
                    m_NewLastName = m_OldLastName = names[1];
                }
            }
        }

    }
    
    _firstNameField.text = m_OldFirstName;
    _lastNameField.text = m_OldLastName;
    _companyField.text = m_OldCompany;
    _roleField.text = m_OldRole;
    
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

- (IBAction)onFirstNameChanged:(UITextField *)sender
{
    m_NewFirstName = sender.text;
    [self flipSaveButton];
}

- (IBAction)onLastNameChanged:(UITextField *)sender
{
    m_NewLastName = sender.text;
    [self flipSaveButton];
}

- (IBAction)onCompanyChanged:(UITextField *)sender
{
    m_NewCompany = sender.text;
    [self flipSaveButton];
}

- (IBAction)onRoleChanged:(UITextField *)sender
{
    m_NewRole = sender.text;
    [self flipSaveButton];
}

- (IBAction)onSavePressed:(id)sender
{
    _contact.lastName = m_NewLastName ? m_NewLastName : @"";
    _contact.firstName = m_NewFirstName ? m_NewFirstName : @"";
    _contact.company = m_NewCompany ? m_NewCompany : @"";
    _contact.function = m_NewRole ? m_NewRole : @"";
    
    NSString* name = [NSString stringWithFormat:@"%@ %@", m_NewFirstName, m_NewLastName];
    _contact.name = name ? name : @"";
    
    [[DataManager sharedInstance] saveContext];
    
    if( m_IsCreating )
    {
        if( _delegate && [_delegate respondsToSelector:@selector(shouldCreateContact:)] )
        {
            [_delegate shouldCreateContact:_contact];
        }
    }
    else
    {
        if( _delegate && [_delegate respondsToSelector:@selector(shouldUpdateContact:)] )
        {
            [_delegate shouldUpdateContact:_contact];
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
    if( _delegate && [_delegate respondsToSelector:@selector(shouldDeleteContact:)] )
    {
        [_delegate shouldDeleteContact:_contact];
    }
    
    [self dismiss];
}


#pragma mark - Helpers
-(void) flipSaveButton
{
    if( [m_OldFirstName isEqualToString:m_NewFirstName]
        && [m_OldLastName isEqualToString:m_NewLastName]
       && [m_OldCompany isEqualToString:m_NewCompany]
       && [m_OldRole isEqualToString:m_NewRole] )
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
