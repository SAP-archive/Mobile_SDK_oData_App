//
//  LoginViewController.m
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.07..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#define SHOULD_USE_LOGONUI 0   ///< 0 = use logon core for user registration

#import "LoginViewController.h"
#import "SAPStoreManager.h"
#import "HttpConversationManager.h"

#import "SMPClientConnection.h"
#import "Settings.h"

#if SHOULD_USE_LOGONUI
#import "MAFLogonNGDelegate.h"
#import "MAFLogonUICustomizationDelegate.h"
#import "MAFLogonUINGPublicHeaders.h"
#endif


#import "MAFLogonManagerNGPublicHeaders.h"

#import "SODataOfflineStoreOptions.h"
#import "MAFLogonSMPConstants.h"

static BOOL SHOULDREGISTERUSER = YES; // NO for direct GW, YES for SMP servers

#if SHOULD_USE_LOGONUI
@interface LoginViewController () <MAFLogonCoreDelegate, MAFLogonNGDelegate, MAFLogonUICustomizationDelegate>
#else
@interface LoginViewController () <MAFLogonCoreDelegate>
#endif

@property (strong, nonatomic) NSString* endpoint;
@property (strong, nonatomic) NSString* appID;
@property (strong, nonatomic) NSString* userName;
@property (strong, nonatomic) NSString* password;

@property (strong, nonatomic) MAFLogonCore* logonCore;
@property (strong, nonatomic) MAFLogonContext* logonContext;
@property (nonatomic, strong) HttpConversationManager* conversationManager;

@property (strong, nonatomic) IBOutlet UITextField *usernameTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;
@property (strong, nonatomic) IBOutlet UIButton *loginButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *progressIndicator;
@property (strong, nonatomic) IBOutlet UILabel *errorLabel;
@property (weak, nonatomic) IBOutlet UISwitch *offlineModeSwitch;

#if SHOULD_USE_LOGONUI
@property (nonatomic, strong) MAFLogonUIViewManager* logonUIViewManager;
#endif

// Actions
- (IBAction)onUsernameChanged:(UITextField *)sender;
- (IBAction)onPasswordChanged:(UITextField *)sender;
- (IBAction)onOfflineModeChanged:(UISwitch *)sender;
- (IBAction)executeLogin:(id)sender;
- (IBAction)enterDemoMode:(id)sender;

@end

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storeStateChanged:) name:kStoreStateNotificationName object:nil];
}

/**
 * Notification is fired whenever store state changes (open or open failed)
 */
-(void) storeStateChanged:(NSNotification*)notification
{
    _errorLabel.hidden = NO;
    _errorLabel.textColor = [UIColor grayColor];
    _errorLabel.text = notification.userInfo[kStoreStateKey];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    _offlineModeSwitch.on = [Settings sharedInstance].isOfflineStoreOn;
    // try to initialize username and password from Settings if any
    [self initCredentials];
    
    // MAFLogonUIViewManager
#if SHOULD_USE_LOGONUI
    [self initLogonUIViewManager];
#endif
}

-(void) viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -  Actions

- (IBAction)onUsernameChanged:(UITextField *)sender
{
    self.userName = sender.text;
}

- (IBAction)onPasswordChanged:(UITextField *)sender
{
    self.password = sender.text;
}

- (IBAction)onOfflineModeChanged:(UISwitch *)sender
{
    [Settings sharedInstance].offlineStoreOn = sender.isOn;
}

- (IBAction)executeLogin:(id)sender
{
    [self dismissKeyboard];
    
    // try to retrieve endpoint URL and app ID from settings
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    self.endpoint = [userDefaults stringForKey:@"endpoint_preference"];
    if( !_endpoint )
    {
         [self reportLoginError:NSLocalizedString(@"Endpoint URL is missing. Manage app in the Settings menu.", nil)];
        return;
    }
    
    self.appID = [userDefaults stringForKey:@"appid_preference"];
    if( !_appID )
    {
        [self reportLoginError:NSLocalizedString(@"App ID is missing. Manage app in the Settings menu.", nil)];
        return;
    }
    
    if( !_password.length || !_userName.length )
    {
        NSLog( @"Cannot log in - credentials not provided!" );
        [self reportLoginError:NSLocalizedString( @"Cannot log in - credentials not provided!", nil )];
        return;
    }
    
    // instantiate the conversation manager
    self.conversationManager = [HttpConversationManager new];
    self.logonCore = [[MAFLogonCore alloc] initWithApplicationId:_appID];
    _logonCore.logonCoreDelegate = self;

    
    // hide login button, show progress indicator
    _loginButton.hidden = YES;
    //    _progressIndicator.hidden  = NO;
    [_progressIndicator startAnimating];
    _errorLabel.hidden = YES;
    
    NSURLCredential* credential = [NSURLCredential credentialWithUser:_userName password:_password persistence:NSURLCredentialPersistenceForSession];
    
    [self login:_appID url:[NSURL URLWithString:_endpoint] credentials:credential];
}

/**
 *  Initializes the store (online, offline, demo mode)
 */
-(void) initStore
{
    NSURLCredential* credential = [NSURLCredential credentialWithUser:_userName password:_password persistence:NSURLCredentialPersistenceForSession];
    
    SAPStoreManager* storeManager = [SAPStoreManager sharedInstance];
    // Configure store facade
    storeManager.conversationManager = _conversationManager;
    
    storeManager.endpoint = [NSURL URLWithString:_endpoint];
    
    //    NSURLCredential* credential = [NSURLCredential credentialWithUser:m_UserName password:m_Password persistence:NSURLCredentialPersistenceForSession];
    
    storeManager.credentials = credential;
    
    storeManager.storeMode = [Settings sharedInstance].offlineStoreOn ? OFFLINE_STORE : ONLINE_STORE;
    // set offline store options before performing any operations with the store
    if( [Settings sharedInstance].offlineStoreOn == OFFLINE_STORE )
    {
        storeManager.offlineOptions = [self makeOfflineOptions:storeManager.endpoint];
    }
    
    // hide login button, show progress indicator
    _loginButton.hidden = YES;
    //    _progressIndicator.hidden  = NO;
    [_progressIndicator startAnimating];
    _errorLabel.hidden = YES;
    
    [storeManager openStore:^(id<SODataStoreAsync> store, NSError *error) {
        [_progressIndicator stopAnimating];
        
        NSString* storeType = (storeManager.storeMode == ONLINE_STORE) ? @"Online" : @"Offline";
        if( error )
        {
            LOGERR(@"Error opening %@ store: %@", storeType, [error localizedDescription]);
            
            _loginButton.hidden = NO;
            _errorLabel.hidden = NO;
            _errorLabel.textColor = [UIColor redColor];
            _errorLabel.text = @"Logon failed!";
            _progressIndicator.hidden = YES;
        }
        else
        {
#ifdef DEBUG
            NSString* msg = [NSString stringWithFormat:@"Logon succesful. %@ store succesfully opened.", storeType];
            LOGINF( @"%@", msg );
#endif
            [self retrieveAppCID];
            
            [self showMainUI];
        }
    }];
}

/**
 *  Retrieves the appCID and persists it
 *
 *  @return YES on success
 */
-(BOOL) retrieveAppCID
{
    BOOL retVal = YES;
    
    NSError* error = nil;
    self.logonContext = [_logonCore getContext:&error];
    
    if( error )
    {
        LOGERR(@"Could not retrieve logon context from secure store - %@", error.description);
        retVal = NO;
    }
    else
    {
        MAFLogonRegistrationContext* regContext = _logonContext.registrationContext;
        NSMutableDictionary* dict = regContext.connectionData[keyMAFLogonConnectionDataApplicationSettings];
        NSString* appCID = dict[keyApplicationSettings_ApplicationConnectionId];
        if( !appCID.length )
        {
            LOGWAR( @"Could not retrieve application connection ID. Details: %@", error.localizedDescription );
            retVal = NO;
        }
        else
        {
            [Settings sharedInstance].appCID = appCID;
        }
    }
    
    return retVal;
}

- (IBAction)enterDemoMode:(id)sender
{
    [SAPStoreManager sharedInstance].storeMode = DEMO_STORE;
    [self showMainUI];
}


-(void) showMainUI
{
    UIViewController* toViewCtrl = [self.storyboard instantiateViewControllerWithIdentifier:@"MainUI"];
    [self.navigationController pushViewController:toViewCtrl animated:YES];
}

#pragma mark - Logon
/**
 *  Unlocks the secure store if needed, and sets the logon context
 *
 *  @param passcode_in passcode to unlock the secure store; pass nil to use default passcode
 *
 *  @return YES on success
 */
-(BOOL) unlockSecureStoreIfNeeded:(NSString*)passcode_in
{
    BOOL retVal = YES;
    
    NSError* error = nil;
    // unlock secure store if needed
    if( !_logonCore.state.isSecureStoreOpen )
    {
        [_logonCore unlockSecureStore:passcode_in error:&error];
        if( error )
        {
            LOGERR(@"Could not unlock secure store - %@", error.description);
            retVal = NO;
        }
    }
    
    self.logonContext = [_logonCore getContext:&error];
    
    if( error )
    {
        LOGERR(@"Could not retrieve logon context from secure store - %@", error.description);
        retVal = NO;
    }

    return retVal;
}

/**
 *  Performs logon withour bringing up the LogonManagerNG UI
 *
 *  @param appID_in      <#appID_in description#>
 *  @param url_in        <#url_in description#>
 *  @param credential_in <#credential_in description#>
 */
-(void) login:(NSString*)appID_in url:(NSURL*)url_in credentials:(NSURLCredential*)credential_in
{
    if( !SHOULDREGISTERUSER || _logonCore.state.isRegistered  )
    {
        if( [self unlockSecureStoreIfNeeded:nil] )
        {
            [_progressIndicator stopAnimating];
            [self initStore];
        }
        return;
    }
    
    _logonCore.logonCoreDelegate = self;
    
    self.logonContext = [MAFLogonContext new];
    
    MAFLogonRegistrationContext* regContext = [MAFLogonRegistrationContext new];
    regContext.applicationId = appID_in;
    regContext.serverHost = url_in.host;
    //    regContext.domain = url_in.host;
    regContext.isHttps = [url_in.scheme compare:@"https" options:NSCaseInsensitiveSearch] == NSOrderedSame ? YES : NO;
    regContext.serverPort = url_in.port.intValue;
    //    regContext.resourcePath = url_in.path ? url_in.path : @"";
    
    regContext.backendUserName = credential_in.user;
    regContext.backendPassword = credential_in.password;
    
    _logonContext.registrationContext = regContext;
    
    [_logonCore registerWithContext:_logonContext];
}

/**
 *  Initializes the objects required for logon and brings up the logon UI
 *  @remark MAFLogonUIViewManager usecase
 */
#if SHOULD_USE_LOGONUI
-(void) initLogonUIViewManager
{
    self.logonUIViewManager = [MAFLogonUIViewManager new];
    
    // set customization delegate optionally to special runtime customization
    [self.logonUIViewManager setLogonUICustomizationDelegate:self];
    
    // set up the logon delegate
    [self.logonUIViewManager.logonManager setLogonDelegate:self];
    
    // should be called from every ViewController!
    [self.logonUIViewManager setParentViewController:self];
    
    //set the applicationID
    [self.logonUIViewManager.logonManager setApplicationId:_appID];
    
    [self.logonUIViewManager.logonManager logon];
}
#endif

#pragma mark - MAFLogonCoreDelegate
-(void) registerFinished:(NSError *)anError
{
    if( anError )
    {
        LOGERR( @"Registration failure. Details:%@", anError.localizedDescription );
        
        [_progressIndicator stopAnimating];
        
        _loginButton.hidden = NO;
        _errorLabel.hidden = NO;
        _errorLabel.textColor = [UIColor redColor];
        _errorLabel.text = NSLocalizedString( @"Logon failed!", nil );
        _progressIndicator.hidden = YES;
    }
    else
    {
        LOGDEB( @"Logon succesful." );
        // persist registration
        NSError* error = nil;
        [_logonCore persistRegistration:nil logonContext:_logonContext error:&error];
        if( error )
        {
            LOGWAR( @"Could not persist registration. Details: %@", error.localizedDescription );
        }
        
        [self initStore];
    }
}

-(void) unregisterFinished:(NSError *)anError
{
    if( anError )
    {
        NSLog(@"Unregister failed with error %@", anError.description);
    }
    else
    {
        NSLog(@"Unregister finished");
    }
}

-(void) cancelRegistrationFinished:(NSError*)anError;
{
    // nop
}

-(void) refreshApplicationSettingsFinished:(NSError*)anError;
{
    // nop
}

-(void) changePasswordFinished:(NSError*)anError;
{
    // nop
}

-(void) uploadTraceFinished:(NSError*)anError;
{
    // nop
}

#pragma mark - MAFLogonNGDelegate implementation
/**
 Called when the logon finished either with success or error.
 */
#if SHOULD_USE_LOGONUI
-(void) logonFinishedWithError:(NSError*)error_in
{
    //[self showAlertView:@"Logon" withError:anError];
    //self.appidButton.enabled = ! self.logonUIViewManager.logonManager.logonState.isUserRegistered;
    if ( !error_in )
    {
        [[self.logonUIViewManager.logonManager logonConfigurator] configureManager:self.conversationManager];
        MAFLogonRegistrationData* regData = [self.logonUIViewManager.logonManager registrationDataWithError:nil];

        [Settings sharedInstance].appCID = [regData applicationConnectionId];

        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Logon Successful" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
    }
    else
    {
        LOGWAR(@"Errors during logon. Details: %@", error_in.localizedDescription);
    }
}

-(IBAction) deregister:(id)sender
{
    [self.logonUIViewManager.logonManager deleteUser];
}
#endif

/**
 Called when the deleteUser method call finished either with success or error.
 */
-(void) deleteUserFinishedWithError:(NSError*)anError {
    NSLog(@"Delete user %@", anError == nil ? @"successful" : @"failed");
}

#pragma mark - Utility Methods
/**
 *  Sets the credentials from the Settings bundle
 *  @remark: Should be entered from the app's Settings menu
 */
-(void) initCredentials
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    // check whether username and password have been set in the app's settings
    self.userName = [userDefaults stringForKey:@"username_preference"];
    self.password = [userDefaults stringForKey:@"password_preference"];
}

/**
 *  Displays logon related issues
 */
-(void) reportLoginError:(NSString*)errorMessage_in
{
    // re-enable login button
    _loginButton.hidden = NO;
    // unhide label showing error message
    _errorLabel.hidden = NO;
    _errorLabel.textColor = [UIColor redColor];

    _errorLabel.text = errorMessage_in;
}

/**
 *  Creates the offline options instance used to initialize the offline store
 *
 *  @return <#return value description#>
 */
- (SODataOfflineStoreOptions*) makeOfflineOptions:(NSURL*)url
{
    SODataOfflineStoreOptions* options = [SODataOfflineStoreOptions new];
    options.conversationManager = _conversationManager;
    
    options.enableHttps = [url.scheme compare:@"https" options:NSCaseInsensitiveSearch] == NSOrderedSame ? true : false;
    options.host = url.host;
    options.port = url.port.integerValue;
    options.serviceRoot = url.path ? url.path : @"";
    
    options.enableRepeatableRequests = YES;
    
    options.definingRequests[@"xreq1"] = @"AppointmentCollection";
    options.definingRequests[@"xreq2"] = @"ContactCollection?$expand=Photo,WorkAddress";
    options.definingRequests[@"xreq3"] = @"AccountCollection?$expand=MainAddress";
    options.definingRequests[@"xreq4"] = @"OpportunityCollection";
    
    return options;
}

-(void) dismissKeyboard
{
    if( _usernameTextField.isFirstResponder )
    {
        [_usernameTextField resignFirstResponder];
    }
    else if( _passwordTextField.isFirstResponder )
    {
        [_passwordTextField resignFirstResponder];
    }
}

@end
