//
//  QSSqliteCache.h
//  QSCache
//
//  Created by wuqiushan on 2019/10/17.
//  Copyright © 2019 wuqiushan3@163.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QSSqliteCache : NSObject

/** 初步化 */
- (instancetype)init;

/** 初步化并指定最大可以占用内存大小 */
- (instancetype)initWithMaxDiskSize:(long long)size;

/** 根据key获取值对象，访问后排在头节点 (已用内存大小 不变) */
- (nullable id<NSCoding>)getObjectWithKey:(NSString *)key;

/** 设置key和value 之前存在先删除，再增加，访问后排在头节点(已用内存大小 = 上次记录值 - 旧 + 新) */
- (void)setObject:(nullable id<NSCoding>)object withKey:(NSString *)key;

/** 根据key移除对应的节点 (已用内存大小 = 上次记录值 - 该节点) */
- (void)removeObjectWithKey:(NSString *)key;

/** 删除所有节点 (已用内存大小 = 0) */
- (void)removeAllObject;

@end

NS_ASSUME_NONNULL_END
