//
//  DCSocketManager.h
//  HttpBySocket
//
//  Created by boob on 2017/6/15.
//  Copyright © 2017年 YY.COM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCNetCache.h"
 
@interface DCSocketManager : NSObject

@property (nonatomic, strong)NSString  * serverHost;//IP或者域名

@property (nonatomic, assign)int         serverPort;//端口，https一般是443 * <#name#>;

@property (nonatomic, assign) BOOL       isHttps; 

- (void)getRequestUriName:(NSString *)uri Param:(NSDictionary *)params Complete:(CompletionHandler)handler;

- (void)postRequestUriName:(NSString *)uri Param:(NSDictionary *)params Complete:(CompletionHandler)handler;


@end
