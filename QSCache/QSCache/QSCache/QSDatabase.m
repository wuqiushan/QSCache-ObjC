//
//  QSDatabase.m
//  QSCache
//
//  Created by wuqiushan on 2019/10/17.
//  Copyright © 2019 wuqiushan3@163.com. All rights reserved.
//  使用模拟器时，每编译运行一次，沙盒路径会变化

#import "QSDatabase.h"
#import <sqlite3.h>

static sqlite3 *db = nil;

@implementation QSDatabase


#pragma mark 创建表
- (void)create {
    
    if (![self open]) {
        return ;
    }
    
    NSString *sql = @"CREATE TABLE IF NOT EXISTS QSTable( \
                    key text PRIMARY KEY NOT NULL, \
                    value blob, \
                    valueType varchar(20) \
                    )";
    int result = sqlite3_exec(db, sql.UTF8String, nil, nil, nil);
    if (result == SQLITE_OK) {
        NSLog(@"QSTable数据库表创建成功");
    }
    else {
        NSLog(@"QSTable数据库表创建失败");
    }
    
    [self close];
}

#pragma mark 插入数据
- (void)insertValue:(NSData *)data key:(NSString *)key {
    
    // key不能为空值
    if ((key == nil) || ([key isEqualToString:@""])) {
        return ;
    }
    if (![self open]) {
        return ;
    }
    
    NSString *sql = @"INSERT INTO QSTable(key, value, valueType) VALUES(?,?,?)";
    sqlite3_stmt *stmt = nil;
    int result = sqlite3_prepare(db, sql.UTF8String, -1, &stmt, nil);
    if (result == SQLITE_OK) {
        // 1,2,3 代表sql里的 ? 位置 从1开始
        sqlite3_bind_text(stmt, 1, key.UTF8String, -1, nil);
        sqlite3_bind_blob(stmt, 2, data.bytes, (int)data.length, nil);
        sqlite3_bind_text(stmt, 3, @"NSString".UTF8String, -1, nil);
        sqlite3_step(stmt);
    }
    sqlite3_finalize(stmt);
    
    [self close];
}

#pragma mark 删除数据
- (void)deleteDBWithKey:(NSString *)key {
    
    // key不能为空值
    if ((key == nil) || ([key isEqualToString:@""])) {
        return ;
    }
    if (![self open]) {
        return ;
    }
    
    NSString *sql = @"DELETE FROM QSTable WHERE key = ?";
    sqlite3_stmt *stmt = nil;
    int result = sqlite3_prepare(db, sql.UTF8String, -1, &stmt, nil);
    if (result == SQLITE_OK) {
        sqlite3_bind_text(stmt, 1, key.UTF8String, -1, nil);
        sqlite3_step(stmt);
    }
    sqlite3_finalize(stmt);
    [self close];
}

#pragma mark 修改数据
- (void)updateValue:(NSData *)data key:(NSString *)key {
    
    // key不能为空值
    if ((key == nil) || ([key isEqualToString:@""])) {
        return ;
    }
    if (![self open]) {
        return ;
    }
    
    NSString *sql = @"UPDATE QSTable SET value = ? WHERE key = ?";
    sqlite3_stmt *stmt = nil;
    int result = sqlite3_prepare(db, sql.UTF8String, -1, &stmt, nil);
    if (result == SQLITE_OK) {
        // 注意这里的 (int)data.length
        sqlite3_bind_blob(stmt, 1, data.bytes, (int)data.length, nil);
        sqlite3_bind_text(stmt, 2, key.UTF8String, -1, nil);
        sqlite3_step(stmt);
    }
    sqlite3_finalize(stmt);
    
    [self close];
}

#pragma mark 查询数据
- (NSData *)queryDBWithKey: (NSString *)key {
    
    // key不能为空值
    if ((key == nil) || ([key isEqualToString:@""])) {
        return nil;
    }
    if (![self open]) {
        return nil;
    }
    
    // 注意这里要是 * 时，取的时候才有东西, select 某个字段时，取结果下标为0
    NSString *sql = @"SELECT value FROM QSTable WHERE key = ?";
    NSData *resultData = nil;
    sqlite3_stmt *stmt = nil;
    int result = sqlite3_prepare(db, sql.UTF8String, -1, &stmt, nil);
    if (result == SQLITE_OK) {
        sqlite3_bind_text(stmt, 1, key.UTF8String, -1, nil);
        result = sqlite3_step(stmt);
        if (result == SQLITE_ROW) {
            // select 某个字段时，获取结果从0开始， 如果是select * 时，从1开始，返回下标对应的列
            //const char*op = sqlite3_column_text(stmt,0);
            const char *valueBytes = sqlite3_column_blob(stmt, 0);
            //int size = sqlite3_column_bytes(stmt,0); //获取长度
            resultData = [NSData dataWithBytes:valueBytes length:strlen(valueBytes)];
        }
    }
    sqlite3_finalize(stmt);
    [self close];
    
    return resultData;
}

#pragma mark 是否存key

/**
 查询key是否存数据库

 @param key 需要查询的key字符串
 @return 返回YES:存在  NO:不存在
 */
- (BOOL)isExistKey: (NSString *)key {
    // key不能为空值
    if ((key == nil) || ([key isEqualToString:@""])) {
        return NO;
    }
    if (![self open]) {
        return NO;
    }
    
    // 注意这里要是 * 时，取的时候才有东西, select 某个字段时，取结果下标为0
    NSString *sql = @"SELECT key FROM QSTable WHERE key = ?";
    BOOL resultData = NO;
    sqlite3_stmt *stmt = nil;
    int result = sqlite3_prepare(db, sql.UTF8String, -1, &stmt, nil);
    if (result == SQLITE_OK) {
        sqlite3_bind_text(stmt, 1, key.UTF8String, -1, nil);
        result = sqlite3_step(stmt);
        if (result == SQLITE_ROW) {
            resultData = YES;
        }
    }
    sqlite3_finalize(stmt);
    [self close];
    
    return resultData;
}


#pragma mark 打开数据库 保存沙盒的 ../Documents/QSCache/QSDB.sqlite
- (sqlite3 *)open {
    
    /** 打开了就不再打开 */
    if (db) { return db; }
    
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *modulePath = [docPath stringByAppendingPathComponent:@"QSCache"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:modulePath]) {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:modulePath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error];
        if (error) {
            NSLog(@"数据库路径创建失败");
            return nil;
        }
        else {
            NSLog(@"=== 数据库存储目录: %@", modulePath);
        }
    }
    
    NSString *storagePath = [modulePath stringByAppendingPathComponent:@"QSDB.sqlite"];
    sqlite3_open(storagePath.UTF8String, &db);
    
    return db;
}

#pragma mark 关闭数据库
- (void)close {
    
    if (db) {
        sqlite3_close(db);
        db = nil;
    }
}



@end
