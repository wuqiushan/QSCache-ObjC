//
//  ViewController.m
//  QSCache
//
//  Created by wuqiushan on 2019/10/17.
//  Copyright © 2019 wuqiushan3@163.com. All rights reserved.
//

#import "ViewController.h"
#import "QSDatabase.h"
#import "QSCache.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 测试删除操作
//    [self testRemove];
    
    // 测试读写删操作, 把存文件的判断大小弄小些可以测存文件
    [self testReadWriteRemove];
    
    // 测试NSData数据
//    [self testNSData];
    
    // 测试数据库
//    [self testSqlite];
}

- (void)testNSData {
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    id data1 = [[QSCache sharedInstance] getObjectWithKey:@"testNSData"];
    
    NSDictionary *testDic = @{@"abc": @"abcValue", @"123": @"123Value"};
    NSData *orgData = [NSKeyedArchiver archivedDataWithRootObject:testDic];
    
    [[QSCache sharedInstance] setObject:orgData withKey:@"testNSData"];
    id result = [[QSCache sharedInstance] getObjectWithKey:@"testNSData"];
    
    // 验证数据正确性，把读出来的数据，还原
    NSDictionary *resultDic = [NSKeyedUnarchiver unarchiveObjectWithData:orgData];
    NSLog(@"测试NSData %@ %@ %@", resultDic, data1, result);
#pragma clang diagnostic pop
}

- (void)testReadWriteRemove {
    
    // 先读 后写 再删 再读
    id read1 = [[QSCache sharedInstance] getObjectWithKey:@"testDic"];
    id read2 = [[QSCache sharedInstance] getObjectWithKey:@"testDic"];
    
    NSDictionary *testDic = @{@"abc": @"abcValue", @"123": @"123Value"};
    [[QSCache sharedInstance] setObject:testDic withKey:@"testDic"];
    [[QSCache sharedInstance] setObject:testDic withKey:@"testDic"];
    
    id resultDic = [[QSCache sharedInstance] getObjectWithKey:@"testDic"];
    
    NSLog(@"写入结束后读取 %@, %@, %@", read1, read2, resultDic);
    
    [[QSCache sharedInstance] removeObjectWithKey:@"testDic"];
    
    resultDic = [[QSCache sharedInstance] getObjectWithKey:@"testDic"];
    NSLog(@"删除结束后读取 %@", resultDic);
}

- (void)testRemove {
    
    [[QSCache sharedInstance] removeAllObject];
    [[QSCache sharedInstance] removeAllObject];
    
    [[QSCache sharedInstance] removeObjectWithKey:@"123"];
    [[QSCache sharedInstance] removeObjectWithKey:@"123"];
    NSLog(@"数据不存在时，测试删除操作");
}


// 测试数据库
- (void)testSqlite {
    NSString *name = @"wuqiushan";
    NSData *nameData = [name dataUsingEncoding:NSUTF8StringEncoding];
    
    QSDatabase *database = [[QSDatabase alloc] init];
    [database createTable];
    [database insertValue:nameData key:@"wuKey1"];
    
    NSString *changeStr = @"wuqiushan741tt";
    [database updateValue:[changeStr dataUsingEncoding:NSUTF8StringEncoding] key:@"wuKey1"];
    
    NSString *changeStr1 = @"123";
    [database updateValue:[changeStr1 dataUsingEncoding:NSUTF8StringEncoding] key:@"wuKey2"];
    
    [database deleteDBWithKey:@"wuKey1"];
    
    if (![database isExistKey:@"wuKey2"]) {
        [database insertValue:[changeStr1 dataUsingEncoding:NSUTF8StringEncoding] key:@"wuKey2"];
    }
    
    NSData *result = [database queryDBWithKey:@"wuKey1"];
    
    
    NSString *test = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    NSLog(@"最后结束 %@", test);
}
@end
