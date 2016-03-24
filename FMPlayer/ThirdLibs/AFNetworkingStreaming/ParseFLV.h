//
//  parseFLV.h
//  parseFLVFormetInfo
//
//  Created by 万敏 on 3/19/16.
//  Copyright © 2016 万敏. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TAG_TYPE_SCRIPT 18
#define TAG_TYPE_AUDIO  8
#define TAG_TYPE_VIDEO  9

typedef unsigned char byte;
typedef unsigned char  int4[4];
typedef unsigned char ui_24[3];

#pragma pack(1)

//struct FLV_HEADER
//       Signature[3]  file type 3 bytes FLV
//       Version       version   1 byte  0x01
//       Flage         file info 1 byte  1:express audio 4:express video 5:express audio and video
//       DataOffset    FLV size  4 bytes Generally 9

typedef struct {
    byte Signature[3];
    byte Version;
    byte Flags;
    int4 DataOffset;
} FLV_HEADER;

//struct TAG_HEADER
//        TagType      tag type  1 byte  8:express audio 9:express video 18:script
//        Datasize     data area lenghe  3 bytes
//        Tiemstamp    tiemstamp  3bytes For script always 0
//        TimestampExtend  TimestampExtend 1byte Rarely used
//        Reserved     StreamsID  3bytes always 0

typedef struct {
    byte  TagType;
    ui_24 DataSize;
    ui_24 Timestamp;
    byte  TimestampExtend;
    ui_24 Reserved;
} TAG_HEADER;
#pragma pack()

// enum script_data_type array data type
enum script_data_type {
    Number = 0,
    boolean,
    String,
    Object,
    MovieClip,
    Null,
    Undefined,
    Reference,
    EcmaArray,
    ObjectEndMarker,
    StringArray,
    Date,
    LongString,
};
typedef enum script_data_type script_type_t;

union av_intfloat64 {
    uint64_t i;
    double f;
};

@interface ParseFLV : NSObject

@property (nonatomic, readonly) NSUInteger flvHeaderBytes;
@property (nonatomic, readonly) NSUInteger flvTagHeaderBytes;


//Type of parsing tag  param：aCoder-Type code for tag（8 or 9 or 18） If failed return UNKNOWN
- (NSString *)parseTagType:(byte)aCoder;

//Parse audio format   param：aCoder-Audio format code （0 ~ 15）If failed return UNKNOWN
- (NSString *)parseAudioFormat:(int)aCoder;

//Sample rate of resolution audio  param：aCoder-Audio sampling rate code （0~3）If failed return UNKNOWN
- (NSString *)parseAudiokHz:(int)aCoder;

//Sample length of audio  param：aCoder-Sample length code (0 or 1) If failed return UNKNOWN
- (NSString *)parseAudioBit:(int)aCoder;

//Parse audio types param： aCoder-type code (0 or 1) If failed return UNKNOWN
- (NSString *)parseAudioType:(int)aCoder;

//Frame type of analytic video  param： aCoder-Frame type code （1~5）If failed return UNKNOWN
- (NSString *)parseVideoFrameType:(int)aCoder;

//Video coding format param： aCoder-Video format code （1~7）If failed return UNKNOWN
- (NSString *)parseVideoCoderID:(int)aCoder;


// functiion: parseHeaderFLVFile:
// Gets the header information for the bendflv file
// param:
//      flvdata:Data for a local flv file
// return: if successful Returns a dictionary containing information， contains 4 keys. otherwise return nil
//key:TagType     express type  audio/video/script
//key:DataSize    express tag data size
//key:Timestamp   express Timestamp
//key:StreamsID   always 0

- (NSDictionary *)parseHeaderFLVFile:(NSData *)flvdata;

// functiion:parseTagFLVFile:
// Gets the entire tag information for the local file
// param:
//      flvdata:Data for a local flv file
// return: if successful Returns an array of tag information that contains the entire file otherwise            return nil

- (NSArray *)parseTagFLVFile:(NSData *)flvdata;

//functiion:parseFLVFileMetaData: complete: error:
//Gets the script data for the local flv file
//param:
//      flvdata: Data for a local flv file
//     complete: Used to call a successful callback to an array of block
//        error: Block for calling failed to return error messages
//note:If you want to know key videocodecid  Please call parseVideoCoderID:
//     If you want to know key audiocodecid  Please call parseAudioFormat:

- (void)parseFLVFileMetaData:(NSData *)flvdata complete:(void (^)(NSArray *complete))complete error:(void (^)(NSString * strError))error;


- (NSDictionary *)parseFLVTagSpecificInfo:(NSData *)flvdata;

// functiion: parseFLVAloneTag: data;
// param:
//     data: Must be a complete tag length of 11 bytes.
//return: if successful Returns a dictionary containing information， contains 4 keys. otherwise return nil
//key:TagType     express type  audio/video/script
//key:DataSize    express tag data size
//key:Timestamp   express Timestamp
//key:StreamsID   always 0

- (NSDictionary *) parseFLVAloneTag:(NSData *)data;

// functiion: parseFLVHeader: data;
//
// param:
//     data: Must be the header of the flv file for 9 bytes of data
//return: if successful Returns a dictionary containing information， contains 4 keys. otherwise return nil
//key:Signature   Label for file type FLV
//key:Flage       file info   1:express audio 4:express video 5:express audio and video
//key:version     General is 0x01
//key:DataOffset   The length of the entire header, generally 9; greater than 9 indicates that there is an extension of information below

- (NSDictionary *) parseFLVHeader:(NSData *)data;

// function: parseFLVScriptInfo:lenght:complete:complete error:
// Gets the script information for the flv file
// param:
//       data: Must be the script information data area
//   dataSize: Must be the size of the data area of the script information：
//   complete: if successful Callback a dictionary containing the script information
//      error: if failure Callback a message that contains the error
//note:If you want to know key videocodecid  Please call parseVideoCoderID:
//     If you want to know key audiocodecid  Please call parseAudioFormat:
- (void) parseFLVScriptInfo:(NSData *)data lenght:(NSUInteger)dataSize complete:(void (^)(NSDictionary *complete))complete error:(void (^)(NSString * strError))error;


@end
