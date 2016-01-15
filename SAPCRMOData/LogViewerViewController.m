//
//  LogViewerViewController.m
//  SAPCRMOData
//
//  Created by Nyisztor Karoly on 2014.11.07..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import "LogViewerViewController.h"
#import "SAPClientLogManagerDefault.h"
#import "SAPClientLogEntry.h"
#import "Settings.h"
#import "NSDate+Extension.h"

#import "LogEntryTableViewCell.h"
/*
 @property (nonatomic, strong) 	NSDate* dateTime;
 @property (nonatomic, strong) 	NSTimeZone* timeZone;
 @property (assign) 				E_CLIENT_LOG_LEVEL severity;
 @property (nonatomic, strong) 	NSString* sourceName;
 @property (nonatomic, strong) 	NSString* msgCode;
 @property (nonatomic, strong) 	NSString* dcComponent;
 @property (nonatomic, strong) 	NSString* guid;
 @property (nonatomic, strong) 	NSString* correlationId;
 @property (nonatomic, strong) 	NSString* application;
 @property (nonatomic, strong) 	NSString* location;
 @property (nonatomic, strong) 	NSString* user;
 @property (nonatomic, strong) 	NSString* rootContextId;
 @property (nonatomic, strong) 	NSString* transactionId;
 @property (nonatomic, strong) 	NSString* message;
 */

@interface LogViewerViewController ()
- (IBAction)onBackPressed:(id)sender;
- (IBAction)onSeveritySelected:(UISegmentedControl *)sender;
@property (weak, nonatomic) IBOutlet UISegmentedControl *logFilterSegmentedControl;

@property (weak, nonatomic) IBOutlet UITableView *logTableView;
@property (strong, nonatomic) NSMutableArray* logEntries;
@end

@implementation LogViewerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


-(void) loadLogs:(E_CLIENT_LOG_LEVEL)logLevel_in
{
    // retrieve log entries
    // XXX: using in-memory output stream for simplicity; however, this may cause out of memory issues when large amounts of logs are returned
    NSOutputStream* logStream = nil; // passing a nil output stream reference tels the log manager to feed the log entries to memory
    NSError* error = nil;
    
    self.logEntries = nil;
    
    [[SAPClientLogManager sharedManager] getLogEntries:logLevel_in outputStream:&logStream error:&error];
    if( error )
    {
        LOGERR( @"Error while retrieving log entries: %@", error.localizedDescription);
    }
    else if ( logStream )
    {
        NSData* logData = [logStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
        if(logData.length == 0)
        {
            NSLog(@"No log entries returned.");
        }
        else
        {
            NSString* logs = [NSString stringWithUTF8String:[logData bytes]];
            
            NSArray* logArray = [logs componentsSeparatedByString:@"\n"];
            
            if( logArray.count == 0 )
            {
                LOGDEB(@"No log entries could be retrieved");
            }
            else
            {
                self.logEntries = [NSMutableArray arrayWithCapacity:logArray.count];

                LOGDEB(@"Retrieved %lu log entries", (unsigned long)logArray.count);
                for( NSString* entry in logArray )
                {
                    SAPClientLogEntry* logEntry = [SAPClientLogEntry new];
                    NSArray* entryData = [entry componentsSeparatedByString:@"#"];
                    if( entryData.count > 15 ) // XXX: should be a valid log entry
                    {
                        logEntry.location = entryData[1];// XXX date mapped to location --- [NSDate dateFromString:entryData[1]];
                        logEntry.user = entryData[3]; // XXX: severity arribves as string already
                        logEntry.message = entryData[14];
#ifdef DEBUG
                        NSLog(@"\t\t\tLog entry level:%@ message: %@", logEntry.user, logEntry.message);
#endif
                        [_logEntries addObject:logEntry];
                    }
                }
            }
        }
    }
    
    [_logTableView reloadData];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadLogs:ErrorClientLogLevel];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _logEntries.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LogEntryTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"LogEntryCell" forIndexPath:indexPath];
    
    SAPClientLogEntry* logEntry = _logEntries[indexPath.row];
    
    cell.entryDateLabel.text = logEntry.location;// XXX: mapped to location --- [NSDate localizeDate:logEntry.dateTime];
    cell.severityLabel.text = logEntry.user;// XXX mapped to user as it comes as string
    cell.logMessageLabel.text = logEntry.message;
    cell.severityBadgeView.backgroundColor = [self badgeColorForCellForSeverity:logEntry.user];
    
    return cell;
}


-(UIColor*) badgeColorForCellForSeverity:(NSString*)severity_in
{
    NSDictionary* severityMap = @{ @"FATAL" : @(FatalClientLogLevel),
                                   @"ERROR" : @(ErrorClientLogLevel),
                                   @"WARNING" : @(WarningClientLogLevel),
                                   @"INFO" : @(InfoClientLogLevel),
                                   @"DEBUG" : @(DebugClientLogLevel) };
    
    E_CLIENT_LOG_LEVEL logLevel = ((NSNumber*)severityMap[severity_in]).integerValue;
    
    UIColor* badgeColor = nil;
    switch (logLevel)
    {
        case FatalClientLogLevel:
        {
            badgeColor = [UIColor purpleColor];
        } break;
        case ErrorClientLogLevel:
        {
            badgeColor = [UIColor redColor];
        } break;
        case WarningClientLogLevel:
        {
            badgeColor = [UIColor orangeColor];
        } break;
        case InfoClientLogLevel:
        {
            badgeColor = [UIColor yellowColor];
        } break;
        case DebugClientLogLevel:
        {
            badgeColor = [UIColor grayColor];
        } break;
        default:
        {
            badgeColor = [UIColor redColor];
        } break;
    }
    
    return badgeColor;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (IBAction)onBackPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onSeveritySelected:(UISegmentedControl *)sender
{
    if( sender.selectedSegmentIndex == 0 )
    {
        // show all logs
        [self loadLogs:DebugClientLogLevel];
    }
    else if( sender.selectedSegmentIndex == 1 )
    {
        // shiw only errors and worse - default
        [self loadLogs:ErrorClientLogLevel];
    }
}

@end
