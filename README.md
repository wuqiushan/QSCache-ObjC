[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE) [![language](https://img.shields.io/badge/language-objective--c-green.svg)](1) 

### 概述
* [X] 可存储任意类型的数据，前提得实现NSCoding协议
* [X] 当内存超出时采用LRU算法进行旧数据淘汰
* [X] 自定义内存和磁盘缓存大小

### 使用示例
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


#### 设计思路(有兴趣可以看)
##### 类说明
* QSLruNode：双向链表节点(同是也是一个字典，这样设计是为了解决链表查询速度慢的问题)  
* QSLru：实现了LRU算法(最近最少使用)，把最久未使用的节点淘汰掉(即链表尾节点)
1.查询节点，节点存在且不为头节点，就把节点先断点前后节点，再添加到头节点
2.新增或修改节点，通过key查询字典元素，有先删除节点，再添加到头节点
3.删除节点，通过key查询字典元素，删除节点
* QSDatabase：基于iOS提供SQLite3接口写数据库持久化，增删改查
* QSMemoryCache：实现内存缓存逻辑，使用了QSLru实例实现(与磁盘的QSLru实例是分离的，因为各自己最大允许缓存大小是有限制的)，
* QSSqliteCache：实现磁盘缓存逻辑，使用了QSLru实例实现
* QSCache：缓存逻辑实现者，管理着QSMemoryCache和QSSqliteCache
##### 流程图
![image](https://github.com/wuqiushan/QSCache-ObjC/blob/master/磁盘缓存图.jpg)
![image](https://github.com/wuqiushan/QSCache-ObjC/blob/master/链表图.jpg)

##### 思路
1.初始化，内存的LRU创建为空，磁盘LRU通过读取上一次QSLru.plist文件转换
2.存储，有数据时，存入内存和磁盘各一份，数据>100k就以文件方式存磁盘，否则存SQLite3数据库
3.读出，优先读出内存，如果没有从磁盘读，磁盘有的话缓存到内存
4.删除，可根据key删除，也可以全部清除
5.退出，保存磁盘LRU配置，转换成QSLru.plist文件存储

