//
//  parseFLV.m
//  parseFLVFormetInfo
//
//  Created by 万敏 on 3/19/16.
//  Copyright © 2016 万敏. All rights reserved.
//

#import "ParseFLV.h"

@interface ParseFLV ()

@property (nonatomic, strong) NSMutableDictionary *AmfDict1;
@property (nonatomic, strong) NSMutableDictionary *AmfDict2;
@property (nonatomic, strong) NSMutableArray      *scriptArray;
@end

@implementation ParseFLV

- (id)init {
    if (self = [super init]) {
        _flvHeaderBytes    = sizeof(FLV_HEADER);
        _flvTagHeaderBytes = sizeof(TAG_HEADER);
        _AmfDict1          = [[NSMutableDictionary alloc] init];
        _AmfDict2          = [[NSMutableDictionary alloc] init];
        _scriptArray       = [NSMutableArray array];
    }
    return self;
}

uint reverse_bytes (byte *p ,int c) {
    int r = 0;
    int i;
    for (i = 0; i < c; i++) {
        r |= ( *(p+i) << (((c-1)*8) -8*i));
    }
    return r;
}
//parse tag header type
-(NSString *) parseTagType:(byte)aCoder {
    
    switch (aCoder) {
        case TAG_TYPE_AUDIO:
            return @"AUDIO";
        case TAG_TYPE_VIDEO:
            return @"VIDEO";
        case TAG_TYPE_SCRIPT:
            return @"SCRIPT";
        default:
            return @"UNKNOWN";
    }
    return @"UNKNOWN";
    
}

//parse audio format
-(NSString *)parseAudioFormat:(int)aCoder {
    switch (aCoder) {
        case 0:
            return @"Linder PCM, platform endian";
        case 1:
            return @"ADPCM";
        case 2:
            return @"MP3";
        case 3:
            return @"Linear PCM, little endian";
        case 4:
            return @"Nellymoser 16-kHz mono";
        case 5:
            return @"Nellymoser 8-kHz mono";
        case 6:
            return @"Nellymoser";
        case 7:
            return @"G.711 A-law logarithmic PCM";
        case 8:
            return @"G.711 mu-law logarithmic PCM";
        case 9:
            return @"reserved";
        case 10:
            return @"AAC";
        case 11:
            return @"speex";
        case 14:
            return @"MP3 8-Khz";
        case 15:
            return @"Device-specific sound";
        default:
            return @"UNKNOWN";
            break;
    }
    return @"UNKNOWN";
    
}

//parse audio smapling rate
-(NSString *)parseAudiokHz:(int)aCoder {
    switch (aCoder) {
        case 0:
            return @"5.5-kHz";
        case 1:
            return @"11-kHz";
        case 2:
            return @"22-kHz";
        case 3:
            return @"44-kHz";
            
        default:
            return @"UNKNOWN";
            break;
    }
    
    return @"UNKNOWN";
}

//parse audio sampling length
-(NSString *)parseAudioBit:(int)aCoder {
    switch (aCoder) {
        case 0:
            return @"8 Bit";
        case 1:
            return @"16 Bit";
        default:
            return @"UNKNOWN";
    }
    return @"UNKNOWN";
}

//parse audio type
-(NSString *)parseAudioType:(int)aCoder {
    switch (aCoder) {
        case 0:
            return @"Mono";
        case 1:
            return @"Stereo";
        default:
            return @"UNKNOWN";
    }
    
    return @"UNKNOWN";
}

//parse video frame type
-(NSString *)parseVideoFrameType:(int)aCoder {
    switch (aCoder) {
        case 1:
            return @"key frame";
        case 2:
            return @"inter frame";
        case 3:
            return @"disposable inter frame";
        case 4:
            return @"generated keyframe";
        case 5:
            return @"video info/command frame";
        default:
            return @"UNKNOWN";
            break;
    }
    return @"UNKNOWN";
    
}

//parse video coder ID
-(NSString *)parseVideoCoderID:(int)aCoder {
    
    switch (aCoder) {
        case 1:
            return @"JPEG (currently unused)";
        case 2:
            return @"Sorenson H.263";
        case 3:
            return @"Screen video";
        case 4:
            return @"On2 VP6";
        case 5:
            return @"On2 VP6 with alpha channel";
        case 6:
            return @"Screen video version 2";
        case 7:
            return @"AVC";
        default:
            return @"UNKNOWN";
            break;
    }
    return @"UNKNOWN";
}

- (NSDictionary *)parseHeaderFLV:(NSData *)flvData {
    
    NSData* subData = [flvData subdataWithRange:NSMakeRange(0, 3)];
    NSString *strHeader = [[NSString alloc] initWithData:subData encoding:NSUTF8StringEncoding];
    if ([strHeader isEqualToString:@"FLV"] == NO) {
        return nil;
    }
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    FLV_HEADER pHeader;
    byte* pData = (byte *)[flvData bytes];
    memcpy(&pHeader, pData, _flvHeaderBytes);
    
    int version    = pHeader.Version;
    int flags      = pHeader.Flags;
    int DataOffset = reverse_bytes((byte *)&pHeader.DataOffset, sizeof(pHeader.DataOffset));
    
    [dic setObject:strHeader forKey:@"Signature"];
    [dic setObject:@(version) forKey:@"version"];
    [dic setObject:@(flags) forKey:@"flags"];
    [dic setObject:@(DataOffset) forKey:@"DataOffset"];
    return dic;
}

- (NSArray *)parseTagFLV:(NSData *)flvData {
    
    NSData* subData = [flvData subdataWithRange:NSMakeRange(0, 3)];
    NSString *strHeader = [[NSString alloc] initWithData:subData encoding:NSUTF8StringEncoding];
    if ([strHeader isEqualToString:@"FLV"] == NO) {
        return nil;
    }
    NSMutableArray *array = [NSMutableArray array];
    
    TAG_HEADER tagheader;
    NSUInteger dataLenght = [flvData length];
    NSUInteger offset = _flvHeaderBytes +4 ;
    byte* pData = (byte *)[flvData bytes];
    while (offset < dataLenght) {
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        memcpy(&tagheader, pData + offset , _flvTagHeaderBytes);
        int tagheader_datasize  = tagheader.DataSize[0]*65536 + tagheader.DataSize[1]*256 +tagheader.DataSize[2];
        int tagheader_timestamp = tagheader.Timestamp[0]*65536 + tagheader.Timestamp[1]*256 + tagheader.Timestamp[2];
        NSString *tagtype_str = [self parseTagType:tagheader.TagType];
        [dic setValue:tagtype_str forKey:@"TagType"];
        [dic setValue:@(tagheader_datasize) forKey:@"DataSize"];
        [dic setValue:@(tagheader_timestamp) forKey:@"Timestamp"];
        
        switch (tagheader.TagType) {
            case TAG_TYPE_AUDIO: {
                
                //fecth first byte of the audio data
                char tagdata_first_byte[1];
                if (offset + 12 > dataLenght) {
                    NSLog(@"data go beyond");
                    return array;
                }
                memcpy(&tagdata_first_byte, pData+offset + _flvTagHeaderBytes, 1);
                //fecth 1~4 bits
                int parseAudioCode = tagdata_first_byte[0] & 0xf0;
                parseAudioCode = parseAudioCode >> 4;
                NSString *audiotagformat = [self parseAudioFormat:parseAudioCode];
                [dic setValue:audiotagformat forKey:@"AudioFormat"];
                
                //fecth 5~6 bits
                parseAudioCode = tagdata_first_byte[0] & 0x0c;
                parseAudioCode = parseAudioCode >>2;
                NSString* audiokHz = [self parseAudiokHz:parseAudioCode];
                [dic setValue:audiokHz forKey:@"AudiokHz"];
                
                //fecth 7 bit
                parseAudioCode = tagdata_first_byte[0] & 0x02;
                parseAudioCode = parseAudioCode >> 1;
                NSString *audioBit = [self parseAudioBit:parseAudioCode];
                [dic setValue:audioBit forKey:@"AudioBit"];
                
                //fecth 8 bit
                parseAudioCode = tagdata_first_byte[0] & 0x01;
                NSString* audioType = [self parseAudioType:parseAudioCode];
                [dic setValue:audioType forKey:@"AudioType"];
                break;
            }
            case TAG_TYPE_VIDEO: {
                
                //fecth first byte of the  video data
                char tagdata_first_byte[1];
                if (offset + 12 > dataLenght) {
                    NSLog(@"data go beyond");
                    return array;
                }
                memcpy(&tagdata_first_byte, pData+offset + _flvTagHeaderBytes, 1);
                
                //fecth 1~4 bits
                int parseVideoCode = tagdata_first_byte[0] & 0xF0;
                parseVideoCode = parseVideoCode >> 4;
                NSString * videoFrameType = [self parseVideoFrameType:parseVideoCode];
                [dic setValue:videoFrameType forKey:@"videoFrameType"];
                
                //fecth 5~6 bits
                parseVideoCode = tagdata_first_byte[0] & 0x0F;
                NSString* parseVideoID = [self parseVideoCoderID:parseVideoCode];
                [dic setValue:parseVideoID forKey:@"VideoCoderID"];
                
                break;
            }
            case TAG_TYPE_SCRIPT: {
                break;
            }
            default:
                break;
        }
        [array addObject:dic];
        offset = offset + _flvTagHeaderBytes + 4 + tagheader_datasize ;
    }
    
    return array;
}


- (void)parseOnMetaData:(NSData *)flvdata complete:(void (^)(NSArray *))complete error:(void (^)(NSString * str))error {
    
    byte* pData = (byte *)[flvdata bytes];
    TAG_HEADER tagheader;
    NSUInteger offset = _flvHeaderBytes+4;
    NSUInteger dataSize = 0;
    memcpy(&tagheader, pData + offset , sizeof(TAG_HEADER));
    
    if (tagheader.TagType == TAG_TYPE_SCRIPT) {
        dataSize  = tagheader.DataSize[0]*65536 + tagheader.DataSize[1]*256 +tagheader.DataSize[2];
        byte dataMeta[dataSize];
        memset(&dataMeta, 0, sizeof(dataMeta));
        memcpy(&dataMeta, pData + offset+_flvTagHeaderBytes, dataSize);
        [self startParse:(byte *)&dataMeta dataSize:dataSize];
        NSMutableArray * array = [[NSMutableArray alloc] init];
        [array addObject:_AmfDict1];
        [array addObject:_AmfDict2];
        complete(array);
    } else {
        error(@"解析失败");
    }
}

- (void)startParse:(byte *)pData dataSize:(NSUInteger)dataSize {
    NSUInteger offset = 0;
    byte *p = NULL;
    p = pData;
    offset = [self parseAMF1Body:p];
    p += offset;
    while (p) {
        if (p - pData >= dataSize) {
            break;
        }
        offset = [self parseScriptType:p keyName:nil];
        p += offset;
    }
    
}

//parse AMF1 body
- (NSUInteger)parseAMF1Body:(byte *)pData {
    NSUInteger offset = 0;
    char amf1str[20];
    byte *p = pData;
    if (*p == 0x02) {
        p++;
        offset = [self getStringLen:p];
        p += 2;
        memset(amf1str, 0, sizeof(amf1str));
        strncpy(amf1str, (const char *)p, offset);
        NSString* str = [[NSString alloc] initWithCString:amf1str encoding:NSUTF8StringEncoding];
        [_AmfDict1 setValue:str forKey:@"AMF1"];
        p = p+offset;
    }
    return p - pData;
}

//parse AMF2 body
- (NSUInteger)parseScriptType:(byte *)pData keyName:(NSString *)key{
    
    NSUInteger offset = 0;
    byte *p = pData;
    byte string_output[512];
    unsigned long long number = 0;
    double double_number = 0.0;
    switch (*p) {
        case Number:
        {
            p++;
            number = [self getDoubleValue:p];
            double_number = [self transitionDataType:number];
            p += 8;
            if (double_number == 0.00) {
                break;
            }
            NSString *str = [NSString stringWithFormat:@"%.2f",double_number];
            [_AmfDict2 setValue:str forKey:key];
            break;
        }
        case boolean:
        {
            p++;
            BOOL type = [self getBoolValue:p];
            if (type) {
                [_AmfDict2 setValue:@"YES" forKey:key];
            } else {
                [_AmfDict2 setValue:@"NO" forKey:key];
            }
            p++;
            break;
        }
        case String:
        {
            p++;
            memset(string_output, 0, sizeof(string_output));
            offset = [self getStringLen:p];
            p += 2;
            strncpy((char *)string_output, (const char *)p, offset);
            NSString* str = [[NSString alloc] initWithCString:(const char *)string_output encoding:NSUTF8StringEncoding];
            [_AmfDict2 setValue:str forKey:key];
            p += offset;
            break;
        }
        case Object:
            p++;
            break;
            
        case MovieClip:
            p++;
            break;
            
        case Null:
            p++;
            break;
            
        case Undefined:
            p++;
            break;
            
        case Reference:
            p++;
            break;
            
        case EcmaArray:
            p++;
            offset = [self parseEcmaArray:p];
            p += offset;
            break;
            
        case ObjectEndMarker:
            p++;
            break;
            
        case StringArray:
            p++;
            break;
            
        case Date:
            p++;
            break;
            
        case LongString:
            p++;
            break;
            
        default:
            
            break;
    }
    return p - pData;
}

//parse ecma array Each element
- (NSUInteger)parseEcmaArray:(byte *)pData {
    NSUInteger ecma_array_len = 0;
    NSUInteger keyname_len = 0;
    byte keyname[32];
    byte *p = pData;
    int i = 0;
    
    ecma_array_len = [self getArrayLen:p];
    p += 4;
    
    for (i = 0; i < ecma_array_len; i++) {
        keyname_len = [self getStringLen:p];
        p += 2;
        memset(keyname, 0, sizeof(keyname));
        strncpy((char *)keyname, (const char *)p, keyname_len);
        NSString *strKey = [[NSString alloc] initWithCString:(const char *)keyname encoding:NSUTF8StringEncoding];
        p += keyname_len;
        p += [self parseScriptType:p keyName:strKey];
    }
    
//    Array end bit accounted for three bytes must be: 0X 00 00 09
    if (*p == 0 && *(p + 1) == 0 && *(p + 2) == 9) {
        p += 3;
    }
    return p - pData;
}

//get bool type value
- (BOOL)getBoolValue:(byte *)pData {
    return *pData;
}

//get double type value
- (NSUInteger)getDoubleValue:(byte *)pData {
    byte double_number[64];
    byte *p = double_number;
    
    memset(double_number, 0, sizeof(double_number));
    snprintf((char *)double_number, sizeof(double_number), "%0.2x%0.2x%0.2x%0.2x%0.2x%0.2x%0.2x%0.2x",
             *pData, *(pData + 1), *(pData + 2), *(pData + 3), *(pData + 4), *(pData + 5), *(pData + 6), *(pData + 7));
    
    return strtoull((char *)p, NULL, 16);

}

//get string type value
- (NSUInteger)getStringLen:(byte *)pData {
    byte *p = pData;
    byte len_char[8];
    NSUInteger len_int = 0;
    
    memset(len_char, 0, sizeof(len_char));
    snprintf((char *)len_char, sizeof(len_char), "0x%x%x", pData[0], pData[1]);
    p = len_char;
    
    len_int = strtoul((char *)p, NULL, 16);
    
    return len_int;
}

//get array number of element
- (NSUInteger)getArrayLen:(byte *)pData {
    char len_char[16];
    char *p = len_char;
    
    memset(len_char, 0, sizeof(len_char));
    snprintf(len_char, sizeof(len_char), "0x%x%x%x%x", pData[0], pData[1], pData[2], pData[3]);
    
    return strtoul(p, NULL, 16);
}

// uint64_t transition to double type
- (double)transitionDataType:(NSUInteger)number {
    union av_intfloat64 v;
    v.i = number;
    return v.f;

}

- (NSDictionary *)parseFLVAloneTag:(NSData *)data {
    
    if ([data length] != _flvTagHeaderBytes) {
        return nil;
    }
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    TAG_HEADER tagheader;
    byte* p =(byte *)[data bytes];
    memcpy(&tagheader, p, _flvTagHeaderBytes);
    
    NSString *tagtype_str = [self parseTagType:tagheader.TagType];
    if ([tagtype_str isEqualToString:@"UNKNOWN"]) {
        return nil;
    }

    int tagheader_datasize  = tagheader.DataSize[0]*65536 + tagheader.DataSize[1]*256 +tagheader.DataSize[2];
    int tagheader_timestamp = tagheader.Timestamp[0]*65536 + tagheader.Timestamp[1]*256 + tagheader.Timestamp[2];
    int tagheader_reservedID = tagheader.Reserved[0]*65536 + tagheader.Reserved[1]*256 +tagheader.Reserved[2];
    
    [dic setValue:tagtype_str             forKey:@"TagType"];
    [dic setValue:@(tagheader_datasize)   forKey:@"DataSize"];
    [dic setValue:@(tagheader_timestamp)  forKey:@"Timestamp"];
    [dic setValue:@(tagheader_reservedID) forKey:@"StreamsID"];
    
    return dic;
}

- (NSDictionary *)parseFLVHeader:(NSData *)data {
    
    NSData* subData = [data subdataWithRange:NSMakeRange(0, 3)];
    NSString *strHeader = [[NSString alloc] initWithData:subData encoding:NSUTF8StringEncoding];
    if ([data length] != 9 && [strHeader isEqualToString:@"FLV"] == NO) {
        return nil;
    }
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    FLV_HEADER pHeader;
    byte *p = (byte *)[data bytes];

    memcpy(&pHeader, p, _flvHeaderBytes);
    int version    = pHeader.Version;
    int flags      = pHeader.Flags;
    int DataOffset = reverse_bytes((byte *)&pHeader.DataOffset, sizeof(pHeader.DataOffset));
    [dic setObject:strHeader     forKey:@"Signature"];
    [dic setObject:@(version)    forKey:@"version"];
    [dic setObject:@(flags)      forKey:@"flags"];
    [dic setObject:@(DataOffset) forKey:@"DataOffset"];
    
    return dic;
}

- (void)parseFLVScriptInfo:(NSData *)data lenght:(NSUInteger)dataSize complete:(void (^)(NSDictionary *complete))complete error:(void (^)(NSString * strError))error
{
    
    NSUInteger offset = 0;
    char amf1str[20];
    byte *pData = (byte *)[data bytes];
    byte *p = pData;

    NSData *subData = [data subdataWithRange:NSMakeRange(dataSize - 3, 3)];
    byte* psubData  = (byte *)[subData bytes];
    if (*psubData != 0 || *(psubData+1) != 0 || *(psubData+2) != 9) {
        error(@"Data length error");
        return;
    }
    if (*p != 0x02) {
        error(@"Format error");
        return;
    }
        p++;
        offset = [self getStringLen:p];
        p += 2;
        memset(amf1str, 0, sizeof(amf1str));
        strncpy(amf1str, (const char *)p, offset);
        NSString* str = [[NSString alloc] initWithCString:amf1str encoding:NSUTF8StringEncoding];
    if ([str isEqualToString:@"onMetaData"] == NO) {
        error(@"Non script data");
        return;
    }
        p = p+offset;
    while (p) {
        if (p - pData >= dataSize) {
            break;
        }
        offset = [self parseScriptType:p keyName:nil];
        p += offset;
    }
        complete(_AmfDict2);
}

@end
