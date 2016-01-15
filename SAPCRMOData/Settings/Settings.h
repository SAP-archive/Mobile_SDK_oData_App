//
//  Settings.h
//  SAPCRMOData
//
//  Created by Nyisztor Karoly on 2014.11.06..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAPClientLogLevel.h"

@interface Settings : NSObject

+(instancetype) sharedInstance;

@property (assign, nonatomic, getter=isVerboseLoggingOn) BOOL verboseLogging;
@property (assign, nonatomic, getter=isE2ETraceOn) BOOL traceOn;
@property (assign, nonatomic, getter=isOfflineStoreOn) BOOL offlineStoreOn;
@property (assign, nonatomic) E_CLIENT_LOG_LEVEL currentLogLevel;
@property (retain, nonatomic) NSString* appCID;


@end
