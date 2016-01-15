//
//  Constants.h
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.09..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, E_OBJECT_TYPE)
{
    CONTACTS,
    DEALS,
    TASKS,
    ACCOUNTS,
    CUSTOMERS,
    OPPORTUNITIES,
    APPOINTMENTS,
    UNKNOWN
};

/**
 *  Ordering criteria, used by DataManager APIs
 */
typedef NS_ENUM(NSUInteger, E_ORDER_TYPE)
{
    NAME,
    DATE
};

#pragma mark - Logging and Tracing
extern NSString* const kAppLoggerID;

extern NSString* const kShowcaseAppE2ETransactionMain; ///< E2E transaction name

#pragma mark - Collection Names
extern NSString* const kAccountsCollection;// = @"Accounts"
extern NSString* const kContactsCollection;// = @"Contacts"
extern NSString* const kAppointmentsCollection;// = @"Appointments"
extern NSString* const kOpportunitiesCollection;// = @"Opportunities"
extern NSString* const kUnknownCollection;// = @"Unknown"

#pragma mark - Error Handling Related Constants
// Error Domains
extern NSString* const kErrorDomainStoreManager;

// Error Codes
extern const NSInteger kErrorCodeNoStore;
extern const NSInteger kErrorCodeNoOfflineStoreOptions;
extern const NSInteger kErrorCodeUnavailableInDemoMode;

#pragma mark - Dimensions
extern const CGFloat kMasterTableWidthLandscape;