//
//  QSSqliteCache.m
//  QSCache
//
//  Created by wuqiushan on 2019/10/17.
//  Copyright © 2019 wuqiushan3@163.com. All rights reserved.
//  说明：
//     1.利用 unarchiveObjectWithData和archivedDataWithRootObject会回调其NSCoding代理方法
//     从而达到对象与NSData之间的转化效果

#import "QSSqliteCache.h"
#import "QSLru.h"
#import "QSDatabase.h"
#import <objc/runtime.h>

@interface QSSqliteCache()

/** lru节点例： key:@"fileData"
              value:@{@"size":123, @"isSqlite":true}
    key:是查找值的重要依据，对应着数据库里的key字段或文件名 （因为小数据存sqlite, 大数据存文件）
    value: size -> 数据大小  isSqlite: true(存sqlite) false(存文件)
    1.此配置存储在数据库，在程序起动时，读取数据库并初始化
    2.程序结束时，存储在数据库里
 */
@property (nonatomic, strong) QSLru *qsLru;

/** 最大能够存储大小 */
@property (nonatomic, assign) long long maxStoreSize;

/** 已使内存大小 */
@property (nonatomic, assign) long long useStoreSize;

/** 文件管理对象 */
@property (nonatomic, strong) NSFileManager *fileManager;

/** Sqlite对象 */
@property (nonatomic, strong) QSDatabase *SqlDB;

@end

@implementation QSSqliteCache

#pragma mark - 初始化、文件操作
- (instancetype)init
{
    return [self initWithMaxDiskSize:0];
}

- (instancetype)initWithMaxDiskSize:(long long)size
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


/**
 获取key对应的对象
 1.从Lru里，读取其节点，(lru会把该节点排在头)
 2.把数据从sqlite或文件里取出
 3.把取出的NSData转化为对象，这里使用到NSCoding

 @param key 目标值的键
 @return 返回获取结果
 */
- (nullable id<NSCoding>)getObjectWithKey:(NSString *)key {

    NSData *resultData = [self.SqlDB queryDBWithKey:key];
    id<NSCoding> resultObject = [NSKeyedUnarchiver unarchiveObjectWithData:resultData];
    return resultObject;
}

// 新增之前，查看是否存在，存在更新，不存在就增加

/**
 存储对象到Sqlite或者文件里
 1.把非NSData的对象转化为NSData
 2.获取NSData长度、判断其大小 <100KB:存Sqlite 否则存：文件(文件名为key)
 3.存储新节点到Lru头部，总磁盘计算

 @param object 待存储的值
 @param key 待存储的键
 */
- (void)setObject:(nullable id<NSCoding>)object withKey:(NSString *)key {
    
    if (object) {
        NSData *objectData = [NSKeyedArchiver archivedDataWithRootObject:object];
        NSData *objectData1 = [NSKeyedArchiver archivedDataWithRootObject:objectData];
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


/**
 通过键删除指定的值 总磁盘计算
 1.从Lru里，读取(注意这个读取不能使排序方法)
 2.获取是sqlite还是文件，将其删除
 3.删除Lru里该节点

 @param key 待删除值的键
 */
- (void)removeObjectWithKey:(NSString *)key {
    
}


/**
 删除所有数据
 1.清理Lru
 2.清理sqlite
 3.清理文件
 */
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
