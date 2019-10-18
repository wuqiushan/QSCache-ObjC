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

- (nullable id<NSCoding>)getObjectWithKey:(NSString *)key;
- (void)setObject:(nullable id<NSCoding>)object withKey:(NSString *)key;
- (void)removeObjectWithKey:(NSString *)key;
- (void)removeAllObject;

@end

NS_ASSUME_NONNULL_END
