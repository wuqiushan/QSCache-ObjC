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

- (nullable id<NSCoding>)getObjectWithKey:(NSString *)key {
    
    return nil;
}

/**
 设置数据
 1.存入内存(直接存对象)，存在先替换，不存在增加
 2.存入数据库或磁盘文件(存NSData)，存在先替换，不存在增加

 @param object 需要存储的对象
 @param key 需要存储的键
 */
- (void)setObject:(nullable id<NSCoding>)object withKey:(NSString *)key {
    
    // 存储对象
//    Person *person = [[Person alloc] init];
//    person.name = @"wuqiushan123";
//    person.age = 293;
//    [self.sqliteCache setObject:person withKey:@"person"];
//    id personR = [self.sqliteCache getObjectWithKey:@"person"];
    
//    NSDictionary *testdic = @{@"key1": @"value1", @"key2": @"value2"};
//    [self.sqliteCache setObject:@"12" withKey:@"testkey"];
//    [self.sqliteCache setObject:[NSNumber numberWithInt:1] withKey:@"testkey1"];
//    [self.sqliteCache setObject:testdic withKey:@"testdic"];
//
//    id test1 = [self.sqliteCache getObjectWithKey:@"testkey"];
//    id test2 = [self.sqliteCache getObjectWithKey:@"testkey1"];
//    id testdic1 = [self.sqliteCache getObjectWithKey:@"testdic"];
    
//    [self.memoryCache setObject:@"123" withKey:@"memory"];
//    [self.memoryCache setObject:@"123" withKey:@"memory"];
    
    NSData *testData = [NSKeyedArchiver archivedDataWithRootObject:@"234"];
    [self.memoryCache setObject:testData withKey:@"memoryData"];
    [self.memoryCache setObject:testData withKey:@"memoryData"];
    
    NSLog(@"3");
}

- (void)removeObjectWithKey:(NSString *)key {
    
}

- (void)removeAllObject {
    
}
@end
