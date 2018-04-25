//
//  AACEncoder.m
//  LiveTest
//
//  Created by 志方 on 17/3/27.
//  Copyright © 2017年 志方. All rights reserved.
//

#import "AACEncoder.h"

@interface AACEncoder()

@property(nonatomic) AudioConverterRef audioConverter;
@property(nonatomic) uint8_t *aacBuffer;
@property(nonatomic) UInt32 aacBufferSize;
@property(nonatomic) char *pcmBuffer;
@property(nonatomic) size_t pcmBufferSize;

@end

@implementation AACEncoder

-(void)dealloc {
    AudioConverterDispose(_audioConverter);
    free(_aacBuffer);
}

-(id) init {
    if (self = [super init]) {
        _encoderQueue = dispatch_queue_create("AAC Encoder Queue", DISPATCH_QUEUE_SERIAL);
        _callbackQueue = dispatch_queue_create("AAC Encoder Callback Queue", DISPATCH_QUEUE_SERIAL);
        _audioConverter = NULL;
        _pcmBufferSize = 0;
        _pcmBuffer = NULL;
        _aacBufferSize = 1024;
        _aacBuffer = malloc(_aacBufferSize * sizeof(uint8_t));
        memset(_aacBuffer, 0, _aacBufferSize);
    }
    return self;
}

-(void) setupEncoderFromSampleBuffer : (CMSampleBufferRef) sampleBuffer {
    AudioStreamBasicDescription inAudioStreamBasicDescription = *CMAudioFormatDescriptionGetStreamBasicDescription((CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(sampleBuffer));
    
    //始终将新的音频流基本描述结构的字段初始化为零，如下所示：..
    AudioStreamBasicDescription outAudioStreamBasicDescription = {0};
    
    //当流以正常速度播放时，流中数据的每秒帧数。对于压缩格式，此字段指示等效解压缩数据的每秒帧数。 mSampleRate字段必须非零，除非在支持的格式列表中使用此结构（请参阅“kAudioStreamAnyRate”）。
    outAudioStreamBasicDescription.mSampleRate = inAudioStreamBasicDescription.mSampleRate;
    
    //kAudioFormatMPEG4AAC_HE不工作。找不到`AudioClassDescription`。 `mFormatFlags`设置为0
    outAudioStreamBasicDescription.mFormatID = kAudioFormatMPEG4AAC;
    
    //格式特定的标志来指定格式的详细信息。设置为0表示无格式标志。请参阅适用于每种格式的标志的“音频数据格式标识符”。
    outAudioStreamBasicDescription.mFormatFlags = kMPEG4Object_AAC_LC;
    
    //音频数据包中的字节数。要指示可变包大小，请将此字段设置为0.对于使用变量包大小的格式，请使用AudioStreamPacketDescription结构指定每个数据包的大小。
    outAudioStreamBasicDescription.mBytesPerPacket = 0;
    
    //音频数据包中的帧数。对于未压缩音频，值为1.对于可变比特率格式，该值为较大的固定数字，例如AAC为1024。对于每个数据包可变数量帧的格式（例如Ogg Vorbis），将此字段设置为0。
    outAudioStreamBasicDescription.mFramesPerPacket = 1024;
    
    //音频缓冲区中从一帧开始到下一帧开始的字节数。对于压缩格式，将此字段设置为0。 ...
    outAudioStreamBasicDescription.mBytesPerFrame = 0;
    
    //每帧音频数据中的通道数。此值必须为非零。
    outAudioStreamBasicDescription.mChannelsPerFrame = 1;
    
    //对于压缩格式，将此字段设置为0。
    outAudioStreamBasicDescription.mBitsPerChannel = 0;
    
    //将结构粘贴到强制平均8字节对齐。必须设置为0。
    outAudioStreamBasicDescription.mReserved = 0;
    
    AudioClassDescription *description = [self getAudioClassDescriptionWithType:kAudioFormatMPEG4AAC
                                                               fromManufacturer:kAppleSoftwareAudioCodecManufacturer];
    
    OSStatus status = AudioConverterNewSpecific(&inAudioStreamBasicDescription,
                                                &outAudioStreamBasicDescription,
                                                1, description, &_audioConverter);
    
    if (status != 0) {
        NSLog(@"setup converter: %d", (int)status);
    }
    
}

-(AudioClassDescription *) getAudioClassDescriptionWithType : (UInt32) type
                                           fromManufacturer : (UInt32) manufacturer {
    
    static AudioClassDescription desc;
    UInt32 encoderSpecifier = type;
    OSStatus st;
    UInt32 size;
    st = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders,
                                    sizeof(encoderSpecifier),
                                    &encoderSpecifier, &size);
    
    if (st) {
        NSLog(@"error getting audio format propery info: %d", (int)(st));
        return nil;
    }
    
    unsigned int count = size / sizeof(AudioClassDescription);
    AudioClassDescription descriptions[count];
    st = AudioFormatGetProperty(kAudioFormatProperty_Encoders,
                                sizeof(encoderSpecifier),
                                &encoderSpecifier, &size, descriptions);
    
    if (st) {
        return nil;
    }
    
    for (unsigned int i = 0; i < count; i++) {
        if ((type == descriptions[i].mSubType) && (manufacturer == descriptions[i].mManufacturer)) {
            memcpy(&desc, &(descriptions[i]), sizeof(desc));
            return &desc;
        }
    }

    return nil;
}

static OSStatus inInputDataProc(AudioConverterRef inAudioConver, UInt32 *ioNumberDataPackts, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData) {
    
    AACEncoder *encoder = (__bridge AACEncoder *)(inUserData);
    UInt32 requestedPackets = *ioNumberDataPackts;
    
    size_t copiedSamples = [encoder copyPCMSamplesIntoBuffer:ioData];
    
    if (copiedSamples < requestedPackets) {
        *ioNumberDataPackts = 0;
        return -1;
    }
    
    *ioNumberDataPackts = 1;
    
    return noErr;
}

-(size_t) copyPCMSamplesIntoBuffer : (AudioBufferList *)ioData {
    
    size_t originalBufferSize = _pcmBufferSize;
    if (!originalBufferSize) {
        return 0;
    }
    
    ioData -> mBuffers[0].mData = _pcmBuffer;
    ioData -> mBuffers[0].mDataByteSize = _pcmBufferSize;
    _pcmBuffer = NULL;
    _pcmBufferSize = 0;
    
    return originalBufferSize;
}

-(void) encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer
           completionBlock:(void (^)(NSData *, NSError *))completionBlock {
    
    CFRetain(sampleBuffer);
    dispatch_async(_encoderQueue, ^{
       
        if (!_audioConverter) {
            [self setupEncoderFromSampleBuffer:sampleBuffer];
        }
        
        CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
        CFRetain(blockBuffer);
        OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &_pcmBufferSize, &_pcmBuffer);
        NSError *error = nil;
        if (status != kCMBlockBufferNoErr) {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        }
        
        memset(_aacBuffer, 0, _aacBufferSize);
        AudioBufferList outAudioBufferList = {0};
        outAudioBufferList.mNumberBuffers = 1;
        outAudioBufferList.mBuffers[0].mNumberChannels = 1;
        outAudioBufferList.mBuffers[0].mDataByteSize = _aacBufferSize;
        outAudioBufferList.mBuffers[0].mData = _aacBuffer;
        AudioStreamPacketDescription *outPacketDescription = NULL;
        UInt32 ioOutputDataPacketSize = 1;
        status = AudioConverterFillComplexBuffer(_audioConverter,
                                                 inInputDataProc,
                                                 (__bridge void *)(self),
                                                 &ioOutputDataPacketSize,
                                                 &outAudioBufferList,
                                                 outPacketDescription);
        
        
        NSData *data = nil;
        if (status == 0) {
            NSData *rawAAC = [NSData dataWithBytes:outAudioBufferList.mBuffers[0].mData length:outAudioBufferList.mBuffers[0].mDataByteSize];
            NSData *adtsHeader = [self adtsDataForPacketLength : rawAAC.length];
            NSMutableData *fullData = [NSMutableData dataWithData:adtsHeader];
            [fullData appendData:rawAAC];
            data = fullData;
        }else{
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        }
        
        if (completionBlock) {
            dispatch_async(_callbackQueue, ^{
                completionBlock(data,error);
            });
        }
        
        CFRelease(sampleBuffer);
        CFRelease(blockBuffer);
    });
}

-(NSData *) adtsDataForPacketLength : (NSUInteger) packetLength {
    int adtsLength = 7;
    char *packet = malloc(sizeof(char) * adtsLength);
    
    //由addADTStoPacket回收的变量
    int profile = 2;//AAC LC
    int freqIdx = 4;//44.1KHz
    int chanCfg = 1;//MPEG-4音频通道配置。 1通道前中心

    NSUInteger fullLength = adtsLength + packetLength;
    //填写ADTS数据
    packet[0] = (char)0xFF; // 11111111     = syncword
    packet[1] = (char)0xF9; // 1111 1 00 1  = syncword MPEG-2 Layer CRC
    packet[2] = (char)(((profile - 1) << 6) + (freqIdx << 2) + (chanCfg >> 2));
    packet[3] = (char)(((chanCfg & 3) << 6) + (fullLength >> 11));
    packet[4] = (char)((fullLength & 0x7FF) >> 3);
    packet[5] = (char)(((fullLength & 7) << 5) + 0x1F);
    packet[6] = (char)0xFC;
    
    NSData *data = [NSData dataWithBytesNoCopy:packet length:adtsLength freeWhenDone:YES];
    return data;
}

@end
