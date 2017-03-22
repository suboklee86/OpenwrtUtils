//
//  UBus.h
//  OpenwrtUtils
//
//  Created by 陈鼎星 on 2017/3/15.
//  Copyright © 2017年 陈鼎星. All rights reserved.
//

#ifndef Utils_h
#define Utils_h

#import <Foundation/Foundation.h>
#import "net/route.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#import <sys/sysctl.h>
#import <netinet/in.h>
#import <arpa/inet.h>

@interface Utils : NSObject{
@private

}

+ (id)sharedInstance;

- (NSString *)GetLocalIP;
- (NSString *)GetGetwayIP;


@end


#endif /* UBus_h */