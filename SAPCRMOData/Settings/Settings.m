//
//  Settings.m
//  SAPCRMOData
//
//  Created by Nyisztor Karoly on 2014.11.06..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import "Settings.h"

static NSString* kVerboseLoggingKey = @"kVerboseLoggingKey";
static NSString* kE2ETraceEnableKey = @"kE2ETraceEnableKey";
static NSString* kOfflineStoreOnKey = @"kOfflineStoreOnKey";
static NSString* kLogLevelKey = @"kLogLevelKey";
static NSString* kAppCIDKey = @"kAppCIDKey";

@interface Settings ()

@property (strong, nonatomic) NSUserDefaults* userDefaults;

@end


@implementation Settings
{
    BOOL m_VerboseLoggingOn;
    BOOL m_TraceOn;
    BOOL m_OfflineStoreOn;
    E_CLIENT_LOG_LEVEL m_CurrentLogLevel;
    NSString* m_AppCID;
}

+(instancetype) sharedInstance
{
    static Settings* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

-(instancetype) init
{
    self = [super init];
    if( self )
    {
        self.userDefaults = [NSUserDefaults standardUserDefaults];
        m_VerboseLoggingOn = [_userDefaults boolForKey:kVerboseLoggingKey];
        m_TraceOn = [_userDefaults boolForKey:kE2ETraceEnableKey];
        m_OfflineStoreOn = [_userDefaults boolForKey:kOfflineStoreOnKey];
        m_CurrentLogLevel = [_userDefaults integerForKey:kLogLevelKey];
        if( m_CurrentLogLevel == 0 )
        {
            [self setCurrentLogLevel:ErrorClientLogLevel];
        }
        m_AppCID = [_userDefaults stringForKey:kAppCIDKey];
    }
    return self;
}

-(void) setVerboseLogging:(BOOL)verboseLogging
{
    if( m_VerboseLoggingOn != verboseLogging )
    {
        m_VerboseLoggingOn = verboseLogging;
        
        [_userDefaults setBool:verboseLogging forKey:kVerboseLoggingKey];
        [_userDefaults synchronize];
    }
}

-(BOOL) isVerboseLoggingOn
{
    return m_VerboseLoggingOn;
}

-(void) setTraceOn:(BOOL)traceOn
{
    if( m_TraceOn != traceOn )
    {
        m_TraceOn = traceOn;
        
        [_userDefaults setBool:traceOn forKey:kE2ETraceEnableKey];
        [_userDefaults synchronize];
    }
}

-(BOOL) isE2ETraceOn
{
    return m_TraceOn;
}


-(void) setOfflineStoreOn:(BOOL)offlineStoreOn
{
    if( m_OfflineStoreOn != offlineStoreOn )
    {
        m_OfflineStoreOn = offlineStoreOn;
        
        [_userDefaults setBool:offlineStoreOn forKey:kOfflineStoreOnKey];
        [_userDefaults synchronize];
    }
}

-(BOOL) isOfflineStoreOn
{
    return m_OfflineStoreOn;
}

-(void) setCurrentLogLevel:(E_CLIENT_LOG_LEVEL)currentLogLevel
{
    if( m_CurrentLogLevel != currentLogLevel )
    {
        m_CurrentLogLevel = currentLogLevel;
        
        [_userDefaults setInteger:currentLogLevel forKey:kLogLevelKey];
        [_userDefaults synchronize];
    }
}

-(E_CLIENT_LOG_LEVEL) currentLogLevel
{
    return m_CurrentLogLevel;
}

-(void) setAppCID:(NSString *)appCID
{
    if( m_AppCID != appCID )
    {
        m_AppCID = appCID;
        
        [_userDefaults setObject:appCID forKey:kAppCIDKey];
        [_userDefaults synchronize];
    }
}

-(NSString*) appCID
{
    return m_AppCID;
}

@end
