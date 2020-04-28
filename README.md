[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE) [![language](https://img.shields.io/badge/language-objective--c-green.svg)](1) 

### 概述
可存储任意类型的数据，当内存超出时采用LRU算法进行旧数据淘汰数。

### 使用方法
```Objective-C
- (void)testReadWriteRemove {
    
    // 先读 后写 再删 再读
    id read1 = [[QSCache sharedInstance] getObjectWithKey:@"testDic"];
    id read2 = [[QSCache sharedInstance] getObjectWithKey:@"testDic"];
    
    NSDictionary *testDic = @{@"abc": @"abcValue", @"123": @"123Value"};
    [[QSCache sharedInstance] setObject:testDic withKey:@"testDic"];
    [[QSCache sharedInstance] setObject:testDic withKey:@"testDic"];
}
```

### 许可证
所有源代码均根据MIT许可证进行许可。