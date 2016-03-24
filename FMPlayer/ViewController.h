//
//  ViewController.h
//  FMPlayer
//
//  Created by Robin on 3/10/16.
//  Copyright © 2016 fastweb. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *startParseFLVButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *labelURL;
@property (weak, nonatomic) IBOutlet UITableView *showFLVTagView;
@property (weak, nonatomic) IBOutlet UITextField *signatuerTextFeild;
@property (weak, nonatomic) IBOutlet UITextField *versionTextFeild;
@property (weak, nonatomic) IBOutlet UITextField *FalgTextFeild;
@property (weak, nonatomic) IBOutlet UITextField *DataSizeTextFeild;
@property (weak, nonatomic) IBOutlet UITextField *videoTypeTextFeild;
@property (weak, nonatomic) IBOutlet UITextField *audioTypeTextFeild;
@property (weak, nonatomic) IBOutlet UITextField *audiokHzTextFeild;
@property (weak, nonatomic) IBOutlet UITextField *audioBitTextFeild;
@property (weak, nonatomic) IBOutlet UITextField *audioStereoTextFeild;

@end

