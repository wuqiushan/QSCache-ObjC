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

- (void)setObject:(nullable id<NSCoding>)value withKey:(NSString *)key {
    
    Person *person = [[Person alloc] init];
    person.name = @"wuqiushan123";
    person.age = 293;
    
//    NSDictionary *testdic = @{@"key1": @"value1", @"key2": @"value2"};
//    [self.sqliteCache setObject:@"12" withKey:@"testkey"];
//    [self.sqliteCache setObject:[NSNumber numberWithInt:1] withKey:@"testkey1"];
//    [self.sqliteCache setObject:testdic withKey:@"testdic"];
//
//    id test1 = [self.sqliteCache getObjectWithKey:@"testkey"];
//    id test2 = [self.sqliteCache getObjectWithKey:@"testkey1"];
//    id testdic1 = [self.sqliteCache getObjectWithKey:@"testdic"];
    
    [self.sqliteCache setObject:person withKey:@"person"];
    id personR = [self.sqliteCache getObjectWithKey:@"person"];
    
    NSLog(@"3");
}

- (void)removeObjectWithKey:(NSString *)key {
    
}

- (void)removeAllObject {
    
}
@end
