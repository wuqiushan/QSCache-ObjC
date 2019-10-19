//
//  QSDatabase.h
//  QSCache
//
//  Created by wuqiushan on 2019/10/17.
//  Copyright © 2019 wuqiushan3@163.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QSDatabase : NSObject

/** 初始化，指提存储路径 */
- (instancetype)initWithStoragePath:(NSString *)path;

#pragma mark 创建表
- (void)createTable;
#pragma mark 删除表
- (void)dropTable;
#pragma mark 清空表
- (void)clearTable;

#pragma mark 插入数据
- (void)insertValue:(NSData *)data key:(NSString *)key;
#pragma mark 删除数据
- (void)deleteDBWithKey:(NSString *)key;
#pragma mark 修改数据
- (void)updateValue:(NSData *)data key:(NSString *)key;
#pragma mark 查询数据
- (NSData *)queryDBWithKey: (NSString *)key;
#pragma mark 查询key是否存在
- (BOOL)isExistKey: (NSString *)key;

@end

NS_ASSUME_NONNULL_END
