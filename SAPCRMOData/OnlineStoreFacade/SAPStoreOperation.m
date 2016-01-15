//
//  SAPOnlineStoreOperation.m
//  SAPCRMOData
//
//  Created by Nyisztor Karoly on 2014.10.28..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import "SAPStoreOperation.h"
#import "Constants.h"

#import "HttpConversationManager.h"
#import "CommonAuthenticationConfigurator.h"
#import "SODataEntityDefault.h"
#import "SODataRequestParamSingleDefault.h"

#import "SODataStoreAsync.h"
#import "SODataOnlineStore.h"
#import "SODataOfflineStore.h"

#import "DemoOnlineStore.h"
#import "DemoRequestExecution.h"

#import "SOData.h"
#import "SODataPropertyDefault.h"
#import "SODataRequestParamSingleDefault.h"

#pragma mark - Constants and declarations
typedef void (^RequestExecBlock)(id<SODataRequestExecution>requestExecution, NSError* error);

@interface SAPStoreOperation () <SODataRequestDelegate>
@property (nonatomic, strong) id<SODataStoreAsync> store; // can be online or offline store
@property (nonatomic, copy) RequestExecBlock requestExecBlock; ///< called after the request finishes
@property (nonatomic, strong) dispatch_semaphore_t requestSemaphore;

@end

@implementation SAPStoreOperation

const NSUInteger kSAPCRMRequestSemaphoreId = 0xff;

-(instancetype) init
{
    self = [super init];
    if( self )
    {
        self.requestSemaphore = dispatch_semaphore_create(kSAPCRMRequestSemaphoreId);
    }
    
    return self;
}
-(instancetype) initWithStore:(id<SODataStoreAsync>) store
{
    if( !store )
    {
        return nil;
    }
    
    self = [self init];
    
    if( self )
    {
        self.store = store;
    }
    
    return self;
}

-(id<SODataRequestExecution>) READ:(NSString*)URLString completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock
{
    dispatch_semaphore_wait(_requestSemaphore, 0);
    
    // store for delegates
    self.requestExecBlock = completionBlock;
    
    id<SODataRequestExecution> result = nil;
    SODataRequestParamSingleDefault* requestParam = [[SODataRequestParamSingleDefault alloc] initWithMode:SODataRequestModeRead resourcePath:URLString];
    
    result = [self.store scheduleRequest:requestParam delegate:self];
    
    return result;
}

-(id<SODataRequestExecution>) CREATE:(id<SODataEntity>)entity inCollection:(NSString*)collection completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock
{
    dispatch_semaphore_wait(_requestSemaphore, 0);
    
    // store for delegates
    self.requestExecBlock = completionBlock;

    id<SODataRequestExecution> result = nil;
    
    
    SODataRequestParamSingleDefault* requestParam = [[SODataRequestParamSingleDefault alloc] initWithMode:SODataRequestModeCreate resourcePath:collection]; // resourcePath is e.g. @"AccountCollection"

    NSError* error = nil;
    [self.store allocateNavigationProperties:entity error:&error];

    NSAssert(error == nil, @"Error should be nil");
    
    requestParam.payload = entity;
    
    // fire the request
    [self.store scheduleRequest:requestParam delegate:self];
    
    return result;
}

-(id<SODataRequestExecution>) UPDATE:(id<SODataEntity>)entity inCollection:(NSString*)collection completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock
{
    dispatch_semaphore_wait(_requestSemaphore, 0);
    
    // store for delegates
    self.requestExecBlock = completionBlock;
    
    // fire the request
    id<SODataRequestExecution> result = [self.store scheduleUpdateEntity:entity delegate:self options:nil];
    
    return result;
}

-(id<SODataRequestExecution>) PATCH:(id<SODataEntity>)entity completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock
{
    dispatch_semaphore_wait(_requestSemaphore, 0);
    
    // store for delegates
    self.requestExecBlock = completionBlock;
    
    // fire the request
    id<SODataRequestExecution> result = [self.store schedulePatchEntity:entity delegate:self options:nil];
    
    return result;
}

-(id<SODataRequestExecution>) DELETE:(id<SODataEntity>)entity completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock
{
    dispatch_semaphore_wait(_requestSemaphore, 0);
    
    // store for delegates
    self.requestExecBlock = completionBlock;
    
    // fire the request
    id<SODataRequestExecution> result = [self.store scheduleDeleteEntity:entity delegate:self options:nil];
    
    return result;
}

#pragma mark - SODataRequestDelegate
- (void) requestServerResponse:(id<SODataRequestExecution>)requestExecution
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        self.requestExecBlock( requestExecution, nil );
    });
    
    dispatch_semaphore_signal(_requestSemaphore);
}

- (void) requestFailed:(id<SODataRequestExecution>)requestExecution error:(NSError *)error
{
    LOGERR(@"Request (%@) failed: %@", [[requestExecution request] description], [error localizedDescription]);
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        self.requestExecBlock( requestExecution, error );
    });
    
    dispatch_semaphore_signal(_requestSemaphore);
}

@end
