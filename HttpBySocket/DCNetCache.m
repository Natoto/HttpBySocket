//
//  DCNetCache.m
//  HttpBySocket
//
//  Created by boob on 2017/6/15.
//  Copyright © 2017年 YY.COM. All rights reserved.
//

#import "DCNetCache.h"


@implementation DCNetCache

- (instancetype)initWithUri:(NSString *)uri Params:(NSDictionary *)params CompleteHandler:(CompletionHandler)handler{
    self = [super init];
    if (self) {
        _uri = uri;
        _params = params;
        _completeHandler = handler;
    }
    return self;
}


/**
 * 传入参数与url，拼接为一个带参数的url
 **/
+(NSString *) connectUrl:(NSDictionary *)params url:(NSString *) urlLink{
    // 初始化参数变量
    __block NSString *str = @"";
    NSString * newurlink = urlLink;
    // 快速遍历参数数组
    __block int idx = 0;
    [params enumerateKeysAndObjectsUsingBlock:^(NSString * key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        str = [str stringByAppendingString:key];
        str = [str stringByAppendingString:@"="];
        str = [str stringByAppendingFormat:@"%@",obj];
        str = [str stringByAppendingString:@"&"];
        idx ++;
    }];
    // 处理多余的&以及返回含参url
    if (str.length > 1) {
        // 去掉末尾的&
        str = [str substringToIndex:str.length - 1];
        // 返回含参url
        if (![[urlLink substringWithRange:NSMakeRange(urlLink.length-2, 1)] isEqualToString:@"?"]) {
            newurlink = [urlLink stringByAppendingString:@"?"];
        }
        newurlink = [newurlink stringByAppendingString:str];
        return newurlink;
    }
    return urlLink;
}
@end
