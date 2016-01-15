//
//  MainViewController.m
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.09..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import "MainViewController.h"
#import "Constants.h"
#import "NSDate+Extension.h"
#import "SAPStoreManager.h"
#import "SOData.h"
//#import "SODataOnlineStore.h"
//#import "SODataOfflineStore.h"

#import "SODataMetaEntityTypeDefault.h"
#import "SODataPropertyDefault.h"

#import "BadgeCellTableViewCell.h"

#import "DataManager.h"
#import "ConverterFactory.h"

#import "EditAccountViewController.h"
#import "EditContactViewController.h"
#import "EditAppointmentViewController.h"
#import "EditOpportunityViewController.h"

#import "SODataRequestParamSingleDefault.h"
#import "SODataEntityDefault.h"
#import "SODataPropertyDefault.h"

#import "sap_xs_runtime.h"
#import "SODataGuid.h"


@interface MainViewController () <AccountUpdating, ContactUpdating, AppointmentUpdating, OpportunityUpdating, UISearchBarDelegate>
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *progressIndicator;

@property (strong, nonatomic) IBOutlet UIView *fullscreenDimView;

@property (strong, nonatomic) IBOutlet UITableView *masterTableView;

@property (strong, nonatomic) IBOutlet UITableView *itemsTableView;

@property (strong, nonatomic) NSMutableArray* collectionList; ///< list of collections displayed in Master

// SODataEntity
@property (strong, nonatomic) NSMutableDictionary* entityDictsByType; ///< list of {collectionType : {resourcePath : entity}} by collection type
@property (strong, nonatomic) NSDictionary* entityDictForSelected; ///< list of entities for selected collection

// entities mapped to native structs
@property (strong, nonatomic) NSMutableDictionary* itemsByType; ///< list of items by collection type
@property (strong, nonatomic) NSArray* itemsForSelected; ///< list of items for selected collection
@property (strong, nonatomic) NSArray* filteredItemsForSelected; ///< list of items filtered by search term

@property (strong, nonatomic) UIRefreshControl* refreshControl; ///< pull down to refresh on entity view

@property (strong, nonatomic) IBOutlet UIView *contactDetailsView;
@property (strong, nonatomic) IBOutlet UIView *appointmentDetailsView;
@property (strong, nonatomic) IBOutlet UIView *opportunityDetailsView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;

// Contact and Account Details Fields
@property (strong, nonatomic) IBOutlet UILabel *contactNameLabel; // e.g. "Jim Raynors"
@property (strong, nonatomic) IBOutlet UILabel *contactFunctionLabel; // e.g. "Sales Representative"
@property (strong, nonatomic) IBOutlet UILabel *contactCompanyLabel; // e.g. "Pepsi Cola"
@property (strong, nonatomic) IBOutlet UILabel *contactPhoneLabel; // "+40 924 86722"
@property (strong, nonatomic) IBOutlet UILabel *contactDueDateLabel; // e.g. "21 Oct, 2014"

// Appointment Details Fields
@property (strong, nonatomic) IBOutlet UILabel *appointmentResponsibleLabel; // e.g. "Jim Raynors"
@property (strong, nonatomic) IBOutlet UILabel *appointmentPriorityLabel; // e.g. "Medium"
@property (strong, nonatomic) IBOutlet UILabel *appointmentStatusLabel; // e.g. "In Progress"
@property (strong, nonatomic) IBOutlet UILabel *appointmentDueDateLabel; // e.g. "21 Oct, 2014"
@property (strong, nonatomic) IBOutlet UILabel *appointmentCommentLabel; // e.g. "Call Steve!"

// Opportunity Details Fields
@property (strong, nonatomic) IBOutlet UILabel *opportunityTitleLabel; // e.g. "Big Deal"
@property (strong, nonatomic) IBOutlet UILabel *opportunityExpectedRevenueLabel; // e.g. "$400,000"
@property (strong, nonatomic) IBOutlet UILabel *opportunityStatusLabel; // e.g. "In Progress"
@property (strong, nonatomic) IBOutlet UILabel *opportunityStartDateLabel; // e.g. "24 Sep, 2014"
@property (strong, nonatomic) IBOutlet UILabel *opportunityDueDateLabel; // e.g. "21 Oct, 2014"
@property (strong, nonatomic) IBOutlet UIImageView *opportunityCommentLabel; // e.g. "Call Steve!"

// Settings
@property (strong, nonatomic) IBOutlet UIView *settingsSlideInView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *setingsTrailingConstraint;

- (IBAction)onSettingsButtonPressed:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *moreButton;
@property (strong, nonatomic) IBOutlet UIButton *closeButton;
@property (strong, nonatomic) IBOutlet UIView *dimView; ///< dims main ui in and out when slide in view reveals or disappers

- (IBAction)onEditItemPressed:(id)sender;
- (IBAction)onCreateItemPressed:(id)sender;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *masterTableViewWidthConstraint;

@end

@implementation MainViewController
{
    Collection* m_SelectedMaster;
    BaseItem* m_SelectedItem;
    BOOL m_IsRightPaneShown;
    BOOL m_IsCollectionViewShown;
    NSString* m_SearchText;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    [self adjustForOrientation:orientation];
    
    _dimView.alpha = 0;
    _fullscreenDimView.alpha = 0;
    
    _contactDetailsView.hidden = NO;
    _appointmentDetailsView.hidden = YES;
    _opportunityDetailsView.hidden = YES;
    
    self.itemsByType = [NSMutableDictionary dictionary];
    self.entityDictsByType = [NSMutableDictionary dictionary];
    self.entityDictForSelected = [NSMutableDictionary dictionary];
    
    UITableViewController* tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = _itemsTableView;
    
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    tableViewController.refreshControl = self.refreshControl;
    
    [self loadCollections];
}

/**
 *  Adjust collection table view width based on inetrface orientation; makes it disappear when device is in portrait mode
 *
 *  @param orientation <#orientation description#>
 */
-(void) adjustForOrientation:(UIInterfaceOrientation)orientation
{
    // hides master table in portrait
    if( UIInterfaceOrientationIsPortrait( orientation ) )
    {
        _masterTableViewWidthConstraint.constant = 0;
    }
    else
    {
        _masterTableViewWidthConstraint.constant = kMasterTableWidthLandscape;
    }
    
    [_masterTableView setNeedsUpdateConstraints];
}

-(void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self adjustForOrientation:toInterfaceOrientation];
}

/**
 *  Gets the collection list and map to CoreData entities
 *  First collection is auto-selected entities are loaded
 */
-(void) loadCollections
{
    // 1. get collection list and map to CoreData entities
    // 2. auto-select first and load entities
    SAPStoreManager* facade = [SAPStoreManager sharedInstance];
    
    NSArray* entityNames = [facade.store.metadata metaEntityNames];
    
    self.collectionList = [NSMutableArray array];
    
    // Demo mode requires distinct collection names
    BOOL isDemoMode = ([SAPStoreManager sharedInstance].storeMode == DEMO_STORE);
    // iterate and create CoreData entities out of available collections
    for (NSString* entityName in entityNames)
    {
        Collection* collection = nil;
        
        // !!! metaEntity.name is not the same as entityName?
        SODataMetaEntityTypeDefault* metaEntity = [facade.store.metadata metaEntityForName:entityName];
        
        switch ([self objectTypeFromName:entityName])
        {
            case ACCOUNTS:
            {
                collection = [[DataManager sharedInstance] insertedNewCollectionInMOC];
                collection.type = @(ACCOUNTS);
                collection.displayName = NSLocalizedString(kAccountsCollection, nil);
                collection.descript_ion = NSLocalizedString(@"List of accounts", nil);
                collection.collectionName = isDemoMode ? kAccountsCollection : metaEntity.name;
                collection.thumbnail = UIImagePNGRepresentation([UIImage imageNamed:@"account"]);
            } break;
            case CONTACTS:
            {
                collection = [[DataManager sharedInstance] insertedNewCollectionInMOC];
                collection.type = @(CONTACTS);
                collection.displayName = NSLocalizedString(kContactsCollection, nil);
                collection.descript_ion = NSLocalizedString(@"List of contacts", nil);
                collection.collectionName = isDemoMode ? kContactsCollection : metaEntity.name;
                collection.thumbnail = UIImagePNGRepresentation([UIImage imageNamed:@"contact"]);                
            } break;
            case APPOINTMENTS:
            {
                collection = [[DataManager sharedInstance] insertedNewCollectionInMOC];
                collection.type = @(APPOINTMENTS);
                collection.displayName = NSLocalizedString(kAppointmentsCollection, nil);
                collection.descript_ion = NSLocalizedString(@"List of appointments", nil);
                collection.collectionName = isDemoMode ? kAppointmentsCollection : metaEntity.name;
                collection.thumbnail = UIImagePNGRepresentation([UIImage imageNamed:@"appointment"]);
            } break;
            case OPPORTUNITIES:
            {
                collection = [[DataManager sharedInstance] insertedNewCollectionInMOC];
                collection.type = @(OPPORTUNITIES);
                collection.displayName = NSLocalizedString(kOpportunitiesCollection, nil);
                collection.descript_ion = NSLocalizedString(@"List of opportunities", nil);
                collection.collectionName = isDemoMode ? kOpportunitiesCollection : metaEntity.name;
                collection.thumbnail = UIImagePNGRepresentation([UIImage imageNamed:@"opportunity"]);
            } break;
            default:
            {
                LOGWAR( @"Unknown collection type %@", entityName );
            }; break;
        }
        
        if( collection )
        {
            [self.collectionList addObject:collection];
        }
    }

    [[DataManager sharedInstance] saveContext];
    
    [_masterTableView reloadData];
    
    if( _collectionList.count )
    {
        // auto select first row in master table
        NSIndexPath* firstRow = [NSIndexPath indexPathForRow:0 inSection:0];

        // set first as selected
        [_masterTableView selectRowAtIndexPath:firstRow
                                      animated:YES
                                scrollPosition:UITableViewScrollPositionNone];
        [self tableView:_masterTableView didSelectRowAtIndexPath:firstRow];
    }
}

/**
 *  (Re)loads entities for current selection
 */
- (void)reloadData
{
    if( !m_SelectedMaster.collectionName )
    {
        LOGDEB(@"Error! Cannot fetch entities, no URL provided" );
        return;
    }
    
    LOGDEB(@" * * * Fetching entities for '%@'", m_SelectedMaster.displayName);

    // XXX: workaround for the offline store
    // Collection names in the metadata are in the form  CRM_BUPA_ODATA.<CollectionName>,
    // while offline store expects (?)                   CRM_BUPA_ODATA_Entities.<CollectionName>Collection
    NSString* collectionName = [m_SelectedMaster.collectionName stringByReplacingOccurrencesOfString:@"CRM_BUPA_ODATA." withString:@""]; //([SAPStoreManager sharedInstance].storeMode == OFFLINE_STORE) ? [m_SelectedMaster.collectionName stringByReplacingOccurrencesOfString:@"CRM_BUPA_ODATA" withString:@"CRM_BUPA_ODATA_Entities"] : m_SelectedMaster.collectionName;
    NSString* collectionURL = [NSString stringWithFormat:@"%@Collection", collectionName];
    
    [self dimScreen:YES];
    
    [[SAPStoreManager sharedInstance] READ:collectionURL completion:^(id<SODataRequestExecution> requestExecution, NSError *error) {
        
        [self dimScreen:NO];
        [_refreshControl endRefreshing];
        
        if( error )
        {
            LOGERR(@"Error getting collection: %@", [error localizedDescription]);
        }
        else
        {
            id<SODataResponse> response = requestExecution.response;
            if ([response conformsToProtocol:@protocol(SODataResponseSingle)])
            {
                if ([[(id<SODataResponseSingle>)response payload] conformsToProtocol:@protocol(SODataEntitySet) ])
                {
                    id<SODataEntitySet> entitySet = (id<SODataEntitySet>)[(id<SODataResponseSingle>)response payload];
                    // convert entities to CoreData instances
                    NSArray* entities = entitySet.entities;
                    
                    NSMutableDictionary* entitiesByResourcepath = [NSMutableDictionary dictionaryWithCapacity:entities.count];
                    
                    NSMutableArray* items = [NSMutableArray arrayWithCapacity:entities.count];
                    for( id<SODataEntity> entity in entities )
                    {
                        BaseItem* item = [self convertToCDEntity:entity ofType:m_SelectedMaster.type.integerValue];
                        [items addObject:item];
                        if( entity.resourcePath )
                        {
                            entitiesByResourcepath[entity.resourcePath] = entity;
                        }
                    }
                    
                    if( items )
                    {
                        self.entityDictsByType[m_SelectedMaster.type] = entitiesByResourcepath;
                        self.entityDictForSelected = entitiesByResourcepath;
                        
                        self.itemsByType[m_SelectedMaster.type] = items;
                        self.itemsForSelected = items;
                        
                        // apply filtering
                        [self filterItems];
                        
                        m_SelectedMaster.toItems = [NSSet setWithArray:items];
                        
                        // Persist to in-memory DB
                        [[DataManager sharedInstance] saveContext];
                        LOGDEB(@" * * * * * Entities loaded for '%@'", m_SelectedMaster.collectionName);
#ifdef DEBUG
                        [self logEntitySet:entitySet.entities];
#endif
                    }
                    else
                    {
                        LOGWAR(@"Error! Could not load entities for %@", m_SelectedMaster.collectionName);
                    }
                    
                    NSIndexPath* selectedMaster = [_masterTableView indexPathForSelectedRow];
                    
                    [_itemsTableView reloadData];
                    [_masterTableView reloadData];
                    // restore selection
                    [_masterTableView selectRowAtIndexPath:selectedMaster animated:YES scrollPosition:UITableViewScrollPositionNone];
                    
                    // auto-select first row in details
                    if( items.count )
                    {
                        NSIndexPath* firstRow = [NSIndexPath indexPathForRow:0 inSection:0];
                        
                        [_itemsTableView selectRowAtIndexPath:firstRow
                                                     animated:YES
                                               scrollPosition:UITableViewScrollPositionNone];
                        [self tableView:_itemsTableView didSelectRowAtIndexPath:firstRow];
                    }
                }
            }
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - TableView Datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 0;
    if( tableView == _masterTableView )
    {
        rows = [self.collectionList count];
    }
    else
    {
        rows = _filteredItemsForSelected.count;
    }
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BadgeCellTableViewCell* cell = nil;
    
    if( tableView == _masterTableView )
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"MasterCell" forIndexPath:indexPath];
        Collection* collection = [self.collectionList objectAtIndex:indexPath.row];
        
        cell.titleLabel.text = collection.displayName;
        cell.descriptionLabel.text = collection.descript_ion;
        cell.thumbnailImageView.image = [UIImage imageWithData:collection.thumbnail];
                
        NSArray* entities = self.itemsByType[collection.type];
        cell.badgeTextField.text = entities.count ? [NSString stringWithFormat:@"%lu", (unsigned long)entities.count] : @"...";
    }
    else if( tableView == _itemsTableView )
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"ItemCell" forIndexPath:indexPath];
        
        BaseItem* item = _filteredItemsForSelected[indexPath.row];
        
        cell.titleLabel.text = item.name;
        cell.descriptionLabel.text = item.descript_ion;
        
        cell.badgeTextField.text = NSLocalizedString( @"?", nil );
        
        cell.thumbnailImageView.image = [self itemBadgeForSelectedType];
    }    

    static UIView* customColorView = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        customColorView = [UIView new];
        customColorView.backgroundColor = [UIColor whiteColor];
    });

    cell.selectedBackgroundView =  customColorView;
    
    return cell;
}

#pragma mark - TableView Delegates
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( tableView == _masterTableView )
    {
        return 80;
    }
    return 66;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( tableView == _masterTableView )
    {
        m_SelectedMaster = _collectionList[indexPath.row];
        
        _titleLabel.text = m_SelectedMaster.displayName;
        
        NSArray* items = self.itemsByType[m_SelectedMaster.type];
        self.itemsForSelected = items;
        
        [self filterItems];
        
        // load data from local DB if no network is available
        /*
         NSError* error = nil;
         ...
         if( <check network availability> )
         {
         self.itemsList = m_SelectedMaster.toItems.allObjects.mutableCopy;
         }
         // fetch live data
         else
         {
*/
        // no items have been fetched for this collection yet
        if( items.count == 0 )
        {
            // clear old content while fetching new one
            [_itemsTableView reloadData];
            [self reloadData];
        }
        else
        {
            if( _filteredItemsForSelected.count )
            {
                LOGDEB(@" * * * Entities for '%@' already cached.", m_SelectedMaster.collectionName);
                [_itemsTableView reloadData];
                
                NSIndexPath* firstRow = [NSIndexPath indexPathForRow:0 inSection:0];
                [_itemsTableView selectRowAtIndexPath:firstRow
                                             animated:YES
                                       scrollPosition:UITableViewScrollPositionNone];
                [self tableView:_itemsTableView didSelectRowAtIndexPath:firstRow];
                
                BaseItem* item = _filteredItemsForSelected[0];
                [self showDetailsFor:m_SelectedMaster.type.integerValue withItem:item];
            }
            else
            {
                // display empty table
                [_itemsTableView reloadData];
                [self showDetailsFor:m_SelectedMaster.type.integerValue withItem:nil];
            }
        }
    }
    else if( tableView == _itemsTableView )
    {
        // filtered items may be empty!
        if( _filteredItemsForSelected.count > indexPath.row )
        {
            m_SelectedItem = _filteredItemsForSelected[indexPath.row];
            [self showDetailsFor:m_SelectedMaster.type.integerValue withItem:m_SelectedItem];
        }
        else
        {
            // display empty table
            [_itemsTableView reloadData];
            [self showDetailsFor:m_SelectedMaster.type.integerValue withItem:nil];
        }
    }
}

#pragma mark - Actions

- (IBAction)onEditItemPressed:(id)sender
{
    if( !m_SelectedItem )
    {
        NSLog( @"No selected item to be edited! %s", __PRETTY_FUNCTION__ );
        return;
    }
    
    E_OBJECT_TYPE type = m_SelectedMaster.type.integerValue;
    
    switch( type )
    {
        case CONTACTS:
        {
            EditContactViewController* editContactViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EditContact"];
            editContactViewController.delegate = self;
            editContactViewController.contact = (Contact*)m_SelectedItem;
            [self presentViewController:editContactViewController animated:YES completion:nil];
        } break;
        case ACCOUNTS:
        {
            EditAccountViewController* editAccountViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EditAccount"];
            editAccountViewController.delegate = self;
            editAccountViewController.account = (Account*)m_SelectedItem;
            [self presentViewController:editAccountViewController animated:YES completion:nil];
        } break;
        case APPOINTMENTS:
        {
            EditAppointmentViewController* editAppointmentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EditAppointment"];
            editAppointmentViewController.delegate = self;
            editAppointmentViewController.appointment = (Appointment*)m_SelectedItem;
            [self presentViewController:editAppointmentViewController animated:YES completion:nil];
        } break;
        case OPPORTUNITIES:
        {
            EditOpportunityViewController* editOpportunityViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EditOpportunity"];
            editOpportunityViewController.delegate = self;
            editOpportunityViewController.opportunity = (Opportunity*)m_SelectedItem;
            [self presentViewController:editOpportunityViewController animated:YES completion:nil];
        } break;
        default:
        {
            NSLog( @"Should not reach here in %s", __PRETTY_FUNCTION__ );
        }
    }
}

- (IBAction)onCreateItemPressed:(id)sender
{
    E_OBJECT_TYPE type = m_SelectedMaster.type.integerValue;
    
    switch( type )
    {
        case CONTACTS:
        {
            EditContactViewController* editContactViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EditContact"];
            editContactViewController.delegate = self;
            [self presentViewController:editContactViewController animated:YES completion:nil];
        } break;
        case ACCOUNTS:
        {
            EditAccountViewController* editAccountViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EditAccount"];
            editAccountViewController.delegate = self;
            [self presentViewController:editAccountViewController animated:YES completion:nil];
        } break;
        case APPOINTMENTS:
        {
            EditAppointmentViewController* editAppointmentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EditAppointment"];
            editAppointmentViewController.delegate = self;
            [self presentViewController:editAppointmentViewController animated:YES completion:nil];
        } break;
        case OPPORTUNITIES:
        {
            EditOpportunityViewController* editOpportunityViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EditOpportunity"];
            editOpportunityViewController.delegate = self;
            [self presentViewController:editOpportunityViewController animated:YES completion:nil];
        } break;
            
        default:
        {
            NSLog( @"Should not reach here in %s", __PRETTY_FUNCTION__ );
        }
    }
}

- (IBAction)onSettingsButtonPressed:(id)sender
{
    [self flipSlideInMenu];
}


#pragma mark - Create Calls
-(void) createContact:(Contact*)contact_in
{
    SODataEntityDefault* anEntity = [[SODataEntityDefault alloc] initWithType:@"CRM_BUPA_ODATA.Contact"];

    NSError* error = nil;
    [[SAPStoreManager sharedInstance].store allocatePropertiesOfEntity:anEntity mode:SODataRequestModeCreate error:&error];
    NSAssert(error == nil, @"Error should be nil");

    const NSUInteger idNum = (arc4random() / 10000000) + 3000;
    NSString* idStr = [NSString stringWithFormat:@"%lu", (unsigned long)idNum];

    NSDictionary* propKeyValues = @{@"contactID" : idStr,
                                    @"accountID" : @"3270", // XXX: should use a real ID
                                    @"lastName" : contact_in.lastName ? contact_in.lastName : @"",
                                    @"firstName" : contact_in.firstName ? contact_in.firstName : @"",
                                    //@"birthDate": @"1986-5-19T00:00:00",
                                    @"fullName" : contact_in.name ? contact_in.name : @"",
                                    @"title" : contact_in.function ? contact_in.function : @"",
                                    @"company" : contact_in.company ? contact_in.company : @""
                                    };
    
    for (NSString* propertyKey in propKeyValues.allKeys)
    {
        id value = [propKeyValues objectForKey:propertyKey];
        SODataPropertyDefault* property = [[SODataPropertyDefault alloc] initWithName:propertyKey];
        [property setValue:value];
        [anEntity.properties setObject:property forKey:property.name];
    }
    
    [[SAPStoreManager sharedInstance] CREATE:anEntity inCollection:[NSString stringWithFormat:@"%@Collection", m_SelectedMaster.collectionName] completion:^(id<SODataRequestExecution> requestExecution, NSError *error) {
        if( error )
        {
            NSLog(@"CREATE failed. Details: %@", error.localizedDescription);
        }
        else
        {
            NSLog(@"CREATE succesful");
            // update views
            dispatch_async( dispatch_get_main_queue(),  ^(void) {
                [self reloadData];
            });
        }
    }];
}

-(void) createAccount:(Account*)account_in
{
    SODataEntityDefault* anEntity = [[SODataEntityDefault alloc] initWithType:@"CRM_BUPA_ODATA.Account"];
    
    NSError* error = nil;
    [[SAPStoreManager sharedInstance].store allocatePropertiesOfEntity:anEntity mode:SODataRequestModeCreate error:&error];
    NSAssert(error == nil, @"Error should be nil");
    
    // create new random id each time
    const NSUInteger idNum = (arc4random() / 10000000) + 3000;
    // XXX: tweak to silence "Number not in interval A - ZZZZZZZZZZ" server message
    NSString* idStr = [NSString stringWithFormat:@"A%lu", (unsigned long)idNum];
    NSDictionary* propKeyValues = @{@"accountID" : idStr,
                                    @"category" : @"2",
                                    @"fullName" : account_in.fullName ? account_in.fullName : @"",
                                    @"name1" : account_in.name1 ? account_in.name1 : @"",
                                    @"name2" : account_in.name2 ? account_in.name2 : @"",
                                    @"title" : account_in.title ? account_in.title : @"",
                                    };
    
    for (NSString* propertyKey in propKeyValues.allKeys)
    {
        id value = [propKeyValues objectForKey:propertyKey];
        SODataPropertyDefault* property = [[SODataPropertyDefault alloc] initWithName:propertyKey];
        [property setValue:value];
        [anEntity.properties setObject:property forKey:property.name];
    }
    
    [[SAPStoreManager sharedInstance] CREATE:anEntity inCollection:[NSString stringWithFormat:@"%@Collection", m_SelectedMaster.collectionName] completion:^(id<SODataRequestExecution> requestExecution, NSError *error) {
        if( error )
        {
            NSLog(@"CREATE failed. Details: %@", error.localizedDescription);
        }
        else
        {
            NSLog(@"CREATE succesful");
            // update views
            dispatch_async( dispatch_get_main_queue(),  ^(void) {
                [self reloadData];
            });
        }
    }];
}

-(void) createAppointment:(Appointment*)appointment_in
{
    SODataEntityDefault* anEntity = [[SODataEntityDefault alloc] initWithType:@"CRM_BUPA_ODATA.Appointment"];
    
    NSError* error = nil;
    [[SAPStoreManager sharedInstance].store allocatePropertiesOfEntity:anEntity mode:SODataRequestModeCreate error:&error];
    NSAssert(error == nil, @"Error should be nil");
    /*
    // create new random id each time
    const NSUInteger idNum = (arc4random() / 10000000) + 3000;
    // XXX: tweak to silence "Number not in interval A - ZZZZZZZZZZ" server message
    NSString* idStr = [NSString stringWithFormat:@"A%lu", (unsigned long)idNum];
    */
    XS_GuidValue* guid = [XS_GuidValue random];
    SODataGuid* odataGuid = [[SODataGuid alloc]initWithString36:[guid toString36]];
    
    // create new random id each time
    //    const NSUInteger idNum = (arc4random() / 10000000) + 3000;
    // XXX: tweak to silence "Number not in interval A - ZZZZZZZZZZ" server message
    //    NSString* idStr = [NSString stringWithFormat:@"%lu", (unsigned long)idNum];
    
    NSDictionary* propKeyValues = @{//@"Description" : appointment_in.description,
                                    //@"ContactAccount" : @"master",
                                    @"Guid" : odataGuid,
                                    @"category" : @"2",
                                    //@"FromDate" : @"2015-5-19T00:00:00",
                                    @"Responsible"   : appointment_in.responsible ? appointment_in.responsible : @"",
                                    @"PriorityTxt" : appointment_in.priority ? appointment_in.priority : @"",
                                    @"Status"  : appointment_in.status ?  appointment_in.status : @"",//@"E0002",
                                    @"Note" : appointment_in.note ? appointment_in.note : @""
                                    };

    
    for (NSString* propertyKey in propKeyValues.allKeys)
    {
        id value = [propKeyValues objectForKey:propertyKey];
        SODataPropertyDefault* property = [[SODataPropertyDefault alloc] initWithName:propertyKey];
        [property setValue:value];
        [anEntity.properties setObject:property forKey:property.name];
    }
    
    [[SAPStoreManager sharedInstance] CREATE:anEntity inCollection:[NSString stringWithFormat:@"%@Collection", m_SelectedMaster.collectionName] completion:^(id<SODataRequestExecution> requestExecution, NSError *error) {
        if( error )
        {
            NSLog(@"CREATE failed. Details: %@", error.localizedDescription);
        }
        else
        {
            NSLog(@"CREATE succesful");
            // update views
            dispatch_async( dispatch_get_main_queue(),  ^(void) {
                [self reloadData];
            });
        }
    }];
}


-(void) createOpportunity:(Opportunity*)opportunity_in
{
    SODataEntityDefault* anEntity = [[SODataEntityDefault alloc] initWithType:@"CRM_BUPA_ODATA.Opportunity"];
    
    NSError* error = nil;
    [[SAPStoreManager sharedInstance].store allocatePropertiesOfEntity:anEntity mode:SODataRequestModeCreate error:&error];
    NSAssert(error == nil, @"Error should be nil");

    // create new random id each time    
    const NSUInteger idNum = (arc4random() / 10000000) + 3000;
    
    XS_GuidValue* guid = [XS_GuidValue random];
    SODataGuid* odataGuid = [[SODataGuid alloc]initWithString36:[guid toString36]];
    
    // XXX: tweak to silence "Number not in interval A - ZZZZZZZZZZ" server message
    NSString* idStr = [NSString stringWithFormat:@"%lu", (unsigned long)idNum];
    
    NSDictionary* propKeyValues = @{/*@"ProcessType" : idStr,*/
                                    /*@"category" : @"2",*/
                                    /*@"BusinessPartner" : @"2",*/
                                    @"Guid" : odataGuid,
                                    @"description" : @"n.a.",
                                    @"objectId" : idStr,
                                    //@"expRevenue" : @(100.000),
                                    //@"StartDate" : @"2015-5-19T00:00:00",
                                    //@"ClosingDate" : @"2015-5-19T00:00:00",
                                    //@"ExpectedSalesVolume" : @"0",
                                    //@"SalesStageCode" : @"1",
                                    @"status" : @"E0001",
                                    @"currPhaseText" : @"Information Exchange",
                                    @"statusText" : @"Open",
                                    //                                    @"ProspectName"   : @"Mark Zbikowski",
                                    //                                    @"ProspectNumber" : @"44483",
                                    //                                    @"MainContactId"  : @"P092345",
                                    //                                    @"MainContactName" : @"Mark Knopfler",
                                    //@"probability" : @"10"
                                    };
    
    for (NSString* propertyKey in propKeyValues.allKeys)
    {
        id value = [propKeyValues objectForKey:propertyKey];
        SODataPropertyDefault* property = [[SODataPropertyDefault alloc] initWithName:propertyKey];
        [property setValue:value];
        [anEntity.properties setObject:property forKey:property.name];
    }
    
    [[SAPStoreManager sharedInstance] CREATE:anEntity inCollection:[NSString stringWithFormat:@"%@Collection", m_SelectedMaster.collectionName] completion:^(id<SODataRequestExecution> requestExecution, NSError *error) {
        if( error )
        {
            NSLog(@"CREATE failed. Details: %@", error.localizedDescription);
        }
        else
        {
            NSLog(@"CREATE succesful");
            // update views
            dispatch_async( dispatch_get_main_queue(),  ^(void) {
                [self reloadData];
            });
        }
    }];
}

#pragma mark - Update Calls
-(void) updateContact:(Contact*)contact_in
{
    SODataEntityDefault* entity = _entityDictForSelected[contact_in.resourcePath];
    if( !entity )
    {
        LOGWAR(@"No entity found for resourcePath: %@", contact_in.resourcePath);
    }

    NSDictionary* propKeyValues = @{@"lastName" : contact_in.lastName ? contact_in.lastName : @"",
                                    @"firstName" : contact_in.firstName ? contact_in.firstName : @"",
                                    @"fullName" : contact_in.name ? contact_in.name : @"",
                                    @"title" : contact_in.function ? contact_in.function : @"",
                                    @"company" : contact_in.company ? contact_in.company : @""
                                    };
    
    for (NSString* propertyKey in propKeyValues.allKeys)
    {
        id value = [propKeyValues objectForKey:propertyKey];
        SODataPropertyDefault* property = [[SODataPropertyDefault alloc] initWithName:propertyKey];
        [property setValue:value];
        [entity.properties setObject:property forKey:property.name];
    }
    
    [[SAPStoreManager sharedInstance] UPDATE:entity inCollection:[NSString stringWithFormat:@"%@Collection", m_SelectedMaster.collectionName] completion:^(id<SODataRequestExecution> requestExecution, NSError *error) {
        if( error )
        {
            NSLog(@"UPDATE failed. Details: %@", error.localizedDescription);
        }
        else
        {
            NSLog(@"UPDATE succesful");
            // update views
            dispatch_async( dispatch_get_main_queue(),  ^(void) {
                [self reloadData];
            });
        }
    }];
}

-(void) updateAccount:(Account*)account_in
{
    SODataEntityDefault* entity = _entityDictForSelected[account_in.resourcePath];
    if( !entity )
    {
        LOGWAR(@"No entity found for resourcePath: %@", account_in.resourcePath);
    }
    
    NSDictionary* propKeyValues = @{/*@"accountID" : account_in.id ? account_in.id : @0,*/
                                    /*@"category" : account_in.category ? account_in.category : @2,*/
                                    @"fullName" : account_in.fullName ? account_in.fullName : @"",
                                    @"name1" : account_in.name1 ? account_in.name1 : @"",
                                    @"name2" : account_in.name2 ? account_in.name2 : @"",
                                    @"title" : account_in.title ? account_in.title : @"",
                                    };
    
    for (NSString* propertyKey in propKeyValues.allKeys)
    {
        id value = [propKeyValues objectForKey:propertyKey];
        SODataPropertyDefault* property = [[SODataPropertyDefault alloc] initWithName:propertyKey];
        [property setValue:value];
        [entity.properties setObject:property forKey:property.name];
    }
    
    [[SAPStoreManager sharedInstance] UPDATE:entity inCollection:[NSString stringWithFormat:@"%@Collection", m_SelectedMaster.collectionName] completion:^(id<SODataRequestExecution> requestExecution, NSError *error) {
        if( error )
        {
            NSLog(@"UPDATE failed. Details: %@", error.localizedDescription);
        }
        else
        {
            NSLog(@"UPDATE succesful");
            // update views
            dispatch_async( dispatch_get_main_queue(),  ^(void) {
                [self reloadData];
            });
        }
    }];
}

-(void) updateAppointment:(Appointment*)appointment_in
{
    SODataEntityDefault* entity = _entityDictForSelected[appointment_in.resourcePath];
    if( !entity )
    {
        LOGWAR(@"No entity found for resourcePath: %@", appointment_in.resourcePath);
    }
    
    NSDictionary* propKeyValues = @{/*@"accountID" : account_in.id ? account_in.id : @0,*/
                                    /*@"category" : account_in.category ? account_in.category : @2,*/
                                    @"Responsible" : appointment_in.responsible ? appointment_in.responsible : @"",
                                    @"PriorityTxt" : appointment_in.priority ? appointment_in.priority : @"",
                                    @"Status" : appointment_in.status ? appointment_in.status : @"",
                                    @"Note" : appointment_in.note ? appointment_in.note : @"",
                                    };
    
    for (NSString* propertyKey in propKeyValues.allKeys)
    {
        id value = [propKeyValues objectForKey:propertyKey];
        SODataPropertyDefault* property = [[SODataPropertyDefault alloc] initWithName:propertyKey];
        [property setValue:value];
        [entity.properties setObject:property forKey:property.name];
    }
    
    [[SAPStoreManager sharedInstance] UPDATE:entity inCollection:[NSString stringWithFormat:@"%@Collection", m_SelectedMaster.collectionName] completion:^(id<SODataRequestExecution> requestExecution, NSError *error) {
        if( error )
        {
            NSLog(@"UPDATE failed. Details: %@", error.localizedDescription);
        }
        else
        {
            NSLog(@"UPDATE succesful");
            // update views
            dispatch_async( dispatch_get_main_queue(),  ^(void) {
                [self reloadData];
            });
        }
    }];
}

-(void) updateOpportunity:(Opportunity*)opportunity_in
{
    SODataEntityDefault* entity = _entityDictForSelected[opportunity_in.resourcePath];
    if( !entity )
    {
        LOGWAR(@"No entity found for resourcePath: %@", opportunity_in.resourcePath);
    }
    
    NSDictionary* propKeyValues = @{/*@"accountID" : account_in.id ? account_in.id : @0,*/
                                    /*@"category" : account_in.category ? account_in.category : @2,*/
                                    @"status" : opportunity_in.status ? opportunity_in.status : @"",
                                    
                                    @"expRevenue" : opportunity_in.expRevenue.stringValue ? opportunity_in.expRevenue.stringValue : @"",
                                    @"status" : opportunity_in.status ? opportunity_in.status : @"",
                                    @"StartDate" : opportunity_in.startDate ? [NSDate localizeDate:opportunity_in.startDate] : @"2015-5-19T00:00:00"
                                    };
    
    for (NSString* propertyKey in propKeyValues.allKeys)
    {
        id value = [propKeyValues objectForKey:propertyKey];
        SODataPropertyDefault* property = [[SODataPropertyDefault alloc] initWithName:propertyKey];
        [property setValue:value];
        [entity.properties setObject:property forKey:property.name];
    }
    
    [[SAPStoreManager sharedInstance] UPDATE:entity inCollection:[NSString stringWithFormat:@"%@Collection", m_SelectedMaster.collectionName] completion:^(id<SODataRequestExecution> requestExecution, NSError *error) {
        if( error )
        {
            NSLog(@"UPDATE failed. Details: %@", error.localizedDescription);
        }
        else
        {
            NSLog(@"UPDATE succesful");
            // update views
            dispatch_async( dispatch_get_main_queue(),  ^(void) {
                [self reloadData];
            });
        }
    }];
}

#pragma mark - Delete Calls
-(void) deleteItem:(BaseItem*)item_in
{
    SODataEntityDefault* entity = _entityDictForSelected[item_in.resourcePath];
    if( !entity )
    {
        LOGWAR(@"No entity found for resourcePath: %@", item_in.resourcePath);
        return;
    }

    [[SAPStoreManager sharedInstance] DELETE:entity completion:^(id<SODataRequestExecution> requestExecution, NSError *error) {
        if( error )
        {
            NSLog(@"DELETE failed. Details: %@", error.localizedDescription);
        }
        else
        {
            NSLog(@"DELETE succesful");
            // update views
            dispatch_async( dispatch_get_main_queue(),  ^(void) {
                [self reloadData];
            });
        }
    }];
}

#pragma mark - ContactUpdating delegate

-(void) shouldUpdateContact:(Contact*)contact_in;
{
    if( ![self checkDemoMode] )
    {
        [self updateContact:contact_in];
    }
}

-(void) shouldCreateContact:(Contact*)contact_in;
{
    if( ![self checkDemoMode] )
    {
        [self createContact:contact_in];
    }
}

-(void) shouldDeleteContact:(Contact*)contact_in;
{
    if( ![self checkDemoMode] )
    {
        [self deleteItem:contact_in];
    }
}

#pragma mark - AccountUpdating delegate

-(void) shouldUpdateAccount:(Account *)account_in
{
    if( ![self checkDemoMode] )
    {
        [self updateAccount:account_in];
    }
}

-(void) shouldCreateAccount:(Account *)account_in
{
    if( ![self checkDemoMode] )
    {
        [self createAccount:account_in];
    }
}

-(void) shouldDeleteAccount:(Account *)account_in
{
    if( ![self checkDemoMode] )
    {
        [self deleteItem:account_in];
    }
}

#pragma mark - AppointmentUpdating delegate
-(void) shouldUpdateAppointment:(Appointment*)appointment_in;
{
    if( ![self checkDemoMode] )
    {
        [self updateAppointment:appointment_in];
    }
}

-(void) shouldCreateAppointment:(Appointment*)appointment_in;
{
    if( ![self checkDemoMode] )
    {
        [self createAppointment:appointment_in];
    }
}

-(void) shouldDeleteAppointment:(Appointment*)appointment_in;
{
    if( ![self checkDemoMode] )
    {
        [self deleteItem:appointment_in];
    }
}

#pragma mark - OpportunityUpdating delegate
-(void) shouldUpdateOpportunity:(Opportunity *)opportunity_in
{
    if( ![self checkDemoMode] )
    {
        [self updateOpportunity:opportunity_in];
    }
}

-(void) shouldCreateOpportunity:(Opportunity *)opportunity_in
{
    if( ![self checkDemoMode] )
    {
        [self createOpportunity:opportunity_in];
    }
}

-(void) shouldDeleteOpportunity:(Appointment*)opportunity_in;
{
    if( ![self checkDemoMode] )
    {
        [self deleteItem:opportunity_in];
    }
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText;   // called when text changes (including clear)
{
#ifdef DEBUG
    NSLog( @"Looking for %@", searchText );
#endif
    
    m_SearchText = searchText;
    [self filterItems];
    
    [_itemsTableView reloadData];
}

-(void) filterItems
{
    // sorting is applied right after fetching
    if( m_SearchText && m_SearchText.length )
    {
        NSPredicate* searchPredicate = [NSPredicate predicateWithFormat:@"SELF.name contains[c] %@", m_SearchText];
        NSArray* filteredArray = [_itemsForSelected filteredArrayUsingPredicate:searchPredicate];
        self.filteredItemsForSelected = filteredArray;
    }
    else
    {
        self.filteredItemsForSelected = _itemsForSelected;
    }
}

#pragma mark - Helpers
/**
 *  Displays detail UI for specific type
 *
 *  @param type <#type description#>
 */
-(void) showDetailsFor:(E_OBJECT_TYPE)type withItem:(BaseItem*)item
{
    switch( type )
    {
        case CONTACTS:
        {
            _contactDetailsView.hidden = NO;
            _appointmentDetailsView.hidden = YES;
            _opportunityDetailsView.hidden = YES;
            
            // labels
            //            if( ![SAPOnlineStoreFacade sharedInstance].demoMode )
            {
                Contact* contact = (Contact*)item;
                _contactNameLabel.text = contact.name;
                _contactFunctionLabel.text = contact.function;
                _contactCompanyLabel.text = contact.company;
            }
        } break;
        case ACCOUNTS:
        {
            _contactDetailsView.hidden = NO;
            _appointmentDetailsView.hidden = YES;
            _opportunityDetailsView.hidden = YES;
            
            // labels
            //            if( ![SAPOnlineStoreFacade sharedInstance].demoMode )
            {
                Account* account = (Account*)item;
                _contactNameLabel.text = account.name;
                _contactFunctionLabel.text = account.title;
                _contactCompanyLabel.text = account.category;
            }
        } break;
        case APPOINTMENTS:
        {
            _contactDetailsView.hidden = YES;
            _appointmentDetailsView.hidden = NO;
            _opportunityDetailsView.hidden = YES;
            
            // labels
            if( !([SAPStoreManager sharedInstance].storeMode == DEMO_STORE) )
            {
                Appointment* appItem = (Appointment*)item;
                _appointmentResponsibleLabel.text = appItem.responsible;
                _appointmentPriorityLabel.text = appItem.priority;
                _appointmentStatusLabel.text = appItem.status;
                _appointmentDueDateLabel.text = [NSDate localizeDate:appItem.endDate];
                _appointmentCommentLabel.text = appItem.note;
            }
        } break;
        case OPPORTUNITIES:
        {
            _contactDetailsView.hidden = YES;
            _appointmentDetailsView.hidden = YES;
            _opportunityDetailsView.hidden = NO;
            
            //            if( ![SAPOnlineStoreFacade sharedInstance].demoMode )
            {
                Opportunity* oppItem = (Opportunity*)item;
                _opportunityTitleLabel.text = oppItem.name;
                _opportunityExpectedRevenueLabel.text = oppItem.expRevenue.stringValue;
                _opportunityStatusLabel.text = oppItem.status;
                _opportunityStartDateLabel.text = [NSDate localizeDate:oppItem.startDate];
                _opportunityDueDateLabel.text = [NSDate localizeDate:oppItem.closeDate];
            }
            //            _opportunityCommentLabel.text = oppItem.comment;
        } break;
            
            // show contact details by default
        default:
        {
            _contactDetailsView.hidden = NO;
            _appointmentDetailsView.hidden = YES;
            _opportunityDetailsView.hidden = YES;
        } break;
            
    }
}

-(UIImage*) itemBadgeForSelectedType
{
    UIImage* result = nil;
    
    switch( m_SelectedMaster.type.intValue )
    {
        case ACCOUNTS:
        {
            result = [UIImage imageNamed:@"account_thumb"];
        } break;
        case CONTACTS:
        {
            result = [UIImage imageNamed:@"contact_thumb"];
        } break;
        case APPOINTMENTS:
        {
            result = [UIImage imageNamed:@"appointment_thumb"];
        } break;
        case OPPORTUNITIES:
        {
            result = [UIImage imageNamed:@"opportunity_thumb"];
        } break;
        default:
        {
            LOGDEB( @"Unknown type" );
        }
    }
    
    return result;
}

/**
 *  Dims / undims the whole screen and reveals/hides progress indicator
 *
 *  @param shouldDim <#shouldDim description#>
 */
-(void) dimScreen:(BOOL)shouldDim
{
    if(shouldDim)
    {
        [_progressIndicator startAnimating];
        // auto-hide Settings menu if it is displayed
        if(m_IsRightPaneShown)
        {
            [self flipSlideInMenu];
        }
    }
    
    CGFloat dimViewToAlpha = shouldDim ? 0.3f : 0.f;
    
    [UIView animateWithDuration:0.3f animations:^{
        _fullscreenDimView.alpha = dimViewToAlpha;
    }];
    
    if(!shouldDim)
    {
        [_progressIndicator stopAnimating];
    }
}
/**
 *  Reveals or hides the slide-in menu
 */
-(void) flipSlideInMenu
{
    // animate slide-in Settings view
    m_IsRightPaneShown = !m_IsRightPaneShown;
    
    CGFloat offset = m_IsRightPaneShown ? _settingsSlideInView.bounds.size.width : -_settingsSlideInView.bounds.size.width;
    
    CGFloat dimViewToAlpha = m_IsRightPaneShown ? 0.3f : 0.f;
    
    CGPoint toCenter = CGPointMake( _settingsSlideInView.center.x + offset, _settingsSlideInView.center.y);
    //    CGRect toFrame = CGRectMake(_settingsSlideInView.frame.origin.x + offset, _settingsSlideInView.frame.origin.y, _settingsSlideInView.frame.size.width, _settingsSlideInView.frame.size.height);
    
    [UIView animateWithDuration:0.3f animations:^{
        _settingsSlideInView.center = toCenter;
        _dimView.alpha = dimViewToAlpha;
        //        _settingsSlideInView.frame = toFrame;
    } completion:^(BOOL finished) {
        //        [_settingsSlideInView setNeedsLayout];
        //        if( !m_IsRightPaneShown )
        //        {
        ////            [self.view sendSubviewToBack:_dimView];
        ////            [_dimView removeFromSuperview];
        //        }
        [self animateButtons:m_IsRightPaneShown];
        _setingsTrailingConstraint.constant = m_IsRightPaneShown ? -_settingsSlideInView.bounds.size.width : 0;
    }];
}

/**
 *  Animates buttons on slide-in panel
 *
 *  @param activate <#activate description#>
 */
-(void) animateButtons:(BOOL)isMenuShown
{
    UIButton* buttonToShow = isMenuShown ? _closeButton : _moreButton;
    UIButton* buttonToHide = isMenuShown ? _moreButton : _closeButton;
    
    buttonToShow.transform = CGAffineTransformMakeScale(0.1, 0.1);
    buttonToShow.hidden = NO;
    buttonToShow.layer.opacity = 0.f;
    // hide Setting button and reveal Close button
    [UIView animateWithDuration:0.3f animations:^{
        buttonToHide.transform = CGAffineTransformMakeScale(0.1, 0.1);
        buttonToHide.layer.opacity = 0.f;
    } completion:^(BOOL finished) {
        buttonToHide.hidden = YES;
        
        [UIView animateWithDuration:0.3f animations:^{
            buttonToShow.transform = CGAffineTransformIdentity;
            buttonToShow.layer.opacity = 1.f;
        }];
    }];
}

/**
 *  Converts raw oData entities to CoreData entities
 *
 *  @param entity_in <#entity_in description#>
 *
 *  @return BaseItem (cast to access child attributes)
 */
-(BaseItem*) convertToCDEntity:(id<SODataEntity>)entity_in ofType:(E_OBJECT_TYPE)type_in
{
    BaseItem* retVal = nil;
    
    id<CoreDataConverting> converter = [ConverterFactory makeConverter:m_SelectedMaster.type.integerValue withEntity:entity_in];
    
    switch( type_in )
    {
        case ACCOUNTS:
        {
            Account* account = [[DataManager sharedInstance] insertedNewAccountInMOC];
            account.title = converter.function;
            account.category = converter.company;
            //            account.phoneNumber = converter.phone;
            //            account.dueDate = converter.dueDate;
            retVal = account;
        } break;
        case CONTACTS:
        {
            Contact* contact = [[DataManager sharedInstance] insertedNewContactInMOC];
            contact.function = converter.function;
            contact.company = converter.company;
            retVal = contact;
        } break;
        case APPOINTMENTS:
        {
            Appointment* appointment = [[DataManager sharedInstance] insertedNewAppointmentInMOC];
            // fill
            appointment.status = converter.status;
            appointment.endDate = [NSDate dateFromString:converter.dueDate];
            appointment.responsible = converter.responsible;
            appointment.note = converter.comment;
            appointment.priority = converter.priority;
            appointment.startDate = [NSDate dateFromString:converter.startDate];
            retVal = appointment;
        } break;
        case OPPORTUNITIES:
        {
            Opportunity* opportunity = [[DataManager sharedInstance] insertedNewOpportunityInMOC];
            opportunity.expRevenue = converter.expectedRevenue;
            opportunity.status = converter.status;
            opportunity.startDate = [NSDate dateFromString:converter.startDate];
            opportunity.closeDate = [NSDate dateFromString:converter.dueDate];
            //            opportunity.propability = converter.probability;
            opportunity.currPhaseText = converter.status;
            retVal = opportunity;
        } break;
        default:
        {
            LOGDEB( @"Unknown type" );
        }
    }
    
    if( retVal )
    {
        retVal.name =  converter.name;
        retVal.descript_ion = converter.short_description;
        retVal.resourcePath = converter.resourcePath;
        retVal.editResourcePath = converter.editResourcePath;
        retVal.typeName = converter.typeName;
    }
    
    return retVal;
}

/**
 *  Extracts the object type based on collection name
 *
 *  @param name <#name description#>
 *
 *  @return <#return value description#>
 */
- (E_OBJECT_TYPE)objectTypeFromName:(NSString*)name
{
    NSUInteger objectType = UNKNOWN;
    /*
     CustomizingRegion
     CustomizingMarketingAttrSet
     Task
     Subscription
     MarketingAttribute
     Relationship
     AccountFactsheet
     CustomizingTaskType
     CustomizingTaskStatus
     Customer
     CustomizingMarketingAttrValue
     Classification
     Note
     Notification
     CustomizingTitle
     CustomizingRating
     CustomizingAcademicTitle
     Attachment
     Address
     CustomizingTaskPriority
     */
    if ([name hasSuffix:@"Contact"])
    {
        objectType = CONTACTS;
    }
    else if ([name hasSuffix:@"Deal"])
    {
        objectType = DEALS;
    }
    else if ([name hasSuffix:@"Account"])
    {
        objectType = ACCOUNTS;
    }
    else if ([name hasSuffix:@"Customer"])
    {
        objectType = CUSTOMERS;
    }
    else if ([name hasSuffix:@"Opportunity"] || [name hasSuffix:@"Opportunities"] )
    {
        objectType = OPPORTUNITIES;
    }
    else if ([name hasSuffix:@"Appointment"])
    {
        objectType = APPOINTMENTS;
    }
    
    return objectType;
}

/**
 *  Prints out entity fields
 *
 *  @param entities <#entities description#>
 */
- (void)logEntitySet:(NSArray*)entities
{
    if( !entities.count )
    {
        return;
    }
    
    id<SODataEntity> entity = entities[0];
    
    NSLog( @"%@ {", entity.typeName );
    for ( NSString* key in entity.properties )
    {
        SODataPropertyDefault *property = [entity.properties objectForKey:key];
        NSLog(@"%@: %@", property.name, [property.value class]);
    }
    
    NSLog(@"}");
}

/**
 *  Checks whether store is in Demo mode and brings up an alert view if yes
 */
-(BOOL) checkDemoMode
{
    BOOL isDemoMode = NO;
    if( [SAPStoreManager sharedInstance].storeMode ==  DEMO_STORE )
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Demo Mode Warning", nil) message:NSLocalizedString(@"Operation not possible in Demo mode", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil, nil];
        [alert show];
        isDemoMode = YES;
    }
    
    return isDemoMode;
}

@end
