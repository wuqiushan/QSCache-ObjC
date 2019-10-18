//
//  QSMemoryCache.h
//  QSWebImage
//
//  Created by apple on 2019/10/2.
//  Copyright © 2019年 wuqiushan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QSMemoryCache : NSObject

/** 初步化 */
- (instancetype)init;
/** 初步化并指定内存大小 */
- (instancetype)initWithMaxMemorySize:(long long)size;
- (void)writeFileWithName:(NSString *)name content:(NSData *)data;
- (NSData *)readFileWithName:(NSString *)name;



@end

NS_ASSUME_NONNULL_END
