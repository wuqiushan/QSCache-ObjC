//
//  Person.m
//  QSCache
//
//  Created by wuqiushan on 2019/10/18.
//  Copyright © 2019 wuqiushan3@163.com. All rights reserved.
//

#import "Person.h"

@interface Person() <NSCoding>
@end

@implementation Person


#pragma mark - NSCoding实现
- (void)encodeWithCoder:(NSCoder *)aCoder {

    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:[NSNumber numberWithInteger:self.age] forKey:@"age"];
    NSLog(@"--> encodeWithCoder");
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {

    NSLog(@"--> initWithCoder");
    if (self = [super init]) {
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.age = [[aDecoder decodeObjectForKey:@"age"] integerValue];
        NSLog(@"");
    }
    return self;
}

@end
