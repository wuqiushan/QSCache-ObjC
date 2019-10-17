//
//  QSCache.h
//  QSCache
//
//  Created by wuqiushan on 2019/10/17.
//  Copyright © 2019 wuqiushan3@163.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QSCache : NSObject

- (void)writeValue:(nullable id<NSCoding>)value key:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
