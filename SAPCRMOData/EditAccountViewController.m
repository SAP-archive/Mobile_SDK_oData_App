//
//  EditAccountViewController.m
//  SAPCRMOData
//
//  Created by Nyisztor, Karoly on 2015. 07. 13..
//  Copyright (c) 2015. SAP-SE. All rights reserved.
//

#import "EditAccountViewController.h"
#import "DataManager.h"
#import "UIColor+Extension.h"

@interface EditAccountViewController ()

- (IBAction)onFirstNameChanged:(UITextField *)sender;   ///< name1
- (IBAction)onLastNameChanged:(UITextField *)sender;    ///< name2
- (IBAction)onTitleChanged:(UITextField *)sender;

- (IBAction)onSavePressed:(id)sender;
- (IBAction)onDeletePressed:(id)sender;
- (IBAction)onCancelPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextField *firstNameField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameField;
@property (weak, nonatomic) IBOutlet UITextField *titleField;

@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@end

@implementation EditAccountViewController
{
    BOOL m_IsCreating; ///< indicates whether we are editing an existing entry or creating a new one
    
    NSString* m_OldFirstName;
    NSString* m_NewFirstName;
    NSString* m_OldLastName;
    NSString* m_NewLastName;
    NSString* m_OldTitle;
    NSString* m_NewTitle;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if( !self.account )
    {
        m_NewFirstName = m_OldFirstName = @"";
        m_NewLastName = m_OldLastName = @"";
        m_NewTitle = m_OldTitle = @"";

        _titleLabel.text = NSLocalizedString(@"New Account", nil);
        _deleteButton.backgroundColor = [UIColor lightGrayColor];
        _deleteButton.enabled = NO;
        
        m_IsCreating = YES;
        self.account = [[DataManager sharedInstance] insertedNewAccountInMOC];
    }
    else
    {
        m_NewFirstName = m_OldFirstName = _account.name1;
        m_NewLastName = m_OldLastName = _account.name2;
        m_NewTitle = m_OldTitle = _account.title;
        
        // XXX: tweak for missing first and last name
        if( (m_OldFirstName.length == 0) && (m_OldLastName.length == 0) )
        {
            NSString* fullname = _account.fullName ? _account.fullName : _account.name;
            if( fullname.length )
            {
                NSArray* names = [fullname componentsSeparatedByString:@" "];
                if( names.count == 1 )
                {
                    m_NewFirstName = m_OldFirstName = names[0];
                }
                else if( names.count == 2 )
                {
                    m_NewFirstName = m_OldFirstName = names[0];
                    m_NewLastName = m_OldLastName = names[1];
                }
            }
        }
    }
    
    _firstNameField.text = m_OldFirstName;
    _lastNameField.text = m_OldLastName;
    _titleField.text = m_OldTitle;

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

- (IBAction)onTitleChanged:(UITextField *)sender
{
    m_NewTitle = sender.text;
    [self flipSaveButton];
}

- (IBAction)onSavePressed:(id)sender
{
    _account.name1 = m_NewFirstName ? m_NewFirstName : @"";
    _account.name2 = m_NewLastName ? m_NewLastName : @"";
    _account.title = m_NewTitle ? m_NewTitle : @"";
    NSString* fullName = [NSString stringWithFormat:@"%@ %@", m_NewFirstName ? m_NewFirstName : @"", m_NewLastName ? m_NewLastName : @""];
    _account.fullName = _account.name = fullName ? fullName : @"";
    
    [[DataManager sharedInstance] saveContext];
    
    if( m_IsCreating )
    {
        if( _delegate && [_delegate respondsToSelector:@selector(shouldCreateAccount:)] )
        {
            [_delegate shouldCreateAccount:_account];
        }
    }
    else
    {
        if( _delegate && [_delegate respondsToSelector:@selector(shouldUpdateAccount:)] )
        {
            [_delegate shouldUpdateAccount:_account];
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
    if( _delegate && [_delegate respondsToSelector:@selector(shouldDeleteAccount:)] )
    {
        [_delegate shouldDeleteAccount:_account];
    }
    
    [self dismiss];
}


#pragma mark - Helpers
-(void) flipSaveButton
{
    if( [m_OldFirstName isEqualToString:m_NewFirstName]
       && [m_OldLastName isEqualToString:m_NewLastName]
       && [m_OldTitle isEqualToString:m_NewTitle] )
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
