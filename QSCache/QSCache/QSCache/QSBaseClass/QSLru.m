//
//  QSLru.m
//  QSWebImage
//
//  Created by apple on 2019/10/2.
//  Copyright © 2019年 wuqiushan. All rights reserved.
//
/**
 os_unfair_lock_t unfairLock;
 unfairLock = &(OS_UNFAIR_LOCK_INIT);
 os_unfair_lock_lock(unfairLock);
 os_unfair_lock_unlock(unfairLock);
 */

#import "QSLru.h"
#import "QSLruNode.h"
#import <os/lock.h>


@interface QSLru()


/**
 可变字典，用来存储所有的节点
 */
@property (nonatomic, strong) NSMutableDictionary *dic;

/** 是链表头部节点 */
@property (nonatomic, strong) QSLruNode *head;

/** 是链表尾部节点 */
@property (nonatomic, strong) QSLruNode *tail;

@end

os_unfair_lock unfairLock;

@implementation QSLru

- (instancetype)init
{
    self = [super init];
    if (self) {
        unfairLock = OS_UNFAIR_LOCK_INIT;
    }
    return self;
}

/**
 获取Lru的对应节点的值
 1.该节点存在，且不为头部节点时 先移除链表关联，移到头部重组关联 再返回其值
 2.该节点不存在，直接返回
 
 @param key 指定获取值的键
 @return 返回该节点的值
 */
- (id)get:(NSString *)key {
    
    QSLruNode *currNode = [self.dic objectForKey:key];
    if (currNode == nil) {
        return nil;
    }
    
    [self removeNode:currNode];
    [self addHead:currNode];
    return currNode.value;
}


/**
 往Lru增加节点，通过键和值
 1.如果元素key之前存在的话，去掉链表关联，从字典移除元素
 2.第1步完后，创建节点，把节点放在链表头部
 
 @param key 节点的键
 @param value 节点的值
 */
- (void)putKey:(NSString *)key value:(id)value {
    
    QSLruNode *currNode = [self.dic objectForKey:key];
    if (currNode != nil) {
        [self removeNode:currNode];
    }
    
    currNode = [[QSLruNode alloc] initWithKey:key value:value];
    [self addHead:currNode];
}

/**
 删除最旧的数据，即最长时间未使用的那个节点
 */
- (void)removeTail {
    [self removeNode:self.tail];
}

/**
 删除指定的节点

 @param key 节点的键
 */
- (void)removeWithKey:(NSString *)key {
    
    QSLruNode *node = [self.dic objectForKey:key];
    [self removeNode:node];
}

/**
 删除指定的节点
 1.如果此节点是头节点，
 2.如果此节点为中间节点，
 3.如果此节点为尾节点，

 @param node 将要删除的节点
 */
- (void)removeNode:(QSLruNode *)node {
    
    if (node == nil) { return ; }
    
    os_unfair_lock_lock(&unfairLock);
    // 要删除元素时，1个节点、2个节点、多个节点 三种情况
    if (node == self.head) {
        if (node == self.tail) {
            self.head = nil;
            self.tail = nil;
        }
        else if (node == self.tail.prev) {
            self.tail.prev = nil;
            self.head = self.tail;
        }
        else {
            self.head = node.next;
        }
    }
    else if (node == self.tail) {
        
        QSLruNode *prevNode = node.prev;
        prevNode.next = nil;
        self.tail = prevNode;
    }
    else {
        QSLruNode *prevNode = node.prev;
        QSLruNode *nextNode = node.next;
        prevNode.next = nextNode;
        nextNode.prev = prevNode;
    }
    [self.dic removeObjectForKey:node.key];
    os_unfair_lock_unlock(&unfairLock);
}


/**
 增加新节点要链表头
 1.当原来链表无任何节点时, 那边头节点和尾节点为同一个
 2.当原来链表有头节点时且为一个节点时，

 @param node 将要增加的节点
 */
- (void)addHead:(QSLruNode *)node {
    
    if (node == nil) { return ; }
    
    os_unfair_lock_lock(&unfairLock);
    
    node.prev = nil;
    node.next = nil;
    
    if (self.head == nil) {
        self.head = node;
        self.tail = node;
    }
    else if (self.head == self.tail) {
        self.head = node;
        self.head.next = self.tail;
        self.tail.prev = self.head;
    }
    else {
        QSLruNode *temp = self.head;
        self.head = node;
        self.head.next = temp;
        temp.prev = self.head;
    }
    [self.dic setObject:node forKey:node.key];
    
    os_unfair_lock_unlock(&unfairLock);
}

#pragma mark 获取头尾字段
- (NSString *)getHeadKey {
    if (self.head) {
        return self.head.key;
    }
    return nil;
}
- (id)getHeadValue {
    if (self.head) {
        return self.head.value;
    }
    return nil;
}

- (NSString *)getTailKey {
    if (self.tail) {
        return self.tail.key;
    }
    return nil;
}
- (id)getTailValue {
    if (self.tail) {
        return self.tail.value;
    }
    return nil;
}

- (NSDictionary *)getAllNode {
    return self.dic;
}

#pragma mark - 懒加载
- (NSMutableDictionary *)dic {
    if (!_dic) {
        _dic = [[NSMutableDictionary alloc] init];
    }
    return _dic;
}

@end
