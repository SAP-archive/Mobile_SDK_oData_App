//
//  Constants.m
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.09..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import "Constants.h"

#pragma mark - Logging and Tracing
NSString* const kAppLoggerID = @"kAppLoggerID";
NSString* const kShowcaseAppE2ETransactionMain = @"kShowcaseAppE2ETransactionMain";

#pragma mark - Collection Names
NSString* const kAccountsCollection = @"Accounts";
NSString* const kContactsCollection = @"Contacts";
NSString* const kAppointmentsCollection = @"Appointments";
NSString* const kOpportunitiesCollection = @"Opportunities";
NSString* const kUnknownCollection = @"Unknown";

#pragma mark - Error Domains
NSString* const kErrorDomainStoreManager = @"com.sap.StoreManagerDomain";

#pragma mark - Error Codes
const NSInteger kErrorCodeNoStore = 100;
const NSInteger kErrorCodeNoOfflineStoreOptions = 101;
const NSInteger kErrorCodeUnavailableInDemoMode = 500;

#pragma mark - Dimensions
const CGFloat kMasterTableWidthLandscape = 320;