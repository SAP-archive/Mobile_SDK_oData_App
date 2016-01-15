//
//  SAPStoreManager.m
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.08..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import "SAPStoreManager.h"
#import "Constants.h"

#import "SAPStoreOperation.h"

#import "HttpConversationManager.h"
#import "CommonAuthenticationConfigurator.h"
#import "SODataRequestParamSingleDefault.h"

#import "SODataStoreAsync.h"
#import "SODataOnlineStore.h"
#import "SODataOfflineStore.h"

#import "DemoOnlineStore.h"
#import "DemoRequestExecution.h"

#import "APPCIDRequestFilter.h"

#import "Settings.h"

#import "SOData.h"

/*
 1. openStore fetches SVC and metadata
 2. call onlinestore scheduleRequest with metadata.resourcePath to get collections
 3. 
 */
#pragma mark - Constants and declarations

// local constants
static NSString* kEndpointKeyPath = @"endpoint";
static NSString* kCredentialsKeyPath = @"credentials";
static NSString* kStoreModeKeyPath = @"storeMode";

// custom callback declarations
typedef void (^StoreOpenBlock)(id<SODataStoreAsync> store, NSError* error);

//typedef void (^SuccessBlock)(id<SODataRequestExecution> requestExecution);
typedef void (^RequestExecBlock)(id<SODataRequestExecution>requestExecution, NSError* error);

#pragma mark - Private interface

@interface SAPStoreManager () <UsernamePasswordProviderProtocol, SODataOnlineStoreDelegate, SODataOfflineStoreDelegate>
@property (nonatomic, copy) StoreOpenBlock storeOpenBlock; ///< invoked after store open requests
@property (strong, nonatomic) id<SODataStoreAsync> store;
@property (nonatomic, strong) NSMutableArray* operations;
@property (nonatomic, strong) dispatch_semaphore_t storeSemaphore;

@end

@implementation SAPStoreManager
{
    SODataOfflineStore* m_OfflineStore;
    SODataOnlineStore* m_OnlineStore;
    HttpConversationManager* m_ConversationManager;
    BOOL m_OfflineStoreOpenFailed;
}

const NSUInteger kSAPCRMOnlineStoreSemaphoreId = 0xef;

+(instancetype) sharedInstance
{
    static dispatch_once_t onceToken;
    static SAPStoreManager* instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [SAPStoreManager new];
    });
    
    return instance;
}

-(NSString*) description
{
    return [NSString stringWithFormat:@"SAPStoreManager:\n\
            Endpoint: %@\n\
            Store Mode: %@\n\
            Username: %@ Password: %@\n\
            Store initialized: %@",
            _endpoint.absoluteString,
            [self storeModeString],
            _credentials.user,
            _credentials.password,
            _store ? @"YES" : @"NO"];
}

-(instancetype) initWithEndpoint:(NSURL*)endpoint_in credentials:(NSURLCredential*)credentials_in storeMode:(E_STORE_MODE)storeMode_in
{
    if( !endpoint_in || !credentials_in )
    {
        NSLog(@"Error: provide valid enpoint and credentials!");
        return nil;
    }
    
    self = [self init];
    if( self )
    {
        self.credentials = credentials_in;
        self.endpoint = endpoint_in;
        self.storeMode = storeMode_in;
        
        [self initStore];
    }
    
    return self;
}

-(instancetype) init
{
    self = [super init];
    if( self )
    {
        self.storeMode = ONLINE_STORE;
        self.operations = [NSMutableArray array];
        
        self.storeSemaphore = dispatch_semaphore_create(kSAPCRMOnlineStoreSemaphoreId);
        
        // perform inits
        [self addObserver:self forKeyPath:kCredentialsKeyPath options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:kEndpointKeyPath options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:kStoreModeKeyPath options:NSKeyValueObservingOptionNew context:nil];        
    }
    return self;
}

-(void) setConversationManager:(HttpConversationManager *)conversationManager
{
    if(  m_ConversationManager != conversationManager )
    {
        m_ConversationManager = conversationManager;
        // configure the conversation manager to use SAPStoreManager instance as authentication delegate
        CommonAuthenticationConfigurator* commonConfig = [[CommonAuthenticationConfigurator alloc] init];
        [commonConfig addUsernamePasswordProvider:self];
        [commonConfig configureManager:self.conversationManager];
    }
}

-(HttpConversationManager*)conversationManager
{
    return m_ConversationManager;
}

-(BOOL) initStore
{
    BOOL result = YES;
    
    if( (_storeMode != DEMO_STORE) && (!_endpoint || !_credentials) )
    {
        return NO;
    }
    
    switch (_storeMode)
    {
        case ONLINE_STORE:
        {
            result = [self initOnlineStore];
        } break;
        case OFFLINE_STORE:
        {
            result = [self initOfflineStore];
        } break;
        case DEMO_STORE:
        {
            result = [self initDemoStore];
        } break;
        default:
        {
            LOGWAR(@"Unknown store type!");
        }
    }
    
    return result;
}
/**
 *  Initializes the online store
 *
 *  @return online store instance
 */
-(BOOL) initOnlineStore
{
    m_OnlineStore = [[SODataOnlineStore alloc] initWithURL:_endpoint httpConversationManager:m_ConversationManager];
    self.store = m_OnlineStore;
    
    [m_OnlineStore setOnlineStoreDelegate:self];

    return (m_OnlineStore != nil);
}

-(BOOL) initOfflineStore
{
    // inits global memory data structures for offline store
    if( _storeMode == OFFLINE_STORE )
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [SODataOfflineStore GlobalInit];
        });
    }
    
    m_OfflineStore = [[SODataOfflineStore alloc] init];
    self.store = m_OfflineStore;
    
    [m_OfflineStore setOfflineStoreDelegate:self];
    
    return (m_OfflineStore != nil);
}

/**
 *  initializes a store for demo purposes
 *
 *  @return store providing mock data
 */
-(BOOL) initDemoStore
{
    m_OnlineStore = [DemoOnlineStore new];
    self.store = m_OnlineStore;
    [m_OnlineStore setOnlineStoreDelegate:self];
    
    return (_store != nil);
}

#pragma mark - APIs

-(void) openStore:(void (^)(id<SODataStoreAsync> store, NSError* error)) completionBlock
{
    //[_storeLock lock];
    dispatch_semaphore_wait(_storeSemaphore, 0);
    
    // store for delegates
    self.storeOpenBlock = completionBlock;
    
    NSError* error = [self validateStore];
    
    if( error )
    {
        completionBlock( nil, error );
        
        dispatch_semaphore_signal(_storeSemaphore);
        
        return;
    }
    
    switch( _storeMode )
    {
        case ONLINE_STORE:
        {
            [m_OnlineStore openStoreWithError:&error];
        } break;
        case OFFLINE_STORE:
        {
            // offline store options shall be set for offline store to work
            if( !_offlineOptions )
            {
                error = [NSError errorWithDomain:kErrorDomainStoreManager code:kErrorCodeNoOfflineStoreOptions userInfo:@{ NSLocalizedDescriptionKey: @"No offline store options have been set" }];
                
                completionBlock( nil, error );
                
                dispatch_semaphore_signal(_storeSemaphore);
                
                return;
            }
            
            m_OfflineStoreOpenFailed = NO;
            [m_OfflineStore openStoreWithOptions:_offlineOptions error:&error];
        } break;
        case DEMO_STORE:
        {
            // nop
        } break;
        default:
        {
            LOGWAR(@"Cannot open store - unknown store type!");
        }
    }

    if (error)
    {
        LOGERR(@"Error opening %@ store: %@", [self storeNameForMode:_storeMode], [error debugDescription]);
        
        completionBlock( nil, error );

        dispatch_semaphore_signal(_storeSemaphore);
    }
}

-(id<SODataRequestExecution>) READ:(NSString*)URLString completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock
{
    NSError* error = [self validateStore];
    if( error )
    {
        completionBlock( nil, error );
        return nil;
    }
    
    id<SODataRequestExecution> result = nil;
    
    if( _storeMode == DEMO_STORE )
    {
        SODataRequestParamSingleDefault* requestParam = [[SODataRequestParamSingleDefault alloc] initWithMode:SODataRequestModeRead resourcePath:URLString];
        result = [[DemoRequestExecution alloc] initWithRequest:requestParam];
        
        completionBlock( result, nil );
    }
    else
    {
        SAPStoreOperation* operation = [[SAPStoreOperation alloc] initWithStore:_store];

        [_operations addObject:operation];
        
        result = [operation READ:URLString completion:^(id<SODataRequestExecution> requestExecution, NSError *error) {
            if( error )
            {
                LOGERR(@"Error: %@", [error localizedDescription]);
            }
            completionBlock( requestExecution, error );
            // remove operation once it finished
            [_operations removeObject:operation];
        }];
    }
    return result;
}

-(id<SODataRequestExecution>) CREATE:(id<SODataEntity>)entity inCollection:(NSString*)collection completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock
{
    NSError* error = [self validateStore];
    if( error )
    {
        completionBlock( nil, error );
        return nil;
    }
    
    id<SODataRequestExecution> result = nil;
    
    if( _storeMode == DEMO_STORE )
    {
        // no create in demo mode
        error = [NSError errorWithDomain:kErrorDomainStoreManager code:kErrorCodeUnavailableInDemoMode userInfo:@{ NSLocalizedDescriptionKey: @"Cannot create in Demo mode." }];
        
        completionBlock( nil, error );
    }
    else
    {
        SAPStoreOperation* operation = [[SAPStoreOperation alloc] initWithStore:_store];
        
        [_operations addObject:operation];
        
        result = [operation CREATE:entity inCollection:collection completion:^(id<SODataRequestExecution> requestExecution, NSError *error) {
            if( error )
            {
                LOGERR(@"Error: %@", [error localizedDescription]);
            }
            completionBlock( requestExecution, error );
            
            [_operations removeObject:operation];
        }];
    }
    return result;
}

//-(id<SODataRequestExecution>) CREATE:(NSString*)URLString completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock
//{
//    return [self executeInMode:SODataRequestModeCreate url:URLString completion:completionBlock];
//}

-(id<SODataRequestExecution>) UPDATE:(id<SODataEntity>)entity inCollection:(NSString*)collection completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock
{
    NSError* error = [self validateStore];
    if( error )
    {
        completionBlock( nil, error );
        return nil;
    }
    
    id<SODataRequestExecution> result = nil;
    
    if( _storeMode == DEMO_STORE )
    {
        // no edit in demo mode
        error = [NSError errorWithDomain:kErrorDomainStoreManager code:kErrorCodeUnavailableInDemoMode userInfo:@{ NSLocalizedDescriptionKey: @"Cannot update in Demo mode." }];

        completionBlock( nil, error );
    }
    else
    {
        SAPStoreOperation* operation = [[SAPStoreOperation alloc] initWithStore:_store];
        [_operations addObject:operation];
        
        result = [operation UPDATE:entity inCollection:collection completion:^(id<SODataRequestExecution> requestExecution, NSError *error) {
            if( error )
            {
                LOGERR(@"Error: %@", [error localizedDescription]);
            }
            completionBlock( requestExecution, error );
            
            [_operations removeObject:operation];
        }];
    }
    return result;
}

-(id<SODataRequestExecution>) DELETE:(id<SODataEntity>)entity completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock
{
    NSError* error = [self validateStore];
    if( error )
    {
        completionBlock( nil, error );
        return nil;
    }
    
    id<SODataRequestExecution> result = nil;
    
    if( _storeMode == DEMO_STORE )
    {
        // no delete in demo mode
        error = [NSError errorWithDomain:kErrorDomainStoreManager code:kErrorCodeUnavailableInDemoMode userInfo:@{ NSLocalizedDescriptionKey: @"Cannot delete in Demo mode." }];
        
        completionBlock( nil, error );
    }
    else
    {
        SAPStoreOperation* operation = [[SAPStoreOperation alloc] initWithStore:_store];
        [_operations addObject:operation];
        
        result = [operation DELETE:entity completion:^(id<SODataRequestExecution> requestExecution, NSError *error) {
            if( error )
            {
                LOGERR(@"Error: %@", [error localizedDescription]);
            }
            completionBlock( requestExecution, error );
            
            [_operations removeObject:operation];
        }];
    }
    return result;
}

-(id<SODataRequestExecution>) PATCH:(id<SODataEntity>)entity completion:(void (^)(id<SODataRequestExecution> requestExecution, NSError *error))completionBlock
{
    NSError* error = [self validateStore];
    if( error )
    {
        completionBlock( nil, error );
        return nil;
    }
    
    id<SODataRequestExecution> result = nil;
    
    if( _storeMode == DEMO_STORE )
    {
        // no delete in demo mode
        error = [NSError errorWithDomain:kErrorDomainStoreManager code:kErrorCodeUnavailableInDemoMode userInfo:@{ NSLocalizedDescriptionKey: @"Cannot patch in Demo mode." }];
        
        completionBlock( nil, error );
    }
    else
    {
        SAPStoreOperation* operation = [[SAPStoreOperation alloc] initWithStore:_store];
        [_operations addObject:operation];
        
        result = [operation PATCH:entity completion:^(id<SODataRequestExecution> requestExecution, NSError *error) {
            if( error )
            {
                LOGERR(@"Error: %@", [error localizedDescription]);
            }
            completionBlock( requestExecution, error );
            
            [_operations removeObject:operation];
        }];
    }
    return result;
}

#pragma mark - Key-Value Observing methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // init the store if credentials and endpoint are both available
    if ([keyPath isEqualToString:kEndpointKeyPath]
    || [keyPath isEqualToString:kCredentialsKeyPath])
    {
        if( self.credentials && self.endpoint )
        {
            [self initStore];
        }
    }
    else if( [keyPath isEqualToString:kStoreModeKeyPath] )
    {
        if( (_storeMode == DEMO_STORE)
        || (self.credentials && self.endpoint) )
        {
            [self initStore];
        }
    }
}

#pragma mark - UsernamePasswordProviderProtocol implementation
- (void) provideUsernamePasswordForAuthChallenge:(NSURLAuthenticationChallenge*)authChallenge completionBlock:(void (^)(NSURLCredential*, NSError*))completionBlock
{
    LOGDEB(@"provideUsernamePasswordForAuthChallenge");

#ifdef DEBUG
    static NSUInteger kMaxAuthenticationAttempts = 5;
    if( authChallenge.previousFailureCount < kMaxAuthenticationAttempts )
    {
        NSLog( @"\t\t\tAuthentication failed for endpoint:%@, username:%@ password:%@", _endpoint, _credentials.user, _credentials.password );
    }
    
    NSAssert( authChallenge.previousFailureCount < kMaxAuthenticationAttempts, @"Authentication failure" );
#endif

    dispatch_async(dispatch_get_main_queue(), ^(void) {
        completionBlock(self.credentials, nil);
    });
}

#pragma mark - OnlineStoreDelegate implementation
- (void)onlineStoreOpenFinished:(SODataOnlineStore*)store
{
    LOGDEB(NSLocalizedString(@"The store has opened successfully", nil));
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kStoreStateNotificationName object:nil userInfo:@{ kStoreStateKey : NSLocalizedString(@"The store has opened successfully", nil) }];

    dispatch_async(dispatch_get_main_queue(), ^(void) {
        self.storeOpenBlock( store, nil );
    });

    dispatch_semaphore_signal(_storeSemaphore);
}

-(void)onlineStoreOpenFailed:(SODataOnlineStore*)store error:(NSError*)error
{
    LOGERR(@"Online store open failed: %@", [error debugDescription]);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kStoreStateNotificationName object:nil userInfo:@{ kStoreStateKey : NSLocalizedString(@"Online store open failed.", nil) }];
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        self.storeOpenBlock( store, error );
    });

    dispatch_semaphore_signal(_storeSemaphore);
}

#pragma mark - SODataOfflineStoreDelegate implementation
/**
 * Called when the store state changes
 *
 * @param store the offline store being opened
 * @param newState the new state of the store
 *
 * \sa SODataOfflineStoreState
 */
- (void) offlineStoreStateChanged:(SODataOfflineStore*) store
                            state:(SODataOfflineStoreState) newState
{
    NSDictionary* storeStates = @{ @(SODataOfflineStoreOpening) : NSLocalizedString(@"The store has started to open", nil),
                                          @(SODataOfflineStoreInitializing) : NSLocalizedString(@"Initializing the resources for a new store", nil),
                                          @(SODataOfflineStorePopulating) : NSLocalizedString(@"Populating the store", nil),
                                          @(SODataOfflineStoreDownloading) : NSLocalizedString(@"Downloading the store", nil),
                                          @(SODataOfflineStoreOpen) : NSLocalizedString(@"The store has opened successfully", nil),
                                          @(SODataOfflineStoreClosed) : NSLocalizedString(@"The store has been closed by the user while opening", nil) };
    LOGDEB(@"%@", storeStates[@(newState)]);

    [[NSNotificationCenter defaultCenter] postNotificationName:kStoreStateNotificationName object:nil userInfo:@{ kStoreStateKey : storeStates[@(newState)] }];
}
/**
 * Called if the store fails to open
 *
 * @param store the offline store being opened
 * @param error the error that occurred
 */
- (void) offlineStoreOpenFailed:(SODataOfflineStore*) store
                          error:(NSError*) error
{
    LOGERR(@"Offline store open failed: %@", [error debugDescription]);
    m_OfflineStoreOpenFailed = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        self.storeOpenBlock( store, error );
    });
    
    dispatch_semaphore_signal(_storeSemaphore);
}

/**
 * Called when the store finishes opening.
 * Guaranteed to be invoked at the end of the open processing regardless of the outcome of the open.
 *
 * @param store the offline store being opened
 */
- (void) offlineStoreOpenFinished:(SODataOfflineStore*) store
{
    if( m_OfflineStoreOpenFailed )
    {
        LOGDEB(@"Offline store open failed");
    }
    else
    {
        LOGDEB(@"Offline store open completed succesfully");
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            self.storeOpenBlock( store, nil );
        });
    }
    
    dispatch_semaphore_signal(_storeSemaphore);
}

#pragma mark - Helpers
/**
 *  Retrieves the store name for given mode
 *
 *  @param storeMode_in <#storeMode_in description#>
 *
 *  @return <#return value description#>
 */
-(NSString*) storeNameForMode:(E_STORE_MODE)storeMode_in
{
    NSDictionary* storeNames = @{ @(ONLINE_STORE) : @"Online",
                                  @(OFFLINE_STORE) : @"Offline",
                                  @(DEMO_STORE) : @"Demo", };
    
    NSString* result = storeNames[@(storeMode_in)];
    
    return (result ? result : @"unknown");
}

/**
 *  Cehcks whether there is a valid store instance available
 *
 *  @return nil, if store is ready, NSError filled with details otherwise
 */
-(NSError*) validateStore
{
    NSError* error = nil;
    
    if( !_store )
    {
        error = [NSError errorWithDomain:kErrorDomainStoreManager code:kErrorCodeNoStore userInfo:@{ NSLocalizedDescriptionKey: @"Store has not been initialized yet" }];
    }
    return error;
}

-(NSString*) storeModeString
{
    NSString* result = nil;
    switch( _storeMode )
    {
        case ONLINE_STORE:
        {
            result = @"Online store";
        } break;
        case OFFLINE_STORE:
        {
            result = @"Offline store";
        } break;
        case DEMO_STORE:
        {
            result = @"Demo store";
        } break;
        default:
        {
            result = @"Unknown store type";
        }
    }
    return result;
}

@end
