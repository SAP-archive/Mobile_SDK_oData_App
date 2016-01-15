//
//  SAPCRMODataTests.m
//  SAPCRMODataTests
//
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "SAPStoreManager.h"
//#import "HttpConversationManager.h"

@interface SAPCRMODataTests : XCTestCase

@end

@implementation SAPCRMODataTests
{
    
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

-(void) test_00DemoModeInit_Negative
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"Asynchronous open DEMO Store test"];
    
    [[SAPStoreManager sharedInstance] setStoreMode:DEMO_STORE];
    [[SAPStoreManager sharedInstance] openStore:^(id<SODataStoreAsync> store, NSError *error) {
        if( error )
        {
            NSLog(@"%@", error.description);
        }
        XCTAssertNotNil( error, @"Should receive error when attempting to open store" );
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error, @"Something went wrong: %@", error.description);
    }];
}

/*
- (void)testConcurrentRead
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Asynchronous dummy READ operation test"];
    
    // XXX: initialized without a valid store
    [SAPStoreManager sharedInstance] READ:@"dummy" completion:^(id<SODataRequestExecution> requestExecution, NSError *error) {
        
    }
    SAPStoreManager* manager = [SAPStoreOperation shared;
    [readOperation READ:@"dummy" completion:^(id<SODataRequestExecution> requestExecution, NSError *error) {
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:100.0 handler:nil];
}
*/

@end
