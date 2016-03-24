//
//  ViewController.m
//  FMPlayer
//
//  Created by Robin on 3/10/16.
//  Copyright © 2016 fastweb. All rights reserved.
//

#import "ViewController.h"
#import "FMTableViewCell.h"
#import "DWHTTPStreamSessionManager.h"
//#import "DWHTTPJSONItemSerializer.h"
#import "DWDummyHTTPResponseSerializer.h"
#import "ParseFLV.h"

@interface ViewController ()

@property (nonatomic, strong) DWHTTPStreamSessionManager *manager;//会话管理的类
@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic, assign) BOOL flvFoundFlag;
@property (nonatomic, assign) long totalReadedDataLength;
@property (nonatomic, strong) ParseFLV *parse;
@property (nonatomic, strong) NSDictionary* dicFLVHeaderInfo;
@property (nonatomic, strong) NSDictionary* dicFLVScriptInfo;
@property (nonatomic, assign) NSInteger offset;
@property (nonatomic, strong) NSMutableArray *tagArray;
@property (nonatomic, assign) BOOL isFirst;
@property (nonatomic, strong) NSMutableData *cutoff_Data;
@property (nonatomic, assign) BOOL isCutoff;
@property (nonatomic, assign) NSInteger nextDataCutLens;
@property (nonatomic, assign) NSUInteger numID;
@property (nonatomic, assign) BOOL isShowAudio;
@property (nonatomic, assign) BOOL isShowVideo;
@end

@implementation ViewController

- (void) initialization {
    _offset = 0;
    _results = [NSMutableArray array];
    _parse   = [[ParseFLV alloc] init];
    _dicFLVHeaderInfo = [[NSDictionary alloc] init];
    _tagArray = [[NSMutableArray alloc] init];
    _cutoff_Data = [[NSMutableData alloc] init];
    _isCutoff = NO;
    _nextDataCutLens = 0;
    _numID = 0;
    _isShowAudio = NO;
    _isShowVideo = NO;
}
- (void)viewDidLayoutSubviews {
    self.scrollView.contentSize = CGSizeMake(320, 450);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    [self initialization];
    self.labelURL.text = @"http://httpflv.fastweb.com.cn.cloudcdn.net/";
}

- (IBAction)parseFLVStart:(id)sender {
    
    UIButton* but = (UIButton *)sender;
    static BOOL start = YES;
    
    if (start) {
        
        start = NO;
        [but setTitle:@"取消" forState:UIControlStateNormal];
        
        NSString* str = self.labelURL.text;
        NSURL* url = [NSURL URLWithString:str];
        self.manager = [[DWHTTPStreamSessionManager alloc] initWithBaseURL:url];
        self.manager.responseSerializer = [[DWDummyHTTPResponseSerializer alloc] init];
    
        [self.manager GET:@"live_fw/wanpeng"
               parameters:@{}
                     data:^(NSURLSessionDataTask *task, id chunk) {
                         if ([chunk isKindOfClass:[NSData class]]) {
                             NSData *d = (NSData *)chunk;
                             if(_flvFoundFlag)
                             {
                                 [_results addObject:d];
                                 _totalReadedDataLength+=d.length;
                                 [self startParseTagInfo:_results];
                                 //                             NSLog(@"total readed data length: %zi", _totalReadedDataLength);
                             } else{
                                 int flvFlagLocation = [self findFLVStartFlag:d];//获取开始的标记位置
                                 if(flvFlagLocation>=0) {
                                     //                                 NSLog(@"FLV found, location is: %zi", flvFlagLocation);
                                     _flvFoundFlag = YES;
                                     NSData * subData = [d subdataWithRange:NSMakeRange(flvFlagLocation, d.length-flvFlagLocation)];
                                     [_results addObject:subData];
                                     _totalReadedDataLength = subData.length;
                                     [self startParseAV:_results];
                                     
                                 }
                             }
                         }
                     }
                  success:^(NSURLSessionDataTask *task) {
                      NSLog(@"Response complete");
                      self.title = @"Done";
                      
                  }
                  failure:^(NSURLSessionDataTask *task, NSError *error) {
                      self.title = @"Failed";
                      NSLog(@"%@",error);
                  }];
        
    } else {
        [self.manager.operationQueue cancelAllOperations];
        [but setTitle:@"开始" forState:UIControlStateNormal];
        start = YES;
    }
    
}

- (void)startParseTagInfo:(NSMutableArray *)flvDataArray {
    
    NSUInteger arrLenght = [flvDataArray count];
     if (arrLenght <=0) {
         return;
     }

    NSData* data = [flvDataArray objectAtIndex:0];
    
    NSInteger dataLens;;
    NSInteger cutoff_Point = 0;
    
    if (_isFirst) {
        _offset = 9;
        _isFirst = NO;
    } else {
        _offset = _nextDataCutLens + 11;
    }
    
    if (_isCutoff) {
        
        [_cutoff_Data appendData:data];
        dataLens = [_cutoff_Data length];
    } else {
        
        if (_cutoff_Data) {
            _cutoff_Data = nil;
            _cutoff_Data = [[NSMutableData alloc] initWithData:data];
            dataLens = [_cutoff_Data length];
        }
        
    }
    if (_offset+16 > dataLens) {
        _isCutoff = YES;
        [_results removeObjectAtIndex:0];
        return;
    }
        while (_offset < dataLens) {
            if (_offset + 16 > dataLens) {
                _isCutoff = YES;
                NSData* subCutData = [_cutoff_Data subdataWithRange:NSMakeRange(cutoff_Point, dataLens - cutoff_Point)];
                
                if (_cutoff_Data) {
                    _cutoff_Data = nil;
                    _cutoff_Data = [[NSMutableData alloc] initWithData:subCutData];
                    [_results removeObjectAtIndex:0];
                }
                return;
            }
            _offset = _offset + 4;
            NSData* subData = [_cutoff_Data subdataWithRange:NSMakeRange(_offset, 12)];
            NSDictionary *dic = [_parse parseFLVTagSpecificInfo:subData];
            
            if (dic == nil) {
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showUpdataFLVInfo:dic];
            });
            NSLog(@"%@",dic);
            NSNumber *number = [dic valueForKey:@"DataSize"];
            NSInteger dataLenghts = [number integerValue];

            cutoff_Point = _offset;
            _nextDataCutLens = dataLenghts;
            _offset = _offset + 11 + dataLenghts;
        }
        NSData* subCutData = [_cutoff_Data subdataWithRange:NSMakeRange(cutoff_Point, dataLens - cutoff_Point)];
       _isCutoff = YES;
        if (_cutoff_Data) {
            _cutoff_Data = nil;
            _cutoff_Data = [[NSMutableData alloc] initWithData:subCutData];
            [_results removeObjectAtIndex:0];
        }

}

- (void)startParseAV:(NSMutableArray *)flvDataArray {
    
    _isFirst = YES;
    NSUInteger arrayLenght = [flvDataArray count];
    if (arrayLenght > 0) {
        NSData *data = [flvDataArray objectAtIndex:0];
        NSData *subData = [data subdataWithRange:NSMakeRange(0, 3)];
        NSString *str = [[NSString alloc] initWithData:subData encoding:NSUTF8StringEncoding];
        if ([str isEqualToString:@"FLV"]) {
            _offset = 9;
            NSData* subFLVData = [data subdataWithRange:NSMakeRange(0, _offset)];
            _dicFLVHeaderInfo = [_parse parseFLVHeader:subFLVData];
            NSLog(@"%@",_dicFLVHeaderInfo);
            [self showHeadViewInfo:_dicFLVHeaderInfo];
        }
        _offset = _offset + 4;
        subData = [data subdataWithRange:NSMakeRange(_offset, 11)];
        NSDictionary* dic = [_parse parseFLVAloneTag:subData];
        if ([[dic valueForKey:@"TagType"] isEqualToString:@"SCRIPT"]) {
            NSNumber * dataSize = [dic valueForKey:@"DataSize"];
            NSInteger size = [dataSize integerValue];
            _offset = _offset +11;
            subData = [data subdataWithRange:NSMakeRange(_offset, size)];
           [_parse parseFLVScriptInfo:subData lenght:size complete:^(NSDictionary *complete) {
               _dicFLVScriptInfo = complete;
            _offset = _offset + size;
               NSLog(@"%@",_dicFLVScriptInfo);
           } error:^(NSString *strError) {
               NSLog(@"%@",strError);
           }];
        }
    }
}

-(int)findFLVStartFlag:(NSData *)data
{
    int i=0;
    while (i+3<data.length) {
        NSData * subData = [data subdataWithRange:NSMakeRange(i, 3)];
        NSString *aString = [[NSString alloc] initWithData:subData encoding:NSUTF8StringEncoding];
        if ([aString isEqualToString:@"FLV"]) {
            return i;
        }
        i++;
    }
    return -1;
}

- (void)showUpdataFLVInfo:(NSDictionary *)dic {
    
    if (_isShowVideo == NO || _isShowAudio == NO) {
        
        [self showTagHeadInfoView:dic];
    }
    
    [dic setValue:@(_numID) forKey:@"ID"];
    [_tagArray addObject:dic];
    [_showFLVTagView reloadData];
    if (_tagArray.count >50) {
        [_tagArray removeObjectAtIndex:0];
    }
    [self tableViewScrollToBottom];
    _numID ++;
}

- (void)tableViewScrollToBottom {
    
    if (_tagArray.count > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(_tagArray.count-1) inSection:0];
        [_showFLVTagView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }

}
- (void)showTagHeadInfoView:(NSDictionary *)dic {
    
    if ([[dic objectForKey:@"TagType"] isEqualToString:@"AUDIO"]) {
        
        _isShowAudio = YES;
        _audioBitTextFeild.text    = [dic objectForKey:   @"AudioBit"];
        NSLog(@"%@",_audioBitTextFeild.text);
        
        _audiokHzTextFeild.text    = [dic objectForKey:   @"AudiokHz"];
        NSLog(@"%@",_videoTypeTextFeild.text);
        
        _audioStereoTextFeild.text = [dic objectForKey:   @"AudioType"];
        NSLog(@"%@",_audioBitTextFeild.text);
        
        _audioTypeTextFeild.text   = [dic objectForKey:   @"AudioFormat"];
        NSLog(@"%@",_audioTypeTextFeild.text);
        
    } else if([[dic objectForKey:@"TagType"] isEqualToString:@"VIDEO"]) {
        
        _isShowVideo = YES;
        _videoTypeTextFeild.text   = [dic objectForKey:   @"VideoCoderID"];
        NSLog(@"%@",_videoTypeTextFeild.text);
    }


}
- (void)showHeadViewInfo:(NSDictionary *)dic {
    
    self.signatuerTextFeild.text = [dic valueForKey:@"Signature"];
    
    NSNumber * value = [dic valueForKey:@"version"];
    self.versionTextFeild.text  = [NSString stringWithFormat:@"0x %d",[value intValue]];
    
    value = [dic valueForKey:@"flags"];
    self.FalgTextFeild.text = [NSString stringWithFormat:@"0x %d",[value intValue]];
    
    value = [dic valueForKey:@"DataOffset"];
    self.DataSizeTextFeild.text  = [NSString stringWithFormat:@"0x %d",[value intValue]];
}
#if 0
-(void)dumpFLVInfo:(NSData *)data
{
//    转存数据
    
    Byte *bytes = (Byte *)[data bytes];
//    int avInfo = (char)bytes+4;
}
#endif

#pragma UITextFeildDelegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (textField.tag == 2000) {
        return  YES;
    }
    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *str = @"tableCell";
    FMTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:str];
    if (cell == nil) {
        NSArray* array = [[NSBundle mainBundle] loadNibNamed:@"FMTableViewCell" owner:nil options:nil];
        for (FMTableViewCell *arCel in array) {
            cell = arCel;
         }
        NSDictionary *dic = _tagArray[indexPath.row];
        cell.Number.text = [NSString stringWithFormat:@"%@",[dic valueForKey:@"ID"]];
        cell.Type.text   = [dic valueForKey:@"TagType"];
        cell.sizeData.text = [NSString stringWithFormat:@"%@",[dic valueForKey:@"DataSize"]];
        cell.StreamsID.text = [NSString stringWithFormat:@"%@",[dic valueForKey:@"StreamsID"]];
        cell.Timestamp.text = [NSString stringWithFormat:@"%@",[dic valueForKey:@"Timestamp"]];
    }
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_tagArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 20;
}


@end
