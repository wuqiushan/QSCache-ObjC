//
//  QSCache.m
//  QSCache
//
//  Created by wuqiushan on 2019/10/17.
//  Copyright © 2019 wuqiushan3@163.com. All rights reserved.
//

#import "QSCache.h"
#import "QSMemoryCache.h"
#import "QSSqliteCache.h"
#import "Person.h"

@interface QSCache()

@property (nonatomic, strong) QSMemoryCache *memoryCache;
@property (nonatomic, strong) QSSqliteCache *sqliteCache;

@end

@implementation QSCache

+ (instancetype)sharedInstance {
    
    static QSCache *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[QSCache alloc] init];
        shared.memoryCache = [[QSMemoryCache alloc] init];
        shared.sqliteCache = [[QSSqliteCache alloc] init];
    });
    return shared;
}

/**
 获取存储的数据
 1.从内存取(存原对象)，有则显示，无则下一步
 2.从数据库或磁盘取(有数据存到NSData)，有则显示(存内存)，无则下一步

 @param key 待读取数据的键
 @return 返回读取数据
 */
- (nullable id<NSCoding>)getObjectWithKey:(NSString *)key {
    
    id result = [self.memoryCache getObjectWithKey:key];
    if (result) {
        return result;
    }
    result = [self.sqliteCache getObjectWithKey:key];
    [self.memoryCache setObject:result withKey:key];
    return result;
}

/**
 设置数据
 1.存入内存(存原对象)，存在先替换，不存在增加
 2.存入数据库或磁盘文件(存NSData)，存在先替换，不存在增加

 @param object 需要存储的对象
 @param key 需要存储的键
 */
- (void)setObject:(nullable id<NSCoding>)object withKey:(NSString *)key {
    
    [self.memoryCache setObject:object withKey:key];
    [self.sqliteCache setObject:object withKey:key];
}


/**
 删除指定数据

 @param key 待删除数据的键
 */
- (void)removeObjectWithKey:(NSString *)key {
    
    [self.memoryCache removeObjectWithKey:key];
    [self.sqliteCache removeObjectWithKey:key];
}


/**
 删除所有数据
 */
- (void)removeAllObject {
    
    [self.memoryCache removeAllObject];
    [self.sqliteCache removeAllObject];
}
@end
