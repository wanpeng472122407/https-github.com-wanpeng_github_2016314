//
//  FMTableViewCell.h
//  FMPlayer
//
//  Created by 万敏 on 3/22/16.
//  Copyright © 2016 fastweb. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FMTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *Number;
@property (weak, nonatomic) IBOutlet UILabel *Type;
@property (weak, nonatomic) IBOutlet UILabel *sizeData;
@property (weak, nonatomic) IBOutlet UILabel *Timestamp;
@property (weak, nonatomic) IBOutlet UILabel *StreamsID;

@end
