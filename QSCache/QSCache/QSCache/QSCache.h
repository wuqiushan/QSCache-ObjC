//
//  QSCache.h
//  QSCache
//
//  Created by wuqiushan on 2019/10/17.
//  Copyright © 2019 wuqiushan3@163.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QSCache : NSObject

/** 因为管理使用情况所以用单例 */
+ (instancetype)sharedInstance;

/** 根据key获取值对象，访问后排在头节点 */
- (nullable id<NSCoding>)getObjectWithKey:(NSString *)key;

/** 设置key和value 之前存在先删除，再增加，访问后排在头节点*/
- (void)setObject:(nullable id<NSCoding>)object withKey:(NSString *)key;

/** 删除指定的数据  */
- (void)removeObjectWithKey:(NSString *)key;

/** 删除所有数据 */
- (void)removeAllObject;

@end

NS_ASSUME_NONNULL_END
