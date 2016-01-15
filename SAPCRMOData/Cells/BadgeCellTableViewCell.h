//
//  BadgeCellTableViewCell.h
//  SAPCRMOData
//
//  Created by Károly Nyisztor on 2014.10.09..
//  Copyright (c) 2014 SAP-SE. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BadgeCellTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (strong, nonatomic) IBOutlet UITextField *badgeTextField;

@end
