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

//将NSArray转化为NSData类型 ：NSData *data = [NSKeyedArchiver archivedDataWithRootObject:Array];
//将NSData转化为NSArray类型 ：NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [[QSCache sharedInstance] setObject:nil withKey:@"k"];
    
//    [self testSqlite];
}


// 测试数据库
- (void)testSqlite {
    NSString *name = @"wuqiushan";
    NSData *nameData = [name dataUsingEncoding:NSUTF8StringEncoding];
    
    QSDatabase *database = [[QSDatabase alloc] init];
    [database create];
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
