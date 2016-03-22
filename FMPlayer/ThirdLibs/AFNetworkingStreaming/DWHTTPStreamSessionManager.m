//
//  DWHTTPStreamSessionManager.m
//  Demo
//

#import "DWHTTPStreamSessionManager.h"

@interface DWHTTPStreamMetadata : NSObject//数据块的基本单元

@property (nonatomic, copy, readonly) DWHTTPStreamChunkBlock chunkBlock;//数据块
@property (nonatomic, strong, readonly) DWHTTPStreamItemSerializer *itemSerializer;//接收数据块的类
@property (nonatomic, weak, readonly) NSURLSessionDataTask *dataTask;//会话的任务

@property (nonatomic, strong, readonly) dispatch_queue_t queue;

+ (instancetype)metadataWithChunkBlock:(DWHTTPStreamChunkBlock)chunkBlock
                        itemSerializer:(DWHTTPStreamItemSerializer *)itemSerializer
                              dataTask:(NSURLSessionDataTask *)dataTask;

@end

@interface DWHTTPStreamSessionManager () <DWHTTPStreamItemSerializationDelegate>

@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) NSMutableDictionary *streamMetadataKeyedByTaskIdentifier;

@end

@implementation DWHTTPStreamSessionManager

@synthesize streamMetadataKeyedByTaskIdentifier = _streamMetadataKeyedByTaskIdentifier;

- (id)initWithBaseURL:(NSURL *)url sessionConfiguration:(NSURLSessionConfiguration *)configuration {
    if ((self = [super initWithBaseURL:url sessionConfiguration:configuration])) {
        _streamMetadataKeyedByTaskIdentifier = [[NSMutableDictionary alloc] init];
        self.itemSerializerProvider = [[DWHTTPStreamItemSerializerProvider alloc] init];
        _lock = [[NSLock alloc] init];
        self.lock.name = @"deanWombourne.afnetworking-streaming.metadatalock";
    }
    return self;
}

#pragma mark - Stream metadata manipulation

- (void)addStreamMetadata:(DWHTTPStreamMetadata *)metadata withIdentifier:(NSUInteger)identifier {
//    将数据块加入到字典
    [self.lock lock];
    self.streamMetadataKeyedByTaskIdentifier[@(identifier)] = metadata;
    [self.lock unlock];
}

- (void)removeStreamMetadataWithIdentifier:(NSUInteger)identifier {
//    移除字典中的数据块
    [self.lock lock];
    [self.streamMetadataKeyedByTaskIdentifier removeObjectForKey:@(identifier)];
    [self.lock unlock];
}

- (DWHTTPStreamMetadata *)getStreamMetadataWithIdentifier:(NSUInteger)identifier {
//   从字典指定的可以中获取一个数据块对象
    [self.lock lock];
    id item = self.streamMetadataKeyedByTaskIdentifier[@(identifier)];
    [self.lock unlock];
    return item;
}

#pragma mark - Public API

- (NSURLSessionDataTask *)GET:(NSString *)URLString
                   parameters:(id)parameters
                         data:(DWHTTPStreamChunkBlock)chunkBlock
                      success:(DWHTTPStreamSuccessBlock)success
                      failure:(DWHTTPStreamFailureBlock)failure {
    
    // Get a default task
    NSURLSessionDataTask *task = [super GET:URLString
                                 parameters:parameters
                                    success:^(NSURLSessionDataTask *task, __unused id response) {
                                        if (success)
                                            success(task);//请求完成的的话回调到上层
                                    }
                                    failure:failure];//失败的话回调到上层
    
    // Create the item parser for this request
    DWHTTPStreamItemSerializer *itemSerializer = [self.itemSerializerProvider itemSerializerWithIdentifier:task.taskIdentifier delegate:self];

    // Create and store the metadata for this task
    DWHTTPStreamMetadata *metadata = [DWHTTPStreamMetadata metadataWithChunkBlock:chunkBlock
                                                                   itemSerializer:itemSerializer
                                                                         dataTask:task];
    [self addStreamMetadata:metadata withIdentifier:task.taskIdentifier];//将元数据对象插入到字典并打上标记
    
    // Return the task
    return task;
}

#pragma mark - URLSession delegate overrides
//从写父类的代理方法
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    // Don't call super if this is a stream we are handling - we don't want to accumulate the data
//    收到数据
    DWHTTPStreamMetadata *metadata = [self getStreamMetadataWithIdentifier:dataTask.taskIdentifier];
    if (metadata) {
        if (metadata.chunkBlock) {
            dispatch_async(metadata.queue, ^{
                [metadata.itemSerializer data:data forResponse:dataTask.response];
            });
        }
    } else {
        [super URLSession:session dataTask:dataTask didReceiveData:data];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
//    完成传输的任务
    DWHTTPStreamMetadata *metadata = [self getStreamMetadataWithIdentifier:task.taskIdentifier];
    if (metadata) {
        dispatch_async(metadata.queue, ^{
            [super URLSession:session task:task didCompleteWithError:error];

            [self removeStreamMetadataWithIdentifier:task.taskIdentifier];
        });
    } else {
        [super URLSession:session task:task didCompleteWithError:error];
    }
}

#pragma mark - DWHTTPItemSerializer delegate methods

- (void)itemSerializer:(DWHTTPStreamItemSerializer *)itemSerializer foundError:(NSError *)error {
//    分析数据出错 将指定的元数据删除
    DWHTTPStreamMetadata *metadata = [self getStreamMetadataWithIdentifier:itemSerializer.streamIdentifier];
    [metadata.dataTask cancel];
}

- (void)itemSerializer:(DWHTTPStreamItemSerializer *)itemSerializer foundItem:(id)item {
//    已经收到足够的数据来解析一个完整的项目
    DWHTTPStreamMetadata *metadata = [self getStreamMetadataWithIdentifier:itemSerializer.streamIdentifier];
    NSAssert(metadata != nil, @"Oops, found a data item for metadata that doesn't exist");
    dispatch_async(dispatch_get_main_queue(), ^{
        metadata.chunkBlock(metadata.dataTask, item);//回调到上层
    });
}

@end

@implementation DWHTTPStreamMetadata//元数据

+ (instancetype)metadataWithChunkBlock:(DWHTTPStreamChunkBlock)chunkBlock
                        itemSerializer:(DWHTTPStreamItemSerializer *)itemSerializer
                              dataTask:(NSURLSessionDataTask *)dataTask {
    DWHTTPStreamMetadata *m = [[DWHTTPStreamMetadata alloc] init];
    m->_chunkBlock = [chunkBlock copy];
    m->_itemSerializer = itemSerializer;
    m->_dataTask = dataTask;
    
    const char *queueName = [[NSString stringWithFormat:@"com.deanWombourne.afnetworking.items.%u", (unsigned int)m.itemSerializer.streamIdentifier] cStringUsingEncoding:NSASCIIStringEncoding];
    m->_queue = dispatch_queue_create(queueName, DISPATCH_QUEUE_SERIAL);//串行队列
    
    return m;//返回元数据对象
}

@end

