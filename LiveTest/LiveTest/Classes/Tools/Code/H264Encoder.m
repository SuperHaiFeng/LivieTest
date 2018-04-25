//
//  H264Encoder.m
//  LiveTest
//
//  Created by 志方 on 17/3/27.
//  Copyright © 2017年 志方. All rights reserved.
//

#import "H264Encoder.h"

@implementation H264Encoder
{
    NSString *yuvFile;
    VTCompressionSessionRef EncodingSession;
    dispatch_queue_t aQueue;
    CMFormatDescriptionRef format;
    CMSampleTimingInfo *timingInfo;
    BOOL initialized;
    int frameCount;
    NSData *sps;
    NSData *pps;
}
@synthesize error;

-(void)initWithConfiguration {
    EncodingSession = nil;
    initialized = true;
    aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    frameCount = 0;
    sps = NULL;
    pps = NULL;
}

void didCompressH264(void *outputCallbackRefCon,
                     void *sourceFrameRefCon,
                     OSStatus  status,
                     VTEncodeInfoFlags
                     infoFlags,
                     CMSampleBufferRef sampleBuffer) {
    
    if (status != 0 ) {
        return;
    }
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        NSLog(@"didCompressH264 数据没有准备好");
        return;
    }
    H264Encoder *encoder = (__bridge H264Encoder*)outputCallbackRefCon;
    
    //检查我们是否先有关键帧
    bool keyframe = !CFDictionaryContainsKey((CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0)), kCMSampleAttachmentKey_NotSync);
    
    if (keyframe) {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
         // CFDictionaryRef extensionDict = CMFormatDescriptionGetExtensions(format);
        //获取extensions
        //从扩展名获取字典与键“SampleDescriptionExtensionAtoms”
        //从dict中获取关键字“avcC”的值
        
        size_t sparameterSetSize, sparameterSetCount;
        const uint8_t *sparameterSet;
        OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format,
                                                                                 0,
                                                                                 &sparameterSet,
                                                                                 &sparameterSetSize,
                                                                                 &sparameterSetCount,
                                                                                 0);
        if (statusCode == noErr) {
            //找到sps，现在检查pps
            size_t pparameterSetSize, pparameterSetCount;
            const uint8_t *pparameterSet;
            OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format,
                                                                                     1,
                                                                                     &pparameterSet,
                                                                                     &pparameterSetSize,
                                                                                     &pparameterSetCount,
                                                                                     0);
            if (statusCode == noErr) {
                //找到pps
                encoder -> sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
                encoder -> pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
                if (encoder -> _delegate) {
                    [encoder -> _delegate gotSpsPps:encoder -> sps pps:encoder -> pps];
                }
            }
            
        }
    }
    
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer,
                                                         0,
                                                         &length,
                                                         &totalLength,
                                                         &dataPointer);
    if (statusCodeRet == noErr) {
        size_t bufferOffset = 0;
        static const int AVCCHeaderLength = 4;
        while (bufferOffset < totalLength - AVCCHeaderLength) {
            //读取NAL单位长度
            uint32_t NALUnitLength = 0;
            memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);
            
            //将Big-endian的长度值转换为Little-endian
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            
            NSData *data = [[NSData alloc] initWithBytes:(dataPointer + bufferOffset+ AVCCHeaderLength) length:NALUnitLength];
            [encoder -> _delegate gotEncodedData:data isKeyFrame:keyframe];
            
            //移动到块缓冲区中的下一个NAL单元
            bufferOffset += AVCCHeaderLength + NALUnitLength;
        }
    }
    
}

-(void)start:(int)width height:(int)height {
    
    int frameSize = (width * height * 1.5);
    
    if (!initialized) {
        NSLog(@"H264:Not initialized");
        error = @"H264:Not initialized";
        return;
    }
    
    dispatch_sync(aQueue, ^{
        //为了测试逻辑，让我们从文件中读取，然后将其发送到编码器来创建h264流
        
        //创建压缩会话
        OSStatus status = VTCompressionSessionCreate(NULL,
                                                     width,
                                                     height,
                                                     kCMVideoCodecType_H264,
                                                     NULL, NULL, NULL,
                                                     didCompressH264,
                                                     (__bridge void *)(self),
                                                     &EncodingSession);
        NSLog(@"H264: VTCompressionSessionCreate %d", (int)status);
        
        if (status != 0) {
            NSLog(@"H264: Unable to create a H264 session");
            error = @"H264: Unable to create a H264 session";
            
            return ;
        }
        
        //设置属性
        VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
        VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
        VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, 240);
        VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_High_AutoLevel);
        
        //告诉编码器开始编码
        VTCompressionSessionPrepareToEncodeFrames(EncodingSession);
        
        //从文件开始读取并将其复制到缓冲区
        
        //使用POSIX打开文件，因为这是一个测试应用程序
        int fd = open([yuvFile UTF8String], O_RDONLY);
        if (fd == -1) {
            NSLog(@"H264: Unable to open the file");
            error = @"H264: Unable to open the file";
            
            return ;
        }
        
        NSMutableData *theData = [[NSMutableData alloc] initWithLength:frameSize];
        NSUInteger actualBytes = frameSize;
        while (actualBytes > 0) {
            void *buffer = [theData mutableBytes];
            NSUInteger bufferSize = [theData length];
            
            actualBytes = read(fd, buffer, bufferSize);
            if (actualBytes < frameSize) {
                [theData setLength:actualBytes];
            }
            
            frameCount ++;
            
            //从此数据中创建一个CM块缓冲区
            CMBlockBufferRef BlockBuffer = NULL;
            OSStatus status = CMBlockBufferCreateWithMemoryBlock(NULL,
                                                                 buffer,
                                                                 actualBytes,
                                                                 kCFAllocatorNull,
                                                                 NULL,
                                                                 0,
                                                                 actualBytes,
                                                                 kCMBlockBufferAlwaysCopyDataFlag,
                                                                 &BlockBuffer);
            
            //检查错误
            if (status != noErr) {
                NSLog(@"H264: CMBlockBufferCreateWithMemoryBlock failed with %d", (int)status);
                error = @"H264: CMBlockBufferCreateWithMemoryBlock failed ";
                
                return ;
            }
            
            //创建一个CM样本缓冲区
            CMSampleBufferRef sampleBuffer = NULL;
            CMFormatDescriptionRef formatDescription;
            CMFormatDescriptionCreate(kCFAllocatorDefault,
                                      kCMMediaType_Video,
                                      'I420',
                                      NULL,
                                      &formatDescription);
            CMSampleTimingInfo sampleTimingInfo = {CMTimeMake(1, 300)};
            OSStatus statusCode = CMSampleBufferCreate(kCFAllocatorDefault,
                                                       BlockBuffer,
                                                       YES, NULL, NULL,
                                                       formatDescription,
                                                       1, 1,
                                                       &sampleTimingInfo,
                                                       0, NULL,
                                                       &sampleBuffer);
            
            //检查错误
            if (statusCode != noErr) {
                NSLog(@"H264: CMSampleBufferCreate failed with %d", (int)statusCode);
                error = @"H264: CMSampleBufferCreate failed ";
                
                return;
            }
            
            CFRelease(BlockBuffer);
            BlockBuffer = nil;
            
            //获取CV图像缓冲区
            CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
            
            //创建属性
            CMTime presentationTimeStamp = CMTimeMake(frameCount, 300);
//            CMTime duration = CMTimeMake(1, DURATION);
            VTEncodeInfoFlags flags;
            
            //通过它去编码
            statusCode = VTCompressionSessionEncodeFrame(EncodingSession,
                                                         imageBuffer,
                                                         presentationTimeStamp,
                                                         kCMTimeInvalid,
                                                         NULL, NULL, &flags);
            //检查错误
            if (statusCode != noErr) {
                NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode);
                error = @"H264: VTCompressionSessionEncodeFrame failed ";
                
                // 结束session
                VTCompressionSessionInvalidate(EncodingSession);
                CFRelease(EncodingSession);
                EncodingSession = NULL;
                error = NULL;
                return;
                
            }
        }
        
        //标记完成
        VTCompressionSessionCompleteFrames(EncodingSession, kCMTimeInvalid);
        
        //结束session
        VTCompressionSessionInvalidate(EncodingSession);
        CFRelease(EncodingSession);
        EncodingSession = NULL;
        error = NULL;
        close(fd);
        
    });
}

-(void)initEncode:(int)width height:(int)height {
    
    dispatch_sync(aQueue, ^{
        //为了测试逻辑，让我们从文件中读取，然后将其发送到编码器来创建h264流

        //创建压缩会话
        OSStatus status = VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, didCompressH264, (__bridge void *)(self),&EncodingSession);
        NSLog(@"H264: VTCompressionSessionCreate %d", (int)status);
        
        if (status != 0) {
            NSLog(@"H264: Unable to create a H264 session");
            error = @"H264: Unable to create a H264 session";
            
            return ;

        }
        
        //设置属性
        VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
        VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Main_AutoLevel);
        
        //告诉编码器开始编码
        VTCompressionSessionPrepareToEncodeFrames(EncodingSession);
    });
}

-(void)encode:(CMSampleBufferRef)sampleBuffer {
    
    dispatch_sync(aQueue, ^{
       
        frameCount ++;
        
        //获取CV图像缓冲区
        CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
        
        //创建属性
        CMTime presentationTimeStamp = CMTimeMake(frameCount, 1000);
        VTEncodeInfoFlags flags;
        
        //通过它去编码
        OSStatus statusCode = VTCompressionSessionEncodeFrame(EncodingSession,
                                                              imageBuffer,
                                                              presentationTimeStamp,
                                                              kCMTimeInvalid, NULL, NULL, &flags);
        
        //检查错误
        if (statusCode != noErr) {
            NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode);
            error = @"H264: VTCompressionSessionEncodeFrame failed ";
            
            //结束会话
            VTCompressionSessionInvalidate(EncodingSession);
            CFRelease(EncodingSession);
            EncodingSession = NULL;
            error = NULL;
            return;
        }
    });
}

-(void)End {
    //标记完成
    VTCompressionSessionCompleteFrames(EncodingSession, kCMTimeInvalid);
    
    //结束会话
    VTCompressionSessionInvalidate(EncodingSession);
    CFRelease(EncodingSession);
    EncodingSession = NULL;
    error = NULL;
}
@end
