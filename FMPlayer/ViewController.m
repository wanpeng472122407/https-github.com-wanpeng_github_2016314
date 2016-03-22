//
//  ViewController.m
//  FMPlayer
//
//  Created by Robin on 3/10/16.
//  Copyright © 2016 fastweb. All rights reserved.
//

#import "ViewController.h"

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
@property (nonatomic, assign) NSInteger proLnes;
@property (nonatomic, strong) NSMutableData *cutoff_Data;
@property (nonatomic, assign) BOOL isCutoff;
@property (nonatomic, assign) NSInteger nextDataCutLens;
@end

@implementation ViewController

- (void) initialization {
    _offset = 0;
    _results = [NSMutableArray array];
    _parse   = [[ParseFLV alloc] init];
    _dicFLVHeaderInfo = [[NSDictionary alloc] init];
    _tagArray = [[NSMutableArray alloc] init];
    _cutoff_Data = [[NSMutableData alloc] init];
    _proLnes = 0;
    _isCutoff = NO;
    _nextDataCutLens = 0;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
#if 0
    // Do any additional setup after loading the view, typically from a nib.
    [self initialization];
    NSURL *url = [NSURL URLWithString:@"http://httpflv.fastweb.com.cn.cloudcdn.net/"];

    self.manager = [[DWHTTPStreamSessionManager alloc] initWithBaseURL:url];
//    self.manager.itemSerializerProvider = [[DWHTTPJSONItemSerializerProvider alloc] init];
    self.manager.responseSerializer = [[DWDummyHTTPResponseSerializer alloc] init];
    
//    self.manager GET:@"" parameters:@{} data:^(NSURLSessionDataTask *task, id chunk) {
//
//    } success:<#^(NSURLSessionDataTask *task)success#> failure:<#^(NSURLSessionDataTask *task, NSError *error)failure#>
    
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
#endif
    
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
    if (_offset+15 > dataLens) {
        _isCutoff = YES;
        [_results removeObjectAtIndex:0];
        return;
    }
        while (_offset < dataLens) {
            if (_offset + 15 > dataLens) {
                _isCutoff = YES;
                NSData* subCutData = [_cutoff_Data subdataWithRange:NSMakeRange(cutoff_Point, dataLens - cutoff_Point)];
                _proLnes = dataLens - cutoff_Point;
                
                if (_cutoff_Data) {
                    _cutoff_Data = nil;
                    _cutoff_Data = [[NSMutableData alloc] initWithData:subCutData];
                    [_results removeObjectAtIndex:0];
                }
                return;
            }
            _offset = _offset + 4;
            NSData* subData = [_cutoff_Data subdataWithRange:NSMakeRange(_offset, 11)];
            NSDictionary *dic = [_parse parseFLVAloneTag:subData];
            NSLog(@"%@",dic);
            NSNumber *number = [dic valueForKey:@"DataSize"];
            NSInteger dataLenghts = [number integerValue];
            _proLnes = dataLenghts;
            [_tagArray addObject:dic];
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
        }
//        _offset = _offset + 4;
//        subData = [data subdataWithRange:NSMakeRange(_offset, 11)];
//        NSDictionary* dic = [_parse parseFLVAloneTag:subData];
//        if ([[dic valueForKey:@"TagType"] isEqualToString:@"SCRIPT"]) {
//            NSNumber * dataSize = [dic valueForKey:@"DataSize"];
//            NSInteger size = [dataSize integerValue];
//            _offset = _offset +11;
//            subData = [data subdataWithRange:NSMakeRange(_offset, size)];
//           [_parse parseFLVScriptInfo:subData lenght:size complete:^(NSDictionary *complete) {
//               _dicFLVScriptInfo = complete;
//            _offset = _offset + size;
//               NSLog(@"%@",_dicFLVScriptInfo);
//           } error:^(NSString *strError) {
//               NSLog(@"%@",strError);
//           }];
//        }
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
- (IBAction)parseFLVStart:(id)sender {
    UIButton *but = (UIButton *)sender;
    but.backgroundColor = [UIColor redColor];
}

-(void)dumpFLVInfo:(NSData *)data
{
//    转存数据
    
    Byte *bytes = (Byte *)[data bytes];
//    int avInfo = (char)bytes+4;
}

@end
