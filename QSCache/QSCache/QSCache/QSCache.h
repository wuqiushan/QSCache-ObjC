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

+ (instancetype)sharedInstance;
//- (nullable id<NSCoding>)getValueForKey:(NSString *)key;
//- (void)setValue:(nullable id<NSCoding>)value key:(NSString *)key;
//- (void)removeValueForKey:(NSString *)key;
//- (void)removeAllValue;

- (nullable id<NSCoding>)getObjectWithKey:(NSString *)key;
- (void)setObject:(nullable id<NSCoding>)value withKey:(NSString *)key;
- (void)removeObjectWithKey:(NSString *)key;
- (void)removeAllObject;

@end

NS_ASSUME_NONNULL_END
