//
//  SAPCRMCUD_Tests.m
//  SAPCRMOData
//
//  Created by Nyisztor, Karoly on 2015. 07. 14..
//  Copyright (c) 2015. SAP-SE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "SAPStoreManager.h"

#import "SMPClientConnection.h"
#import "SMPUserManager.h"
#import "Settings.h"
#import "MAFLogonNGDelegate.h"
//#import "MAFLogonUICustomizationDelegate.h"
#import "MAFLogonManagerNGPublicHeaders.h"
//#import "MAFLogonUINGPublicHeaders.h"

#import "SODataOfflineStoreOptions.h"
#import "MAFLogonSMPConstants.h"
#import "HttpConversationManager.h"

#import "SODataEntityDefault.h"
#import "SODataPropertyDefault.h"
#import "SODataStore.h"
#import "SODataStoreAsync.h"
#import "SODataRequestDelegate.h"
#import "SODataRequestParamSingleDefault.h"
#import "SODataRequestExecution.h"

#import "sap_xs_runtime.h"
#import "SODataGuid.h"


#warning enter logon details below
static NSString* APP_ID = @"APP_ID";
static NSString* CRM_ENDPOINT = @"ENDPOINT";

static NSString* CRM_USER = @"USER_NAME";
static NSString* CRM_PASSWORD = @"PASSWORD";

@interface SAPCRMCUD_Tests : XCTestCase <MAFLogonCoreDelegate, SODataRequestDelegate>

@end

@implementation SAPCRMCUD_Tests
{
    HttpConversationManager* m_ConversationManager;
    MAFLogonCore* m_LogonCore;
    MAFLogonContext* m_LogonContext;
    NSString* m_UserName;
    NSString* m_Password;
    id<SODataStoreAsync> m_OnlineStore;

    XCTestExpectation* m_LoginExpectation;
    XCTestExpectation* m_Expectation;
}

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    m_Password = [m_Password isEqualToString:CRM_PASSWORD] ? m_Password : CRM_PASSWORD;
    m_UserName = [m_UserName isEqualToString:CRM_USER] ? m_UserName : CRM_USER;
    
    m_ConversationManager = [HttpConversationManager new];
    m_LogonCore = [[MAFLogonCore alloc] initWithApplicationId:APP_ID];
    m_LogonCore.logonCoreDelegate = self;
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/**
 * Tests create operation
 * Performs user registration and open store
 */
-(void) testCreate
{
    NSURLCredential* credential = [NSURLCredential credentialWithUser:m_UserName password:m_Password persistence:NSURLCredentialPersistenceForSession];
    m_LoginExpectation = [self expectationWithDescription:@"Login and store open works as expected"];
    
    [self login:APP_ID url:[NSURL URLWithString:CRM_ENDPOINT] credentials:credential];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error, "Error while executing login / open online store. Details %@", error.localizedDescription);
    }];
    
    // Create account
    
    /*m_Expectation = [self expectationWithDescription:@"Create Account works as expected"];
    [self createAccount];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error, "Error while creating Account. Details %@", error.localizedDescription);
    }];*/
    
    
    // Create contact
    m_Expectation = [self expectationWithDescription:@"Create contact works as expected"];
    [self createContact];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error, "Error while creating Account. Details %@", error.localizedDescription);
    }];

    // Create appointment
    // fails with "Specify at least one number for the business partner."
    /*m_Expectation = [self expectationWithDescription:@"Create Appointment works as expected"];
    [self createAppointment];

    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error, "Error while creating Appointment. Details %@", error.localizedDescription);
    }];

    // Create opportunity
    m_Expectation = [self expectationWithDescription:@"Create Opportunity works as expected"];
    [self createOpportunity];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error, "Error while creating Opportunity. Details %@", error.localizedDescription);
    }];
     */
}

/**
 * Tests create operation
 * Performs user registration and open store
 */
-(void) testUpdate
{
    NSURLCredential* credential = [NSURLCredential credentialWithUser:m_UserName password:m_Password persistence:NSURLCredentialPersistenceForSession];
    m_LoginExpectation = [self expectationWithDescription:@"Login and store open works as expected"];
    
    [self login:APP_ID url:[NSURL URLWithString:CRM_ENDPOINT] credentials:credential];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error, "Error while executing login / open online store. Details %@", error.localizedDescription);
    }];
    
    // Update account
    m_Expectation = [self expectationWithDescription:@"Update Account works as expected"];
    [self updateAccount];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error, "Error while updating Account. Details %@", error.localizedDescription);
    }];
    /*
    // Update contact
    m_Expectation = [self expectationWithDescription:@"Update contact works as expected"];
    [self updateContact];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error, "Error while updating Account. Details %@", error.localizedDescription);
    }];
    
    // Update appointment
    m_Expectation = [self expectationWithDescription:@"Update Appointment works as expected"];
    [self updateAppointment];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error, "Error while updating Appointment. Details %@", error.localizedDescription);
    }];
    
    // Update opportunity
    m_Expectation = [self expectationWithDescription:@"Update Opportunity works as expected"];
    [self updateOpportunity];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error, "Error while updating Opportunity. Details %@", error.localizedDescription);
    }];
     */
}

-(void) updateAccount
{
    /*
     CRM_BUPA_ODATA.Account
     {
     name2: __NSCFConstantString
     category: __NSCFString
     birthDate: (null)
     eTag: __NSCFString
     isMyAccount: __NSCFBoolean
     title: __NSCFConstantString
     name1: __NSCFConstantString
     academicTitle: __NSCFConstantString
     fullName: __NSCFConstantString
     academicTitleID: __NSCFConstantString
     accountID: __NSCFString
     titleID: __NSCFConstantString
     }
     */
    
    SODataRequestParamSingleDefault *requestParam = [[SODataRequestParamSingleDefault alloc] initWithMode:SODataRequestModeUpdate resourcePath:@"AccountCollection('422429')"]; // XXX: use entity.editResourcePath in real-life scenarios
    
    SODataEntityDefault* anEntity = [[SODataEntityDefault alloc] initWithType:@"CRM_BUPA_ODATA.Account"];

    // XXX: tweak to silence "Number not in interval A - ZZZZZZZZZZ" server message
    // NSString* idStr = [NSString stringWithFormat:@"A%lu", (unsigned long)idNum];
    NSDictionary* propKeyValues = @{/*@"accountID" : idStr,
                                    @"category" : @"2",*/
                                    @"fullName" : @"Jeffrey Lebowski updated",
                                    @"name1" : @"Jeff",
                                    @"name2" : @"Lebowski updated"
                                    //@"title" : @"Test Account",
                                    //@"birthDate": @"1986-5-19T00:00:00",
                                    //@"academicTitle": @"Magister"
                                    };
    
    
    for (NSString* propertyKey in propKeyValues.allKeys)
    {
        id value = [propKeyValues objectForKey:propertyKey];
        SODataPropertyDefault* property = [[SODataPropertyDefault alloc] initWithName:propertyKey];
        [property setValue:value];
        [anEntity.properties setObject:property forKey:property.name];
    }
    
    NSError* error = nil;
    [m_OnlineStore allocatePropertiesOfEntity:anEntity mode:SODataRequestModeUpdate error:&error];
    XCTAssertNil(error, @"Error should be nil. Update failed.");
    
    requestParam.payload = anEntity;
    
    // fire the request
    [m_OnlineStore scheduleRequest:requestParam delegate:self];
}

-(void) createAccount
{
    /*
     CRM_BUPA_ODATA.Account
     {
     name2: __NSCFConstantString
     category: __NSCFString
     birthDate: (null)
     eTag: __NSCFString
     isMyAccount: __NSCFBoolean
     title: __NSCFConstantString
     name1: __NSCFConstantString
     academicTitle: __NSCFConstantString
     fullName: __NSCFConstantString
     academicTitleID: __NSCFConstantString
     accountID: __NSCFString
     titleID: __NSCFConstantString
     }
     */

    SODataRequestParamSingleDefault *requestParam = [[SODataRequestParamSingleDefault alloc] initWithMode:SODataRequestModeCreate resourcePath:@"AccountCollection"];
    
    SODataEntityDefault* anEntity = [[SODataEntityDefault alloc] initWithType:@"CRM_BUPA_ODATA.Account"];
    // create new random id each time
    const NSUInteger idNum = (arc4random() / 10000000) + 3000;
    // XXX: tweak to silence "Number not in interval A - ZZZZZZZZZZ" server message
    NSString* idStr = [NSString stringWithFormat:@"A%lu", (unsigned long)idNum];
    NSDictionary* propKeyValues = @{@"accountID" : idStr,
                                    @"category" : @"2",
                                    @"fullName" : @"Jeffrey Lebowski",
                                    @"name1" : @"Jeffrey",
                                    @"name2" : @"Lebowski",
                                    @"title" : @"Test Account",
                                    //@"birthDate": @"1986-5-19T00:00:00",
                                    @"academicTitle": @"Magister"
                                    };
    
    
    for (NSString* propertyKey in propKeyValues.allKeys)
    {
        id value = [propKeyValues objectForKey:propertyKey];
        SODataPropertyDefault* property = [[SODataPropertyDefault alloc] initWithName:propertyKey];
        [property setValue:value];
        [anEntity.properties setObject:property forKey:property.name];
    }
    
    NSError* error = nil;
    [m_OnlineStore allocatePropertiesOfEntity:anEntity mode:SODataRequestModeCreate error:&error];
    XCTAssertNil(error, @"Error should be nil. Create failed.");
    
    requestParam.payload = anEntity;
    
    // fire the request
    [m_OnlineStore scheduleRequest:requestParam delegate:self];
}

-(void) createContact
{
    /*
     CRM_BUPA_ODATA.Contact
     {
     lastName: __NSCFConstantString
     firstName: __NSCFConstantString
     birthDate: (null)
     function: __NSCFConstantString
     company: __NSCFConstantString
     eTag: __NSCFString
     isMyContact: __NSCFBoolean
     title: __NSCFConstantString
     academicTitle: __NSCFConstantString
     fullName: __NSCFConstantString
     academicTitleID: __NSCFConstantString
     isMainContact: __NSCFBoolean
     accountID: __NSCFString
     department: __NSCFConstantString
     contactID: __NSCFString
     titleID: __NSCFConstantString
     }
     */
    SODataRequestParamSingleDefault *requestParam = [[SODataRequestParamSingleDefault alloc] initWithMode:SODataRequestModeCreate resourcePath:@"ContactCollection"];
    
    SODataEntityDefault* anEntity = [[SODataEntityDefault alloc] initWithType:@"CRM_BUPA_ODATA.Contact"];

    NSError* error = nil;
    [m_OnlineStore allocatePropertiesOfEntity:anEntity mode:SODataRequestModeCreate error:&error];
    XCTAssertNil(error, @"Error should be nil. Create failed.");
    const NSUInteger idNum = (arc4random() / 10000000) + 3000;
    NSString* idStr = [NSString stringWithFormat:@"%lu", (unsigned long)idNum];
    NSDictionary* propKeyValues = @{@"contactID" : idStr,
                                    @"accountID" : @"3270",
                                    @"lastName" : @"Lebowski",
                                    @"firstName" : @"Jeffrey",
                                    //@"birthDate": @"1986-5-19T00:00:00",
                                    @"fullName" : @"Jeffrey Lebowski",
                                    @"academicTitle": @"zen master",
                                    @"title" : @"0000000000000",
                                    @"company" : @"Life inc."
                                    };
    
    
    for (NSString* propertyKey in propKeyValues.allKeys)
    {
        id value = [propKeyValues objectForKey:propertyKey];
        SODataPropertyDefault* property = [[SODataPropertyDefault alloc] initWithName:propertyKey];
        [property setValue:value];
        [anEntity.properties setObject:property forKey:property.name];
    }
    
    [m_OnlineStore allocateNavigationProperties:anEntity error:&error];
    XCTAssertNil(error, @"Error should be nil. Create failed.");
    
    requestParam.payload = anEntity;
    
    // fire the request
    [m_OnlineStore scheduleRequest:requestParam delegate:self];
}

-(void) createOpportunity
{
    /*
     CRM_BUPA_ODATA.Opportunity
     {
     expRevenue: NSDecimalNumber
     status: __NSCFString
     closingDate: __NSTaggedDate
     startDate: __NSTaggedDate
     probability: __NSCFString
     objectId: __NSCFString
     currPhaseText: __NSCFConstantString
     Guid: SODataGuid
     currency: __NSCFString
     description: __NSCFString
     statusText: __NSCFString
     }
     */
    
    // fire the request
    SODataRequestParamSingleDefault *requestParam = [[SODataRequestParamSingleDefault alloc] initWithMode:SODataRequestModeCreate resourcePath:@"OpportunityCollection"];
    
    SODataEntityDefault* anEntity = [[SODataEntityDefault alloc] initWithType:@"CRM_BUPA_ODATA.Opportunity"];
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
    
    NSError* error = nil;
    [m_OnlineStore allocatePropertiesOfEntity:anEntity mode:SODataRequestModeCreate error:&error];
    XCTAssertNil(error, @"Error should be nil. Create failed.");
    
    requestParam.payload = anEntity;
    
    // fire the request
    [m_OnlineStore scheduleRequest:requestParam delegate:self];
}

-(void) createAppointment
{
    /*
     CRM_BUPA_ODATA.Appointment {
     Status: __NSCFString
     ToDate: __NSTaggedDate
     HasAttachment: __NSCFBoolean
     AccountTxt: __NSCFString
     Responsible: __NSCFConstantString
     ContactTxt: __NSCFString
     PrivatFlag: __NSCFBoolean
     MyOwn: __NSCFBoolean
     Location: __NSCFString
     Account: __NSCFString
     ContactAccount: __NSCFString
     ResponsArea: __NSCFConstantString
     ToOffset: __NSCFNumber
     Note: __NSCFString
     Description: __NSCFString
     ChangedAt: __NSTaggedDate
     PriorityTxt: __NSCFConstantString
     ResponsibleTxt: __NSCFString
     StatusTxt: __NSCFString
     AllDay: __NSCFBoolean
     Contact: __NSCFString
     Priority: __NSCFString
     FromOffset: __NSCFNumber
     Guid: SODataGuid
     FromDate: __NSTaggedDate
     }
     */
    
    // fire the request
    SODataRequestParamSingleDefault* requestParam = [[SODataRequestParamSingleDefault alloc] initWithMode:SODataRequestModeCreate resourcePath:@"AppointmentCollection"];
    
    SODataEntityDefault* anEntity = [[SODataEntityDefault alloc] initWithType:@"CRM_BUPA_ODATA.Appointment"];
    
    XS_GuidValue* guid = [XS_GuidValue random];
    SODataGuid* odataGuid = [[SODataGuid alloc]initWithString36:[guid toString36]];
    
    NSDictionary* propKeyValues = @{@"Description" : @"n.a.",
                                    @"ContactAccount" : @"master",
                                    @"Guid" : odataGuid,
                                    @"category" : @"2",
                                    //@"FromDate" : @"2015-5-19T00:00:00",
                                    @"Responsible"   : @"M.Z.",
                                    @"PriorityTxt" : @"low",
                                    @"Status"  : @"E0002",
                                    @"Note" : @"Be there 10 mins earlier!",
                                    @"expectedRevenue" : @"100.000"
                                    };
    
    
    for (NSString* propertyKey in propKeyValues.allKeys)
    {
        id value = [propKeyValues objectForKey:propertyKey];
        SODataPropertyDefault* property = [[SODataPropertyDefault alloc] initWithName:propertyKey];
        [property setValue:value];
        [anEntity.properties setObject:property forKey:property.name];
    }
    
    NSError* error = nil;
    [m_OnlineStore allocatePropertiesOfEntity:anEntity mode:SODataRequestModeCreate error:&error];
    XCTAssertNil(error, @"Error should be nil. Create failed.");
    
    requestParam.payload = anEntity;
    
    // fire the request
    [m_OnlineStore scheduleRequest:requestParam delegate:self];
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
    if( !m_LogonCore.state.isSecureStoreOpen )
    {
        [m_LogonCore unlockSecureStore:passcode_in error:&error];
        if( error )
        {
            NSLog(@"Could not unlock secure store - %@", error.description);
            retVal = NO;
        }
    }
    
    m_LogonContext = [m_LogonCore getContext:&error];
    
    if( error )
    {
        NSLog(@"Could not retrieve logon context from secure store - %@", error.description);
        retVal = NO;
    }
    
    return retVal;
}

-(void) login:(NSString*)appID_in url:(NSURL*)url_in credentials:(NSURLCredential*)credential_in
{
    if( m_LogonCore.state.isRegistered  )
    {
        if( [self unlockSecureStoreIfNeeded:nil] )
        {
            [self initStore];
        }
        return;
    }
    
    m_LogonContext = [MAFLogonContext new];

    MAFLogonRegistrationContext* regContext = [MAFLogonRegistrationContext new];
    regContext.applicationId = appID_in;
    regContext.serverHost = url_in.host;
    regContext.isHttps = [url_in.scheme compare:@"https" options:NSCaseInsensitiveSearch] == NSOrderedSame ? YES : NO;
    regContext.serverPort = url_in.port.intValue;

    regContext.backendUserName = credential_in.user;
    regContext.backendPassword = credential_in.password;
    
    m_LogonContext.registrationContext = regContext;
    
    [m_LogonCore registerWithContext:m_LogonContext];    
}

/**
 *  Initializes the store (online, offline, demo mode)
 */
-(void) initStore
{
    NSURLCredential* credential = [NSURLCredential credentialWithUser:m_UserName password:m_Password persistence:NSURLCredentialPersistenceForSession];
    
    SAPStoreManager* storeManager = [SAPStoreManager sharedInstance];
    // Configure store facade
    storeManager.conversationManager = m_ConversationManager;
    
    storeManager.endpoint = [NSURL URLWithString:CRM_ENDPOINT];
    
    storeManager.credentials = credential;
    
    storeManager.storeMode = ONLINE_STORE;
    
    [storeManager openStore:^(id<SODataStoreAsync> store, NSError *error) {
        NSString* storeType = (storeManager.storeMode == ONLINE_STORE) ? @"Online" : @"Offline";
        if( error )
        {
            NSLog(@"Error opening %@ store: %@", storeType, [error localizedDescription]);
        }
        else
        {
            NSLog(@"Logon succesful. Online store succesfully opened.");
            m_OnlineStore = store;
            [self retrieveAppCID];
        }
        
        [m_LoginExpectation fulfill];
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
    m_LogonContext = [m_LogonCore getContext:&error];
    
    if( error )
    {
        NSLog(@"Could not retrieve logon context from secure store - %@", error.description);
        retVal = NO;
    }
    else
    {
        MAFLogonRegistrationContext* regContext = m_LogonContext.registrationContext;
        NSMutableDictionary* dict = regContext.connectionData[keyMAFLogonConnectionDataApplicationSettings];
        NSString* appCID = dict[keyApplicationSettings_ApplicationConnectionId];
        if( !appCID.length )
        {
            NSLog( @"Could not retrieve application connection ID. Details: %@", error.localizedDescription );
            retVal = NO;
        }
        else
        {
            [Settings sharedInstance].appCID = appCID;
        }
    }
    
    return retVal;
}

#pragma mark - MAFLogonCoreDelegate
-(void) registerFinished:(NSError*)anError
{
    if( anError )
    {
        NSLog( @"Registration failure. Details:%@", anError.localizedDescription );
        
        [m_LoginExpectation fulfill];
    }
    else
    {
        NSLog( @"Logon succesful." );
        // persist registration
        NSError* error = nil;
        [m_LogonCore persistRegistration:nil logonContext:m_LogonContext error:&error];
        if( error )
        {
            NSLog( @"Could not persist registration. Details: %@", error.localizedDescription );
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

#pragma mark - SODataRequestDelegate

- (void) requestServerResponse:(id<SODataRequestExecution>)requestExecution
{
    NSLog(@"Request (%@) succesfully completed", [[requestExecution request] description]);
    [m_Expectation fulfill];
}


- (void) requestFailed:(id<SODataRequestExecution>)requestExecution error:(NSError *)error
{
    NSString* errorMessage = [NSString stringWithFormat:@"Request (%@) failed: %@", [[requestExecution request] description], [error debugDescription]];
    NSLog(@"%@", errorMessage);
    [m_Expectation fulfill];
    XCTFail("Request failed! %@", errorMessage);
}

@end
