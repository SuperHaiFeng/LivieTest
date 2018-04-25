//
//  ZZUserItem.m
//  LiveTest
//
//  Created by 志方 on 17/3/30.
//  Copyright © 2017年 志方. All rights reserved.
//

#import "ZZUserItem.h"

@implementation ZZUserItem

-(void)setValue:(id)value forUndefinedKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        value = self.ID;
    }
}

@end
