//
//  FMTableViewCell.m
//  FMPlayer
//
//  Created by 万敏 on 3/22/16.
//  Copyright © 2016 fastweb. All rights reserved.
//


#import "FMTableViewCell.h"
@implementation FMTableViewCell

- (void)awakeFromNib {
    // Initialization code
    self.Number.layer.borderColor = [UIColor grayColor].CGColor;
    self.Number.layer.borderWidth = 1.0;
    
    self.Type.layer.borderColor = [UIColor grayColor].CGColor;
    self.Type.layer.borderWidth = 1.0;
    
    self.Timestamp.layer.borderColor = [UIColor grayColor].CGColor;
    self.Timestamp.layer.borderWidth = 1.0;
    
    self.sizeData.layer.borderColor = [UIColor grayColor].CGColor;
    self.sizeData.layer.borderWidth = 1.0;
    
    self.StreamsID.layer.borderColor = [UIColor grayColor].CGColor;
    self.StreamsID.layer.borderWidth = 1.0;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
