//
//  AACEncoder.h
//  LiveTest
//
//  Created by 志方 on 17/3/27.
//  Copyright © 2017年 志方. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface AACEncoder : NSObject

@property(nonatomic) dispatch_queue_t encoderQueue;
@property(nonatomic) dispatch_queue_t callbackQueue;

-(void) encodeSampleBuffer : (CMSampleBufferRef) sampleBuffer
           completionBlock : (void (^) (NSData *encodedData, NSError *error)) completionBlock;

@end
