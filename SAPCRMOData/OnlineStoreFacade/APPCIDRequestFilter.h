//
//  APPCIDRequestFilter.h
//  SAPCRMOData
//
//  Created by Nyisztor Karoly on 2014.10.31..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RequestFilterProtocol.h"
/**
 *  Provides the AppCID
 *  @remark Should be used only in special cases, not needed if logon logic is proprely integrated
 */
@interface APPCIDRequestFilter : NSObject <RequestFilterProtocol>

@end
