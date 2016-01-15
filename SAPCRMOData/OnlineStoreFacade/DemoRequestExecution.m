//
//  DemoRequestExecution.m
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.14..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import "DemoRequestExecution.h"
#import "SODataRequestParamSingleDefault.h"
#import "SODataPropertyDefault.h"

#pragma mark - DemoRequestExecution
@implementation DemoRequestExecution
{
    E_OBJECT_TYPE m_Type;
}

@dynamic uniqueId;
@dynamic status;
@dynamic request;
@dynamic response;

-(instancetype) initWithRequest:(id<SODataRequestParam>)request
{
    self = [self init];
    // retrieve collection type from resource path
    NSString* resourcePath = ((SODataRequestParamSingleDefault*)request).resourcePath;
    // in demo mode, resourcePath can be:
    //    @[@"Contact",
    //      @"Deal",
    //      @"Account",
    //      @"Customer",
    //      @"Opportunity",
    //      @"Appointment"];
#ifdef DEBUG
    NSLog( @"%@", resourcePath );
#endif
    m_Type = [self collectionType:resourcePath];

    return self;
}

-(id<SODataResponse>) response
{
    return [[DemoResponse alloc] initWithType:m_Type];
}

-(void) cancelExecution
{
    // just to silence the compiler
}

-(BOOL)updatedPayload;
{
    // just to silence the compiler
    return YES;
}

-(BOOL)isCachePassive;
{
    // just to silence the compiler
    return YES;    
}

#pragma mark - Helpers
-(E_OBJECT_TYPE) collectionType:(NSString*)path
{
    E_OBJECT_TYPE type = CONTACTS;
    
    NSDictionary* typeNameMap = @{ kAccountsCollection: @(ACCOUNTS),
                                   kContactsCollection: @(CONTACTS),
                                   kAppointmentsCollection: @(APPOINTMENTS),
                                   kOpportunitiesCollection: @(OPPORTUNITIES)};
    
    for (NSString* prefix in typeNameMap.allKeys )
    {
        if( [path hasPrefix:prefix] )
        {
            type = ((NSNumber*)typeNameMap[prefix]).integerValue;
            break;
        }
    }
    
    return type;
}

@end


#pragma mark - DemoResponse
@implementation DemoResponse
{
    E_OBJECT_TYPE m_Type;
}

@dynamic payload;
@dynamic payloadType;
@dynamic customTag;
@dynamic headers;
@dynamic isBatch;

-(instancetype) initWithType:(E_OBJECT_TYPE)type
{
    self = [self init];
    if( self )
    {
        m_Type = type;
    }
    
    return self;
}

-(id<SODataEntitySet>) payload
{
    DemoEntitySet* result = [[DemoEntitySet alloc] initWithType:m_Type];
    return result;
}

@end

#pragma mark - DemoEntitySet
@implementation DemoEntitySet
{
    E_OBJECT_TYPE m_Type;
    NSMutableArray* m_EntitySet;
}

-(instancetype) initWithType:(E_OBJECT_TYPE)type
{
    self = [self init];
    if( self )
    {
        m_Type = type;
        m_EntitySet = [NSMutableArray array];
        for ( NSUInteger i = 0; i < 6; ++i )
        {
            DemoEntity* entity = [[DemoEntity alloc] initWithType:m_Type];
            if( entity )
            {
                [m_EntitySet addObject:entity];
            }
        }
    }
    
    return self;
}

-(NSMutableArray*) entities
{
    return m_EntitySet;
}

@end

#pragma mark - DemoEntity

static NSMutableDictionary* m_IndexForType;

// Account constants
static NSArray* accountProperties;
static NSArray* contactProperties;
static NSArray* appointmentProperties;
static NSArray* opportunityProperties;

@interface DemoEntity ()
@property (strong, nonatomic) NSMutableDictionary* properties;
@end

@implementation DemoEntity
{
    E_OBJECT_TYPE m_Type;
    NSString* m_TypeName;
    NSMutableDictionary* m_Properties;
}


-(id) valueForUndefinedKey:(NSString *)key
{
    NSLog(@"Property %@ does not exist in DemoEntity", key);
    return @"";
}

-(void) setValue:(id)value forUndefinedKey:(NSString *)key
{
    NSLog(@"Property %@ does not exist in DemoEntity", key);
}

+(void)initialize
{
    m_IndexForType = [NSMutableDictionary dictionaryWithCapacity:UNKNOWN];
    
    SODataPropertyDefault* p11 = [SODataPropertyDefault new];
    SODataPropertyDefault* p12 = [SODataPropertyDefault new];
    
    SODataPropertyDefault* p21 = [SODataPropertyDefault new];
    SODataPropertyDefault* p22 = [SODataPropertyDefault new];
    
    SODataPropertyDefault* p31 = [SODataPropertyDefault new];
    SODataPropertyDefault* p32 = [SODataPropertyDefault new];
    SODataPropertyDefault* p41 = [SODataPropertyDefault new];
    SODataPropertyDefault* p42 = [SODataPropertyDefault new];
    
    SODataPropertyDefault* p51 = [SODataPropertyDefault new];
    SODataPropertyDefault* p52 = [SODataPropertyDefault new];
    SODataPropertyDefault* p61 = [SODataPropertyDefault new];
    SODataPropertyDefault* p62 = [SODataPropertyDefault new];


    // List of account props
    p11.value = @"GolfByZip LLC";
    p12.value = @"Thea G. Traynor";
    p21.value = @"StopGrey Inc.";
    p22.value = @"Rachel A. Robinson";
    
    p31.value = @"FlowerTime";
    p32.value = @"Julian K. Russell";
    p41.value = @"Multi-Systems Merchant Services";
    p42.value = @"Steven J. Black";
    
    p51.value = @"Solution Realty";
    p52.value = @"Justin F. McCabe";
    p61.value = @"Dubrow's Cafeteria";
    p62.value = @"George R. Harris";
    
    accountProperties = @[@{ @"accountID": p11, @"fullName": p12 },
                          @{ @"accountID": p21, @"fullName": p22 },
                          @{ @"accountID": p31, @"fullName": p32 },
                          @{ @"accountID": p41, @"fullName": p42 },
                          @{ @"accountID": p51, @"fullName": p52 },
                          @{ @"accountID": p61, @"fullName": p62 }];

    // List of contact props
    p11 = [SODataPropertyDefault new];
    p12 = [SODataPropertyDefault new];
    p21 = [SODataPropertyDefault new];
    p22 = [SODataPropertyDefault new];
    
    p31 = [SODataPropertyDefault new];
    p32 = [SODataPropertyDefault new];
    p41 = [SODataPropertyDefault new];
    p42 = [SODataPropertyDefault new];
    
    p51 = [SODataPropertyDefault new];
    p52 = [SODataPropertyDefault new];
    p61 = [SODataPropertyDefault new];
    p62 = [SODataPropertyDefault new];
    
    p11.value = @"Wilbert C. Petty";
    p12.value = @"Crown Books";
    p21.value = @"Ann D. Batten";
    p22.value = @"Century House";

    p31.value = @"Melanie F. Quigley";
    p32.value = @"Monmax";
    p41.value = @"Mary T. Lord";
    p42.value = @"HomeBase";
    
    p51.value = @"William L. Scales";
    p52.value = @"Your Choices";
    p61.value = @"Thomas M. McCall";
    p62.value = @"Belle Lady";


    contactProperties = @[@{ @"fullName": p11, @"company": p12 },
                          @{ @"fullName": p21, @"company": p22 },
                          @{ @"fullName": p31, @"company": p32 },
                          @{ @"fullName": p41, @"company": p42 },
                          @{ @"fullName": p51, @"company": p52 },
                          @{ @"fullName": p61, @"company": p62 }];
    
    // List of appointment props
    p11 = [SODataPropertyDefault new];
    p12 = [SODataPropertyDefault new];
    p21 = [SODataPropertyDefault new];
    p22 = [SODataPropertyDefault new];
    
    p31 = [SODataPropertyDefault new];
    p32 = [SODataPropertyDefault new];
    p41 = [SODataPropertyDefault new];
    p42 = [SODataPropertyDefault new];
    
    p51 = [SODataPropertyDefault new];
    p52 = [SODataPropertyDefault new];
    p61 = [SODataPropertyDefault new];
    p62 = [SODataPropertyDefault new];

    
    p11.value = @"Call Apple";
    p12.value = [NSDate date];
    p21.value = @"Meet Hannah";
    p22.value = [NSDate date];
    
    p31.value = @"Dinner with John Marxley";
    p32.value = [NSDate dateWithTimeIntervalSinceNow:5*24*60*60];
    p41.value = @"Walk the dog";
    p42.value = [NSDate date];
    
    p51.value = @"Send invoice to Finn";
    p52.value = [NSDate dateWithTimeIntervalSinceNow:2*24*60*60];
    p61.value = @"Reserve table at Excalibur";
    p62.value = [NSDate dateWithTimeIntervalSinceNow:10*24*60*60];

    appointmentProperties = @[@{ @"Description": p11, @"FromDate": p12 },
                              @{ @"Description": p21, @"FromDate": p22 },
                              @{ @"Description": p31, @"FromDate": p32 },
                              @{ @"Description": p41, @"FromDate": p42 },
                              @{ @"Description": p51, @"FromDate": p52 },
                              @{ @"Description": p61, @"FromDate": p62 }];
    
    // List of opportunity props
    p11 = [SODataPropertyDefault new];
    p12 = [SODataPropertyDefault new];
    p21 = [SODataPropertyDefault new];
    p22 = [SODataPropertyDefault new];
    
    p31 = [SODataPropertyDefault new];
    p32 = [SODataPropertyDefault new];
    p41 = [SODataPropertyDefault new];
    p42 = [SODataPropertyDefault new];
    
    p51 = [SODataPropertyDefault new];
    p52 = [SODataPropertyDefault new];
    p61 = [SODataPropertyDefault new];
    p62 = [SODataPropertyDefault new];
    
    p11.value = @"Big Sale";
    p12.value = @"Starts at 8 AM";
    p21.value = @"Buy Apple stock";
    p22.value = @"now";
    
    p31.value = @"Send CV to Apple";
    p32.value = @"...at the end of the day";
    p41.value = @"Sell MS stock";
    p42.value = @"the quicker the better";
    
    p51.value = @"Call Sonja";
    p52.value = @"pending...";
    p61.value = @"Ask Jim about funding options";
    p62.value = @"ongoing";
    
    
    opportunityProperties = @[@{ @"description": p11, @"statusText": p12 },
                              @{ @"description": p21, @"statusText": p22 },
                              @{ @"description": p31, @"statusText": p32 },
                              @{ @"description": p41, @"statusText": p42 },
                              @{ @"description": p51, @"statusText": p52 },
                              @{ @"description": p61, @"statusText": p62 }];

}

-(instancetype) initWithType:(E_OBJECT_TYPE)type
{
    self = [self init];
    if( self )
    {
        m_Type = type;
        self.resourcePath = @"";
        self.editResourcePath = @"";
    
        switch (type)
        {
            case ACCOUNTS:
            {
                m_TypeName = kAccountsCollection;
            } break;
            case CONTACTS:
            {
                m_TypeName = kContactsCollection;
            } break;
            case APPOINTMENTS:
            {
                m_TypeName = kAppointmentsCollection;
            } break;
            case OPPORTUNITIES:
            {
                m_TypeName = kOpportunitiesCollection;
            } break;
            
            default:
            {
                m_TypeName = kUnknownCollection;
            }
        }
        
        [self populateProps];
    }
    
    return self;
}

-(NSString*) typeName
{
    return m_TypeName;
}

-(NSMutableDictionary*) properties
{
    return _properties;
}


/**
 *  Helper
 */
-(void) populateProps
{
    NSNumber* indexForType = (NSNumber*) m_IndexForType[ @(m_Type) ];
//    if( !indexForType )
//    {
//        indexForType = @0;
//    }
    
    switch( m_Type )
    {
        case ACCOUNTS:
        {
            if( indexForType.integerValue < (accountProperties.count - 1) )
            {
                m_IndexForType[@(m_Type)] = indexForType ? @(indexForType.integerValue + 1) : @0;
            }
            else
            {
                m_IndexForType[@(m_Type)] = @0;
            }
            
            indexForType = (NSNumber*) m_IndexForType[ @(m_Type) ];
            self.properties = accountProperties[indexForType.integerValue];
        } break;
        case CONTACTS:
        {
            if( indexForType.integerValue < (contactProperties.count - 1) )
            {
                m_IndexForType[@(m_Type)] = indexForType ? @(indexForType.integerValue + 1) : @0;
            }
            else
            {
                m_IndexForType[@(m_Type)] = @0;
            }
            
            indexForType = (NSNumber*) m_IndexForType[ @(m_Type) ];
            self.properties = contactProperties[indexForType.integerValue];
        } break;
        case APPOINTMENTS:
        {
            if( indexForType.integerValue < (appointmentProperties.count - 1) )
            {
                m_IndexForType[@(m_Type)] = indexForType ? @(indexForType.integerValue + 1) : @0;
            }
            else
            {
                m_IndexForType[@(m_Type)] = @0;
            }
            
            indexForType = (NSNumber*) m_IndexForType[ @(m_Type) ];
            self.properties = appointmentProperties[indexForType.integerValue];
        } break;
        case OPPORTUNITIES:
        {
            if( indexForType.integerValue < (opportunityProperties.count - 1) )
            {
                m_IndexForType[@(m_Type)] = indexForType ? @(indexForType.integerValue + 1) : @0;
            }
            else
            {
                m_IndexForType[@(m_Type)] = @0;
            }
            
            indexForType = (NSNumber*) m_IndexForType[ @(m_Type) ];
            self.properties = opportunityProperties[indexForType.integerValue];
        } break;
        default:
        {
            NSLog(@"Should not reach here");
        }
    }
}


@end
