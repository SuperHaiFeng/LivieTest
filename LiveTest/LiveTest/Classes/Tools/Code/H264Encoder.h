//
//  H264Encoder.h
//  LiveTest
//
//  Created by 志方 on 17/3/27.
//  Copyright © 2017年 志方. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>

@protocol H264EncoderDelegate <NSObject>

-(void) gotSpsPps : (NSData *) sps pps : (NSData *) pps;
-(void) gotEncodedData : (NSData *) data isKeyFrame : (BOOL) isKeyFrame;

@end

@interface H264Encoder : NSObject

@property(nonatomic, weak) NSString *error;
@property(nonatomic, weak) id<H264EncoderDelegate> delegate;

-(void) initWithConfiguration;
-(void) start : (int) width height : (int) height;
-(void) initEncode : (int) width height : (int) height;
-(void) encode : (CMSampleBufferRef) sampleBuffer;
-(void) End;

@end
