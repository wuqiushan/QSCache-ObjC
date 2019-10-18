//
//  QSSqliteCache.m
//  QSCache
//
//  Created by wuqiushan on 2019/10/17.
//  Copyright © 2019 wuqiushan3@163.com. All rights reserved.
//

#import "QSSqliteCache.h"
#import "QSLru.h"
#import "QSDatabase.h"
#import <objc/runtime.h>

@interface QSSqliteCache()

@property (nonatomic, strong) QSLru *qsLru;
@property (nonatomic, assign) long long maxStoreSize;
@property (nonatomic, assign) long long useStoreSize;
@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) QSDatabase *SqlDB;

@end

@implementation QSSqliteCache

#pragma mark - 初始化、文件操作
- (instancetype)init
{
    return [self initWithMaxMemorySize:0];
}

- (instancetype)initWithMaxMemorySize:(long long)size
{
    self.maxStoreSize = size;
    self.useStoreSize = 0;
    
    self = [super init];
    if (self) {
        if (self.maxStoreSize == 0) {
            self.maxStoreSize = 500 * 1024;
        }
    }
    return self;
}

- (nullable id<NSCoding>)getObjectWithKey:(NSString *)key {

    NSData *resultData = [self.SqlDB queryDBWithKey:key];
    id<NSCoding> resultObject = [NSKeyedUnarchiver unarchiveObjectWithData:resultData];
    return resultObject;
}

// 新增之前，查看是否存在，存在更新，不存在就增加
- (void)setObject:(nullable id<NSCoding>)value withKey:(NSString *)key {
    
    NSObject *object = (NSObject *)value;
    if (object) {
        NSData *objectData = [NSKeyedArchiver archivedDataWithRootObject:object];
        if ([self.SqlDB isExistKey:key]) {
            [self.SqlDB updateValue:objectData key:key];
        }
        else {
            [self.SqlDB insertValue:objectData key:key];
        }
    }
    else {
        NSLog(@"setValue: key 这种情况没处理");
    }
}

- (void)removeObjectWithKey:(NSString *)key {
    
}

- (void)removeAllObject {
    
}


#pragma mark - 懒加载
- (NSFileManager *)fileManager {
    if (!_fileManager) {
        _fileManager = [NSFileManager defaultManager];
    }
    return _fileManager;
}

- (QSLru *)qsLru {
    if (!_qsLru) {
        _qsLru = [[QSLru alloc] init];
    }
    return _qsLru;
}

- (QSDatabase *)SqlDB {
    if (!_SqlDB) {
        _SqlDB = [[QSDatabase alloc] init];
        [_SqlDB create];
    }
    return _SqlDB;
}

@end
