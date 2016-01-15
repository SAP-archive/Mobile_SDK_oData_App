//
//  LogEntry.h
//  SAPCRMOData
//
//  Created by Nyisztor Karoly on 2014.11.05..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LogEntryTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *logMessageLabel;
@property (weak, nonatomic) IBOutlet UILabel *severityLabel;
@property (weak, nonatomic) IBOutlet UILabel *entryDateLabel;
@property (weak, nonatomic) IBOutlet UIView *severityBadgeView;

@end
