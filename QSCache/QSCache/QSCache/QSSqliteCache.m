//
//  QSSqliteCache.m
//  QSCache
//
//  Created by wuqiushan on 2019/10/17.
//  Copyright © 2019 wuqiushan3@163.com. All rights reserved.
//  说明：
//     1.利用 unarchiveObjectWithData和archivedDataWithRootObject会回调其NSCoding代理方法
//     从而达到对象与NSData之间的转化效果

#import <UIKit/UIKit.h>
#import "QSSqliteCache.h"
#import "QSLru.h"
#import "QSLruNode.h"
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

/** 最大允许存储大小 */
@property (nonatomic, assign) long long maxStoreSize;

/** 已使内存大小 */
@property (nonatomic, assign) long long useStoreSize;

/** 本模块存储文件的路径 */
@property (nonatomic, copy) NSString *storePath;

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
        
        // 初使化存储文件和Sqlite的路径
        NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        self.storePath = [docPath stringByAppendingPathComponent:@"QSCache"];
        
        if (![self.fileManager fileExistsAtPath:self.storePath]) {
            NSError *error = nil;
            [self.fileManager createDirectoryAtPath:self.storePath
                        withIntermediateDirectories:YES
                                         attributes:nil
                                              error:&error];
            if (error) {
                self.storePath = nil;
                NSAssert(self.storePath != nil, @"QSDiskCache路径创建失败");
            }
        }
        
        // 读取配置文件，初始 QSLru和useStoreSize 变量
        [self initQSLruAndSize];
        // 通知
        [self initNotify];
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

    NSData *resultData = nil;
    NSDictionary *valueDic = [self.qsLru get:key];
    if (!valueDic) { return nil; }
    BOOL isSqlite = [[valueDic objectForKey:@"isSqlite"] boolValue];
    if (isSqlite) {
        resultData = [self.SqlDB queryDBWithKey:key];
    }
    else {
        NSString *fullPath = [self.storePath stringByAppendingPathComponent:key];
        if ([self.fileManager fileExistsAtPath:fullPath]) {
            NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:fullPath];
            resultData = [handle readDataToEndOfFile];
            [handle closeFile];
        }
    }
    return [self unarchiveObjectWithData:resultData];
}

/**
 存储对象到Sqlite或者文件里 (只要key不为空，就存储)
 1.把对象转化为NSData，(如果是NSData不再转)
 2.获取NSData长度、判断其大小 <100KB:存Sqlite 否则存：文件(文件名为key)
 3.存储新节点到Lru头部
 4.总磁盘计算，如果磁盘大小溢出，就循环删除尾部数据，直到大小小于允许存储大小

 @param object 待存储的值
 @param key 待存储的键
 */
- (void)setObject:(nullable id<NSCoding>)object withKey:(NSString *)key {
    
    if ( (object == nil) || (key == nil) || ([key isEqualToString:@""]) ) {
        return ;
    }
    
    [self removeObjectWithKey:key];
    NSData *objectData = [self archivedDataWithRootObject:object];
    BOOL isSqlite = true;  /** 存储方式记录 */
    BOOL isSuccess = true; /** 存储是成功记录 */
    
    if (objectData.length < 102400) { // 测存文件可以设置 100k
        if ([self.SqlDB isExistKey:key]) {
            [self.SqlDB updateValue:objectData key:key];
        }
        else {
            [self.SqlDB insertValue:objectData key:key];
        }
    }
    else {
        isSqlite = false;
        if ([self.fileManager fileExistsAtPath:self.storePath]) {
            NSString *fullPath = [self.storePath stringByAppendingPathComponent:key];
            isSuccess = [self.fileManager createFileAtPath:fullPath contents:objectData attributes:nil];
            NSAssert(isSuccess == true, @"写入文件失败");
        }
    }
    
    if (isSuccess) {
        // Lru 存数据
        NSNumber *sizeNumber = [NSNumber numberWithInteger:objectData.length];
        NSNumber *isSqliteNumber = [NSNumber numberWithBool:isSqlite];
        NSDictionary *valueDic = @{@"size": sizeNumber, @"isSqlite": isSqliteNumber};
        [self.qsLru putKey:key value:valueDic];
        
        self.useStoreSize += objectData.length;
        while (self.useStoreSize > self.maxStoreSize) {
            NSString *tailKey = [self.qsLru getTailKey];
            [self removeObjectWithKey:tailKey];
        }
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
    
    QSLruNode *node = [[self.qsLru getAllNode] objectForKey:key];
    if (node == nil) { return ; }
    if (node.value == nil) { return ; }
    NSInteger fileSize = [[node.value objectForKey:@"size"] integerValue];
    BOOL isSqlite = [[node.value objectForKey:@"isSqlite"] boolValue];
    
    if (self.useStoreSize > fileSize) {
        self.useStoreSize -= fileSize;
    }
    else {
        self.useStoreSize = 0;
    }
    
    if (isSqlite) {
        [self.SqlDB deleteDBWithKey:key];
    }
    else {
        // 从文件里删除
        NSString *fullPath = [self.storePath stringByAppendingPathComponent:key];
        if ([self.fileManager fileExistsAtPath:fullPath]) {
            NSError *error = nil;
            [self.fileManager removeItemAtPath:fullPath error:&error];
            if (error) {
                NSLog(@"QSCache 删除 %@ 文件失败", fullPath);
            }
        }
    }
    
    [self.qsLru removeWithKey:key];
}


/**
 删除所有数据
 1.清理Lru
 2.清理sqlite
 3.清理文件
 */
- (void)removeAllObject {
    
    self.qsLru = nil;
    self.useStoreSize = 0;
    // 把整个目录删除，
    [self.SqlDB clearTable];
    
    NSArray *filePaths = [self.fileManager contentsOfDirectoryAtPath:self.storePath error:nil];
    for (NSString *element in filePaths) {
        
        if ([element isEqualToString:@".DS_Store"] ||
            [element isEqualToString:@"QSDB.sqlite"] ||
            [element isEqualToString:@"QSLru.plist"]) {
            continue ;
        }
        NSString *fullPath = [self.storePath stringByAppendingPathComponent:element];
        [self.fileManager removeItemAtPath:fullPath error:nil];
    }
}

#pragma mark - Lru存储和读出

/**
 程序进入非活动状态、后台、杀死等通知
 */
- (void)initNotify {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveQSLru) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveQSLru) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveQSLru) name:UIApplicationWillTerminateNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

/**
 当程序启动时，把上次QSLru记录读出来供本次使用
 {tail:key2, key1: { value: dic,  prev: keyn}, key2: { value: dic,  prev: key1}}
 1.把plist文件读取出来
 2.然后遍历，填充在QSLru变量中
 3.遍历所有文件，如果在QSLru中找不到就删除
 (注意不能用QSLruget类中的get方法，因为get会导致Lru链表重新排序，直接 类.dic 操作)
 4.计算当前使用存储大小
 */
- (void)initQSLruAndSize {
    
    NSString *QSLruPath = [self.storePath stringByAppendingPathComponent:@"QSLru.plist"];
    NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:QSLruPath];
    if (!dic) {
        self.useStoreSize = 0;
    }
    else {
        // 因为从后往前，所以最新的排在首节点
        NSString *tail = [dic objectForKey:@"tail"];
        while (tail != nil) {
            
            NSDictionary *contentDic = [dic objectForKey:tail];
            NSDictionary *valueDic = [contentDic objectForKey:@"value"];
            // 这里注意：字典的数据是对的，打印也对，但用xcode输出堆栈看不出来
            [self.qsLru putKey:tail value:valueDic];
            tail = [contentDic objectForKey:@"prev"];
        }
        
        NSError *error;
        NSArray<NSString *> *fileList = [self.fileManager contentsOfDirectoryAtPath:self.storePath error:&error];
        NSEnumerator *enumerator = [fileList objectEnumerator];
        id element = nil;
        while (element = [enumerator nextObject]) {
            NSString *elementStr = (NSString *)element;
            if ([element isEqualToString:@".DS_Store"] ||
                [element isEqualToString:@"QSDB.sqlite"] ||
                [element isEqualToString:@"QSLru.plist"]) {
                continue ;
            }
            
            if (![[self.qsLru getAllNode] objectForKey:elementStr]) {
                [self removeObjectWithKey:elementStr];
            }
        }
        
        self.useStoreSize = [self getDirectorySize];
    }
}

/**
 当程序退出时，才存储
 1.把遍历Lru转成字典如： {tail:key2, key1: { value: dic,  prev: keyn}, key2: { value: dic,  prev: key1}}
 2.删除之前存储的plist文件
 2.把转化后的字典用plist文件存储在对应的位置上
 
 */
- (void)saveQSLru {
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    if (!self.qsLru.getTailKey) {
        return ;
    }
    [dic setObject:self.qsLru.getTailKey forKey:@"tail"];
    [[self.qsLru getAllNode] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[QSLruNode class]]) {
            QSLruNode *node = (QSLruNode *)obj;
            NSMutableDictionary *subDic = [[NSMutableDictionary alloc] init];
            if (node.value) {
                [subDic setObject:node.value forKey:@"value"];
            }
            if (node.prev.key) {
                [subDic setObject:node.prev.key forKey:@"prev"];
            }
            [dic setObject:subDic forKey:node.key];
        }
    }];
    
    NSString *QSLruPath = [self.storePath stringByAppendingPathComponent:@"QSLru.plist"];
    if ([self.fileManager fileExistsAtPath:QSLruPath]) {
        NSError *error;
        [self.fileManager removeItemAtPath:QSLruPath error:&error];
        NSAssert(error == nil, @"保存配置QSLru时，删除之前的plist出错");
    }
    [dic writeToFile:QSLruPath atomically:YES];
}

#pragma mark - 文件大小
/**
 获取所有文件大小
 
 @return 返回所有文件大小值
 */
- (long long)getDirectorySize {
    return [self getFileSize:nil];
}


/**
 获取指定的文件大小
 
 @param name 文件名称
 @return 返回指定文件的大小
 */
- (long long)getFileSize:(NSString *)name {
    
    unsigned long long fileLength = 0;
    NSError *error;
    NSString *filePath = self.storePath;
    if ((name != nil) && (name.length > 0)) {
        filePath = [filePath stringByAppendingPathComponent:name];
    }
    if ([self.fileManager fileExistsAtPath:filePath]) {
        NSDictionary *dic =[self.fileManager attributesOfItemAtPath:self.storePath error:&error];
        if (error) {
            return 0;
        }
        else {
            // 这里有个问题，用方法读出来要远小于用mac直接查看的值
            fileLength = [dic fileSize];
            return fileLength * 1000 / 8;
        }
    }
    return 0;
}


#pragma mark - 包装 对象编码解码

/**
 解码，即把NSData解码成对象，会调用<NSCoding>协议的 initWithCoder 方法
 1.判断数据不是NSData类型，符合NSCoding返回该对象,不符合直接返回nil
 2.解码操作完成后，符合NSCoding返回该对象,不符合直接返回nil

 @param data 需要解码的数据
 @return 得到解码的对象
 */
- (nullable id<NSCoding>)unarchiveObjectWithData:(NSData *)data {
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (data && (![data isKindOfClass:[NSData class]])) {
        if ([data conformsToProtocol:@protocol(NSCoding)]) {
            return data;
        }
        return nil;
    }
    
    id result = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if ([result conformsToProtocol:@protocol(NSCoding)]) {
        return result;
    }
    return nil;
#pragma clang diagnostic pop
    
}

/**
 编码，把对象编码成NSData，会调用<NSCoding>协议的 encodeWithCoder 方法
 1.如果本身就是NSData数据了，就不需要再次编码了
 2.编码

 @param object 需要编码的对象
 @return 得到编码后的数据
 */
- (NSData *)archivedDataWithRootObject:(nullable id<NSCoding>)object {
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (object && [((id)object) isKindOfClass:[NSData class]]) {
        return (NSData *)object;
    }
    
    NSData *result = [NSKeyedArchiver archivedDataWithRootObject:object];
    return result;
#pragma clang diagnostic pop
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
        [_SqlDB createTable];
    }
    return _SqlDB;
}

@end
