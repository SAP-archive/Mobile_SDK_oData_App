//
//  SAPStoreManager.h
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.08..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SODataStoreAsync;
@protocol SODataRequestExecution;
@protocol SODataEntity;
@class HttpConversationManager;
@class SODataOnlineStore;
@class SODataOfflineStore;
@class SODataOfflineStoreOptions;

/**
 *  Defines store modes
 */
typedef NS_ENUM(NSUInteger, E_STORE_MODE)
{
    ONLINE_STORE,
    OFFLINE_STORE,
    DEMO_STORE
};


/**
 *  NSNotification userInfo dictionary key for store state description from
 */
static NSString* kStoreStateKey = @"kStoreStateKey";

/**
 *  Notification sent to observers whenever the store state changes
 *  Subscribers should retrieve the state sttring from the userInfo dictionary using the kStoreStateKey
 */
static NSString* kStoreStateNotificationName = @"kStoreStateNotificationName";


/**
 *  Facade on top of SODataOnlineStore and SODataOffline Store and networking
 *  Exposes block-based APIs to simplify SDK usage
 */
@interface SAPStoreManager : NSObject

/**
 *  Returns / updates the store mode; default is ONLINE_STORE
 * @see initWithEndpoint:credentials:storeMode:
 */
@property (assign, nonatomic) E_STORE_MODE storeMode;

@property (strong, nonatomic) HttpConversationManager* conversationManager;

@property (strong, nonatomic) NSURLCredential* credentials; ///< when using the singleton, credentials must be provided prior to usage
@property (strong, nonatomic) NSURL* endpoint; ///< when using the singleton, credentials must be provided prior to usage
@property (strong, nonatomic) SODataOfflineStoreOptions* offlineOptions; ///< required for offline stores
@property (strong, nonatomic, readonly) id<SODataStoreAsync> store; ///< initialized online or offline store; nil if not yet created

/**
 *  Singleton instance
 *  Endpoint and credentials must be provided prior to usage
 *  @return shared instance
 */
+(instancetype) sharedInstance;

/**
 *  Creates an instance which is ready to use
 *
 *  @param endpoint_in    endpoint url
 *  @param credentials_in credentials to access the endpoint
 *  @param storeMode_in tells whether online or offline store should be used
*
 *  @return facade instance or nil in case of issues
 */
-(instancetype) initWithEndpoint:(NSURL*)endpoint_in credentials:(NSURLCredential*)credentials_in storeMode:(E_STORE_MODE)storeMode_in;

/**
 *  Opens the online or offline store store
 *  Inspect the error once the completion block; nil means no issues
 *
 *  @remark Call this right after facade init to download and parse SVC and metadata
 */
-(void) openStore:(void (^)(id<SODataStoreAsync> store, NSError* error)) completionBlock;

/**
 *  Wraps OData READ call
 *
 *  @param URLString      resource path
 *  @param completionBlock
 *
 *  @return SODataRequestExecution instance (so that you can e.g. cancel the request, etc.)
 */
-(id<SODataRequestExecution>) READ:(NSString*)URLString completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock;

/**
 *  Wraps OData CREATE call
 *
 *  @param URLString      resource path
 *  @param completionBlock
 *
 *  @return SODataRequestExecution instance (so that you can e.g. cancel the request, etc.)
 */
-(id<SODataRequestExecution>) CREATE:(id<SODataEntity>)entity inCollection:(NSString*)collection completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock;
//-(void)createEntity:(id<SODataEntity>) entity inCollection:(NSString *)collection withCompletion:(void(^)(BOOL success, id<SODataEntity> newEntity))completion;

/**
 *  Wraps OData UPDATE call
 *
 *  @param URLString      resource path
 *  @param completionBlock
 *
 *  @return SODataRequestExecution instance (so that you can e.g. cancel the request, etc.)
 */
//-(id<SODataRequestExecution>) UPDATE:(NSString*)URLString completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock;
-(id<SODataRequestExecution>) UPDATE:(id<SODataEntity>)entity inCollection:(NSString*)collection completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock;

/**
 *  Wraps OData DELETE call
 *
 *  @param URLString      resource path
 *  @param completionBlock
 *
 *  @return SODataRequestExecution instance (so that you can e.g. cancel the request, etc.)
 */
-(id<SODataRequestExecution>) DELETE:(id<SODataEntity>)entity completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock;
//-(id<SODataRequestExecution>) DELETE:(NSString*)URLString completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock;

/**
 *  Wraps OData PATCH call
 *
 *  @param URLString      resource path
 *  @param completionBlock
 *
 *  @return SODataRequestExecution instance (so that you can e.g. cancel the request, etc.)
 */
-(id<SODataRequestExecution>) PATCH:(id<SODataEntity>)entity completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock;
//-(id<SODataRequestExecution>) PATCH:(NSString*)URLString completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock;

@end
