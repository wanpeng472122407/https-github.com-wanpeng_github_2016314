//
//  DWHTTPStreamItemSerialization.h
//  Pods
//
//  Created by NAP Sam on 16/06/2014.
//
//

#import "AFNetworking.h"

@class DWHTTPStreamItemSerializer;

@protocol DWHTTPStreamItemSerializationDelegate <NSObject>

/**
 * Call this method when enough data has been received to parse a complete item
 *
 * @param itemSerializer The serializer that has found the item
 * @param item The item that has been created
 */
- (void)itemSerializer:(DWHTTPStreamItemSerializer *)itemSerializer foundItem:(id)item;
//调用此方法时，已收到足够的数据来解析一个完整的项目
/**
 * Call this method when an error occurs during parsing of the data.
 *
 * @param itemSerializer The serializer that has found the item
 * @param error The error that occured
 */
- (void)itemSerializer:(DWHTTPStreamItemSerializer *)itemSerializer foundError:(NSError *)error;
//当在分析数据时出现错误时调用此方法。
@end

/**
 * Implement this to return your own custom subclass of DWHTTPStreamItemSerializer to parse different data formats
 */
@protocol DWHTTPStreamItemSerializerProvider <NSObject>

/**
 Return an initialized item serializer

 @param identifier An identifier for this item serializer
 @param delegate The delegate to recieve serialization events
 @return A subclass of DWHTTPStreamItemSerializer that is ready to receive data chunks
 */
- (DWHTTPStreamItemSerializer *)itemSerializerWithIdentifier:(NSUInteger)identifier delegate:(id<DWHTTPStreamItemSerializationDelegate>)delegate;
//实例化一个可接受数据块的类
@end

/**
 * Base class for item serializers. This class is the simplest implementation of the item serializer possible,
 * it simply returns the data back untouched to the delegate. The side effect of this is to allow a session
 * manager that isn't configured to have the defaults behaviour of just returning the data chunks to the block.
 */
@interface DWHTTPStreamItemSerializer : NSObject
//接收数据块的类
/**
 This is the designated initialiser
 */
- (id)initWithIdentifier:(NSUInteger)identifier delegate:(id<DWHTTPStreamItemSerializationDelegate>)delegate;

/**
 * Use the delegate property to pass items back to the stream session manager when they have been pased. It's also for passing back any errors that occur.
 */
@property (nonatomic, weak, readonly) id<DWHTTPStreamItemSerializationDelegate> delegate;

/**
 * This property stores an identifier for the task to tie together the input task and the item serializer efficiently.
 * You probably don't want to override this :)
 */
@property (nonatomic, assign, readonly) NSUInteger streamIdentifier;

/**
 * Implement this method to recieve data chunks passed from the data task. When you have enough to form a complete
 * item, pass it back in the delegate callback itemSerializer:foundItem:
 */
- (void)data:(NSData *)data forResponse:(NSURLResponse *)response;
//从数据任务中得到足够的数据 会调用代理方法
@end

/**
 * Default implementation of the item serializer provider protocol. This just provides the basic item serialiser.
 */
@interface DWHTTPStreamItemSerializerProvider : NSObject <DWHTTPStreamItemSerializerProvider>
//这个类接受了协议
@end
