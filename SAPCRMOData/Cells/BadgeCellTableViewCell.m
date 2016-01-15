//
//  BadgeCellTableViewCell.m
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.09..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import "BadgeCellTableViewCell.h"

@implementation BadgeCellTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
    UIView* selectedBackgroundView = [UIView new];
    selectedBackgroundView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    self.selectedBackgroundView = selectedBackgroundView;
}

@end