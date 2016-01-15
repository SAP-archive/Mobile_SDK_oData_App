//
//  DemoRequestExecution.h
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.14..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SODataRequestExecution.h"
#import "Constants.h"

#pragma mark - DemoRequestExecution
@interface DemoRequestExecution : NSObject <SODataRequestExecution>

//-(instancetype) initWithRequest:(id<SODataRequestParam>)request;

@property (readonly, nonatomic, strong) id<SODataResponse> response;

@end


#pragma mark - DemoResponse
#import "SODataResponseSingle.h"

@interface DemoResponse : NSObject <SODataResponseSingle>
-(instancetype) initWithType:(E_OBJECT_TYPE)type;
@end


#pragma mark - DemoEntitySet
#import "SODataEntitySet.h"

@interface DemoEntitySet : NSObject <SODataEntitySet>
-(instancetype) initWithType:(E_OBJECT_TYPE)type;
@end

#pragma mark - DemoEntity
#import "SODataEntity.h"

@interface DemoEntity : NSObject <SODataEntity>
-(instancetype) initWithType:(E_OBJECT_TYPE)type;

@property (nonatomic, copy) NSString * resourcePath;
@property (nonatomic, copy) NSString * editResourcePath;

@end
