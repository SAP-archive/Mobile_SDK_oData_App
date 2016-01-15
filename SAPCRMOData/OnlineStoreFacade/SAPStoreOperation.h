//
//  SAPOnlineStoreOperation.h
//  SAPCRMOData
//
//  Created by Nyisztor Karoly on 2014.10.28..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SODataStoreAsync;
@protocol SODataRequestExecution;
@protocol SODataEntity;


@interface SAPStoreOperation : NSObject

@property (strong, nonatomic, readonly) id<SODataStoreAsync> store; ///< initialized online or offline store; nil if not yet created

/**
 *  Initializes the operation with an online or offline store
 *
 *  @param store online or offline store
 *
 *  @return valid SAPStoreOperation instance
 */
-(instancetype) initWithStore:(id<SODataStoreAsync>) store;

#pragma mark - Supported operations
/**
 *  Executes a Read OData request
 *
 *  @param URLString       endpoint
 *  @param completionBlock block to be executed once the asynchronous operaiton finishes
 *
 *  @return request execution instance
 */
-(id<SODataRequestExecution>) READ:(NSString*)URLString completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock;

/**
 *  Executes a Create OData request
 *
 *  @param URLString       holds collection ID (e.g. "LeaveRequestCollection")
 *  @param completionBlock block to be executed once the asynchronous operaiton finishes
 *
 *  @return request execution instance
 */
-(id<SODataRequestExecution>) CREATE:(id<SODataEntity>)entity inCollection:(NSString*)collection completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock;

/**
 *  Executes an Update OData request
 *
 *  @param URLString       endpoint
 *  @param completionBlock block to be executed once the asynchronous operaiton finishes
 *
 *  @return request execution instance
 */
-(id<SODataRequestExecution>) UPDATE:(id<SODataEntity>)entity inCollection:(NSString*)collection completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock;

/**
 *  Executes a Patch OData request
 *
 *  @param URLString       endpoint
 *  @param completionBlock block to be executed once the asynchronous operaiton finishes
 *
 *  @return request execution instance
 */
-(id<SODataRequestExecution>) PATCH:(id<SODataEntity>)entity completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock;

/**
 *  Executes a Delete OData request
 *
 *  @param URLString       endpoint
 *  @param completionBlock block to be executed once the asynchronous operaiton finishes
 *
 *  @return request execution instance
 */
-(id<SODataRequestExecution>) DELETE:(id<SODataEntity>)entity completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock;

@end
