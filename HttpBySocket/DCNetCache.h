//
//  DCNetCache.h
//  HttpBySocket
//
//  Created by boob on 2017/6/15.
//  Copyright © 2017年 YY.COM. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^CompletionHandler)(NSDictionary *response);
@interface DCNetCache : NSObject

@property (nonatomic, copy) NSString *uri;
@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, copy) CompletionHandler completeHandler;

- (instancetype)initWithUri:(NSString *)uri Params:(NSDictionary *)params CompleteHandler:(CompletionHandler)handler;

+(NSString *) connectUrl:(NSDictionary *)params url:(NSString *) urlLink;
@end
