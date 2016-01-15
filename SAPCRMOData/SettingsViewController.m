//
//  SettingsViewController.m
//  SAPCRMOData
//
//  Created by Nyisztor Karoly on 2014.11.05..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import "SettingsViewController.h"
#import "SupportabilityUploader.h"
#import "SAPSupportabilityFacade.h"
#import "SAPE2ETraceManager.h"
#import "SAPClientLogManager.h"
#import "SAPStoreManager.h"
#import "Settings.h"
#import "Constants.h"

static NSLock* sUploadLogLock;
static NSLock* sUploadBTXLock;

@interface SettingsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *logLevelLabel;

- (IBAction)onVerboseLoggingSwitch:(UISwitch *)sender;
- (IBAction)onE2ETraceSwitch:(UISwitch *)sender;

- (IBAction)onShowLogsPressed:(id)sender;
- (IBAction)onUploadLogsPressed:(id)sender;
- (IBAction)onUploadBTXPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UISwitch *verboseLoggingSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *traceSwitch;

@property (weak, nonatomic) IBOutlet UIButton *uploadBTXButton;

@property (strong, nonatomic) id<SAPE2ETraceTransaction> e2ETransaction;

@property (strong, nonatomic) NSString* uplodURL;

@end

@implementation SettingsViewController

+(void) initialize
{
    sUploadLogLock = [NSLock new];
    sUploadBTXLock = [NSLock new];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    E_CLIENT_LOG_LEVEL logLevel = [Settings sharedInstance].currentLogLevel;
    
    _logLevelLabel.text = [self mapLogLevelToString:logLevel];
    _verboseLoggingSwitch.on = ([Settings sharedInstance].currentLogLevel == DebugClientLogLevel);
    
    self.e2ETransaction = [[[SAPSupportabilityFacade sharedManager] getE2ETraceManager] getActiveTransaction];
//    [Settings sharedInstance].traceOn = _e2ETransaction ? YES :NO;
    _traceSwitch.on = [Settings sharedInstance].traceOn;
    _uploadBTXButton.enabled = [Settings sharedInstance].traceOn;
    // try to retrieve endpoint URL and app ID from settings
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    self.uplodURL = [userDefaults stringForKey:@"endpoint_preference"];
    if( !_uplodURL )
    {
        LOGERR(@"Endpoint URL is missing. Manage in app Settings menu.", nil);
    }
}

/**
 *  Maps log levels to user-friendly strings
 *
 *  @param logLevel_in <#logLevel_in description#>
 *
 *  @return <#return value description#>
 */
-(NSString*) mapLogLevelToString:(E_CLIENT_LOG_LEVEL)logLevel_in
{
    NSDictionary* severities = @{ @(AllClientLogLevel): NSLocalizedString( @"ALL", nil ),
                                  @(DebugClientLogLevel): NSLocalizedString( @"DEBUG", nil ),
                                  @(InfoClientLogLevel):  NSLocalizedString( @"INFO", nil ),
                                  @(WarningClientLogLevel):  NSLocalizedString( @"WARNING", nil ),
                                  @(ErrorClientLogLevel):  NSLocalizedString( @"ERROR", nil ),
                                  @(FatalClientLogLevel):  NSLocalizedString( @"FATAL", nil ),
                                  @(NoneClientLogLevel): NSLocalizedString( @"NONE", nil ) };
    
    return severities[@(logLevel_in)];
}

#pragma mark - Actions

- (IBAction)onVerboseLoggingSwitch:(UISwitch *)sender
{
    [Settings sharedInstance].currentLogLevel = sender.isOn ? DebugClientLogLevel : ErrorClientLogLevel;
    _logLevelLabel.text = [self mapLogLevelToString:[Settings sharedInstance].currentLogLevel];
    
    [[[SAPSupportabilityFacade sharedManager] getClientLogManager] setLogLevel:[Settings sharedInstance].currentLogLevel];
}

- (IBAction)onE2ETraceSwitch:(UISwitch *)sender
{
    BOOL shouldStartE2E = sender.isOn;
    
    [Settings sharedInstance].traceOn = shouldStartE2E;
    
    NSError* error = nil;
    
    if( shouldStartE2E )
    {
        self.e2ETransaction = [[[SAPSupportabilityFacade sharedManager] getE2ETraceManager] startTransaction:kShowcaseAppE2ETransactionMain error:&error];
        if( error )
        {
            LOGERR(@"Could not start E2ETransaction. Details: %@", error.localizedDescription);
        }
        else
        {
            _uploadBTXButton.enabled = _e2ETransaction ? YES : NO;
        }
    }
    else
    {
        _uploadBTXButton.enabled = NO;
        
        if( !_e2ETransaction )
        {
            LOGWAR( @"No E2ETransaction has been started");
        }
        else
        {
            [[[SAPSupportabilityFacade sharedManager] getE2ETraceManager] endTransaction:_e2ETransaction error:&error];
            if( error )
            {
                LOGERR(@"Could not end E2ETransaction. Details: %@", error.localizedDescription);
            }
        }
    }
}

- (IBAction)onShowLogsPressed:(id)sender
{
    UIViewController* toViewCtrl = [self.storyboard instantiateViewControllerWithIdentifier:@"LogViewer"];
    [self presentViewController:toViewCtrl animated:YES completion:^{
        
    }];
}

- (IBAction)onUploadLogsPressed:(id)sender
{
    if( !_uplodURL )
    {
        LOGERR( @"Could not upload logs - missing endpoint URL. Should be set in Settings." );
        return;
    }
    
    [sUploadLogLock lock];
    
    NSURL* uploadURL = [NSURL URLWithString:_uplodURL];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%li/clientlogs", uploadURL.host, (long)uploadURL.port.integerValue]]];
        
    NSString* appCID = [Settings sharedInstance].appCID;
    [request setValue:appCID forHTTPHeaderField:@"X-SMP-APPCID"];
    
    SupportabilityUploader* uploader = [[SupportabilityUploader alloc] initWithHttpConversationManager:[SAPStoreManager sharedInstance].conversationManager urlRequest:request];
    
    [[[SAPSupportabilityFacade sharedManager] getClientLogManager] uploadClientLogs:uploader completion:^(NSError* error) {
        if ( !error )
        {
            LOGDEB( @"Log upload completed succesfully" );
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString( @"Log Upload", nil ) message:NSLocalizedString( @"Log upload completed succesfully", nil ) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [alertView show];
            });
        }
        else
        {
            LOGWAR( @"Log upload failed: %@", error.localizedDescription );
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString( @"Log Upload", nil ) message:[NSString stringWithFormat:@"Log upload failed: %@", error.localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];

            dispatch_async(dispatch_get_main_queue(), ^{
                [alertView show];
            });
        }
        
        [sUploadLogLock unlock];
    }];
}

- (IBAction)onUploadBTXPressed:(id)sender
{
    if( !_uplodURL )
    {
        LOGERR( @"Could not upload BTX - missing endpoint URL. Should be set in Settings." );
        return;
    }
    
    [sUploadBTXLock lock];
    
    NSURL* uploadURL = [NSURL URLWithString:_uplodURL];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%li/btx", uploadURL.host, (long)uploadURL.port.integerValue]]];
    
    NSString* appCID = [Settings sharedInstance].appCID;
    [request setValue:appCID forHTTPHeaderField:@"X-SMP-APPCID"];
    
    SupportabilityUploader* uploader = [[SupportabilityUploader alloc] initWithHttpConversationManager:[SAPStoreManager sharedInstance].conversationManager urlRequest:request];
    
    [[[SAPSupportabilityFacade sharedManager] getE2ETraceManager] uploadBTX:uploader completion:^(NSError* error) {
        if ( !error )
        {
            LOGDEB( @"BTX upload completed succesfully" );
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString( @"BTX Upload", nil ) message:NSLocalizedString( @"BTX upload completed succesfully", nil ) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [alertView show];
            });
        }
        else
        {
            LOGWAR( @"BTX upload failed: %@", error.localizedDescription );
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString( @"BTX Upload", nil ) message:[NSString stringWithFormat:@"BTX upload failed: %@", error.localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [alertView show];
            });
        }
        
        [sUploadBTXLock unlock];
    }];
}

@end
