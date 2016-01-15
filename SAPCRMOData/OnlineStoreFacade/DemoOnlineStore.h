//
//  DemoOnlineStore.h
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.13..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import "SODataOnlineStore.h"
#import "SODataMetadata.h"

@interface DemoMetadata : NSObject  <SODataMetadata>
@property (readonly, nonatomic, strong) NSArray* metaEntityNames;
@end

@interface DemoOnlineStore : SODataOnlineStore

@end
