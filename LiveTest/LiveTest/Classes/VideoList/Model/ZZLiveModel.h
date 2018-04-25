//
//  ZZLiveModel.h
//  LiveTest
//
//  Created by 志方 on 17/3/23.
//  Copyright © 2017年 志方. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ZZCreatorModel;
@interface ZZLiveModel : NSObject
/** 直播流地址  */
@property(nonatomic, copy) NSString *stream_addr;
/** 关注人 */
@property(nonatomic, assign) NSUInteger online_users;
/** 城市 */
@property(nonatomic, copy) NSString *city;
/** 直播 */
@property(nonatomic, strong) ZZCreatorModel *creator;

@end
