//
//  DemoOnlineStore.m
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.13..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import "DemoOnlineStore.h"
#import "SODataMetaEntityTypeDefault.h"

@interface DemoMetadata()

@property (strong, nonatomic) NSMutableDictionary* entityForname;

@end;


@implementation DemoMetadata

@dynamic xml;
@dynamic resourcePath;
@dynamic latestResourcePath;
@dynamic metaNamespaces;
@dynamic metaEntityNames;
@dynamic metaComplexNames;
@dynamic metaEntityContainerNames;

-(instancetype) init
{
    self = [super init];
    if( self )
    {
        self.entityForname = [NSMutableDictionary dictionary];
    }
    
    return self;
}

//- (id)initWithCoder:(NSCoder *)aDecoder
//{
//    return [self init];
//}
//
//-(void) encodeWithCoder:(NSCoder *)aCoder
//{
//    // nop
//}

-(NSArray*) metaEntityNames
{
    return @[@"Contact",
             @"Deal",
             @"Account",
             @"Customer",
             @"Opportunity",
             @"Appointment"];
}

- (id<SODataMetaEntityType>)metaEntityForName:(NSString*)fqName
{
    SODataMetaEntityTypeDefault* metaEntity = _entityForname[fqName];
    
    if( metaEntity == nil )
    {
        SODataMetaEntityTypeDefault* metaEntity = [[SODataMetaEntityTypeDefault alloc] initWithName:fqName isMediaEntity:NO properties:nil keyPropertyNames:nil navigationProperties:nil annotations:nil];
        
        _entityForname[fqName] = metaEntity;
    }
    
    return metaEntity;
}

@end

@implementation DemoOnlineStore

/**
 Metadata
 */
//@property (readonly, nonatomic, strong) NSObject<SODataMetadata>* metadata;

-(id<SODataMetadata>) metadata
{
    static DemoMetadata* result = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        result = [DemoMetadata new];
    });
    
    return result;
}

- (id<SODataRequestExecution>) scheduleRequest:(id<SODataRequestParam>)request delegate:(id<SODataRequestDelegate>)delegate
{
    return nil;
}

@end
