//
//  ZZCaptureController.m
//  LiveTest
//
//  Created by 志方 on 17/3/23.
//  Copyright © 2017年 志方. All rights reserved.
//

#import "ZZCaptureController.h"
#import <AVFoundation/AVFoundation.h>
#import <GPUImage.h>
#import "GPUImageBeautifyFilter.h"
#import "H264Encoder.h"
#import "AACEncoder.h"
#import "ZZGiftItem.h"
#import "ZZUserItem.h"
#import "ZZGiftAnimView.h"

@interface ZZCaptureController ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,H264EncoderDelegate>
/** 录制会话 */
@property(nonatomic, strong) AVCaptureSession *captureSession;
/** 当前拍摄设备摄像头 */
@property(nonatomic, strong) AVCaptureDeviceInput *currentVideoDeviceInput;
/** 焦点光标图片 */
@property(nonatomic, weak) UIImageView *focusCursorImageView;
/** 视频预览图层 */
@property(nonatomic, weak) AVCaptureVideoPreviewLayer *previedLayer;
/** 录制输入输出连接 */
@property(nonatomic, weak) AVCaptureConnection *videoConnection;
@property(nonatomic,strong) UIButton *backBtn;
@property(nonatomic, strong) UIButton *exchgeCapture;
@property(nonatomic, strong) UIButton *clickUpvote;
@property(nonatomic, strong) UIButton *giftBtn;
/** 美颜开关 */
@property(nonatomic, strong) UISwitch *on_off;

/** 美颜相机 */
@property(nonatomic, strong) GPUImageVideoCamera *videoCamera;
/** 美颜后的图层 */
@property(nonatomic, weak) GPUImageView *captureVideoPreview;

@property(nonatomic, weak) GPUImageBilateralFilter *bilateralFilter;
@property(nonatomic, weak) GPUImageBrightnessFilter *brightnessFilter;
/** 音视频编码 */
@property(nonatomic, strong) H264Encoder *h264Encoder;
@property(nonatomic, strong) AACEncoder *aacEncoder;
@property(nonatomic, copy) NSString *h264File;
@property(nonatomic, strong) NSFileHandle *fileHandle;

/** 礼物动画 */
@property(nonatomic, strong) NSMutableArray *giftQueue;
@property(nonatomic, strong) NSMutableArray *giftAnimViews;
@property(nonatomic, strong) NSMutableArray *positions;

@end

@implementation ZZCaptureController

/** 懒加载聚焦视图 */
-(UIImageView *) focusCursorImageView {
    if (_focusCursorImageView == nil) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"focus"]];
        _focusCursorImageView = imageView;
        [self.view addSubview:_focusCursorImageView];
    }
    return _focusCursorImageView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"视频采集";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.navigationController.navigationBar setHidden:YES];
    
    [self setView];
    [self setupCaptureVideo];
    
    [self setupVideoCamera];
//    [self setupAdjustCamera];
    
}
-(void) setView {
    self.backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.backBtn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [self setBtn:self.backBtn withFrame:CGRectMake(10, 25, 40, 40) withTitle:@"🔙"];
    
    self.exchgeCapture = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.exchgeCapture addTarget:self action:@selector(exchangeAction) forControlEvents:UIControlEventTouchUpInside];
    [self setBtn:self.exchgeCapture withFrame:CGRectMake(kScreenWidth - 50, 25, 40, 40) withTitle:@"👁‍🗨"];
    
    self.giftBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.giftBtn addTarget:self action:@selector(sendGiftAction) forControlEvents:UIControlEventTouchUpInside];
    [self setBtn:self.giftBtn withFrame:CGRectMake(10, kScreenHeight - 150, 40, 40) withTitle:@"💝"];
    
    self.on_off = [[UISwitch alloc] initWithFrame:CGRectMake(kScreenWidth - 60, 80, 50, 40)];
    [self.on_off addTarget:self action:@selector(on_offAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.on_off];
    
    UISlider *slider1 = [[UISlider alloc] initWithFrame:CGRectMake(30, kScreenHeight - 100, kScreenWidth - 60, 30)];
    [slider1 addTarget:self action:@selector(brightnessFilter:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:slider1];
    
    UISlider *slider2 = [[UISlider alloc] initWithFrame:CGRectMake(30, kScreenHeight - 60, kScreenWidth - 60, 30)];
    [slider2 addTarget:self action:@selector(bilateralFilter:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:slider2];
    
    self.clickUpvote = [UIButton buttonWithType:UIButtonTypeSystem];
    [self setBtn:self.clickUpvote withFrame:CGRectMake(kScreenWidth - 50, kScreenHeight - 150, 40, 40) withTitle:@"💕"];
    [self.clickUpvote addTarget:self action:@selector(clickUpvoteAction) forControlEvents:UIControlEventTouchUpInside];
    
    
}
-(void) clickUpvoteAction {
    [self setupVoteLayer];
}
-(void) sendGiftAction {
    
}
#pragma mark - 设置点赞Layer 
-(void) setupVoteLayer {
    CALayer *layer = [CALayer layer];
    layer.contents = (id)[UIImage imageNamed:@"2.png"].CGImage;
    [self.view.layer addSublayer:layer];
    layer.bounds = CGRectMake(0, 0, 30, 30);
    layer.position = CGPointMake(kScreenWidth - 30, kScreenHeight - 130);
    
    [self setupAnim:layer];
}
//设置点赞layer动画
-(void) setupAnim : (CALayer *) layer {
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        [layer removeAllAnimations];
        [layer removeFromSuperlayer];
    }];
    
    //创建basic动画
    CABasicAnimation *alphaAnim = [CABasicAnimation animation];
    alphaAnim.keyPath = @"alpha";
    alphaAnim.fromValue = @0;
    alphaAnim.toValue = @1;
    
    //路径动画
    CAKeyframeAnimation *pathAnim = [CAKeyframeAnimation animation];
    pathAnim.keyPath = @"position";
    pathAnim.path = [self animPath:layer].CGPath;
    
    //创建动画组
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[alphaAnim,pathAnim];
    group.duration = 4;
    [layer addAnimation:group forKey:nil];
    
    [CATransaction commit];
}

-(UIBezierPath *) animPath : (CALayer *) layer {
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    CGFloat y = kScreenHeight - 130;
    CGFloat x = 30;
    while (y > 0) {
        if (y == kScreenHeight - 130) {
            [path moveToPoint:CGPointMake(kScreenWidth - x, y)];
        }else{
            if (y <= kScreenHeight - 500) {
                [path moveToPoint:CGPointMake(kScreenWidth - x, y)];
            }else{
                [path addLineToPoint:CGPointMake(kScreenWidth - x, y)];
            }
            
        }
        x = arc4random_uniform(kScreenWidth * 0.3 - 20) + 20;
        y -= 20;
    }
    
    return path;
}

//设置按钮属性
-(void) setBtn : (UIButton *) button
     withFrame : (CGRect) frame
     withTitle : (NSString *) title {
    button.frame = frame;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTintColor:[UIColor blackColor]];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    button.layer.cornerRadius = 20;
    button.backgroundColor = [UIColor whiteColor];
    button.alpha = 0.8;
    [self.view addSubview:button];
}
#pragma mark - 美颜
-(void) brightnessFilter : (UISlider *) sender {
    _brightnessFilter.brightness = sender.value;
}
#pragma mark - 磨皮
-(void) bilateralFilter : (UISlider *) sender {
    //值越小，磨皮效果越好
    CGFloat maxValue = 10;
    [_bilateralFilter setDistanceNormalizationFactor:(maxValue - sender.value)];
}
#pragma mark - 设置自调节美颜
-(void) setupAdjustCamera {
    //创建视频源
    //SessionPreset: 屏幕分辨率，AVCaptureSessionPresetHigh会自适应高分辨率
    //cameraPosition：摄像头方向
    //最好使用AVCaptureSessionPresetHigh,会自动识别，如果太高分辨率，当前设备不支持会直接报错
    GPUImageVideoCamera *videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionFront | AVCaptureDevicePositionBack];
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    _videoCamera = videoCamera;
    
    //创建最终预览view
    GPUImageView *captureVideoPreview = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    [self.view insertSubview:captureVideoPreview atIndex:0];
    
    //创建滤镜：磨皮、美白、组合滤镜
    GPUImageFilterGroup *groupFilter = [[GPUImageFilterGroup alloc] init];
    
    //磨皮滤镜
    GPUImageBilateralFilter *bilateralFilter = [[GPUImageBilateralFilter alloc] init];
    [groupFilter addTarget:bilateralFilter];
    _bilateralFilter = bilateralFilter;
    
    //美白滤镜
    GPUImageBrightnessFilter *brightnessFilter = [[GPUImageBrightnessFilter alloc] init];
    [groupFilter addTarget:brightnessFilter];
    _brightnessFilter = brightnessFilter;
    
    //设置滤镜组链
    [bilateralFilter addTarget:brightnessFilter];
    [groupFilter setInitialFilters:@[bilateralFilter]];
    groupFilter.terminalFilter = brightnessFilter;
    
    //设置GPUImage处理链，从数据源 => 滤镜 = > 最终界面效果
    [videoCamera addTarget:groupFilter];
    [groupFilter addTarget:captureVideoPreview];
    
    //必须调用startCameraCapture 底层才会把采集到的视频源，渲染到GPUImageView中，
    [videoCamera startCameraCapture];
    
}
#pragma mark - 设置开关美颜
-(void) setupVideoCamera {
    //创建视频源
    //SessionPreset: 屏幕分辨率，AVCaptureSessionPresetHigh会自适应高分辨率
    //cameraPosition：摄像头方向
    GPUImageVideoCamera *videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionFront | AVCaptureDevicePositionBack];
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    _videoCamera = videoCamera;
    
    
    //创建最终预览view
    GPUImageView *captureVideoPreview = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    
    _captureVideoPreview = captureVideoPreview;
    [self.view insertSubview:_captureVideoPreview atIndex:0];
    //设置处理链
    [_videoCamera addTarget:_captureVideoPreview];
    
    //必须调用startCameraCapture,底层才会把采集到的视频源，渲染到GPUImageView中，就能显示了
    //开始采集视频
    [_videoCamera startCameraCapture];
}
-(void) on_offAction : (UISwitch *) sender {
    //切换美颜效果原理：移除之前所有处理链，重新设置处理链
    if (sender.on) {
        //移除之前所有处理链
        [_videoCamera removeAllTargets];
        
        //创建美颜滤镜
        GPUImageBeautifyFilter *beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
        
        //设置GPUImage处理链，从数据源 => 滤镜 => 最终界面效果
        [_videoCamera addTarget:beautifyFilter];
        [beautifyFilter addTarget:_captureVideoPreview];
    }else{
        //移除之前所有处理链
        [_videoCamera removeAllTargets];
        [_videoCamera addTarget:_captureVideoPreview];
    }
}

-(void) backAction {
    [self.navigationController popViewControllerAnimated:YES];
}
-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.h264Encoder.delegate = nil;
    self.h264Encoder = nil;
    [_captureSession stopRunning];
}
#pragma mark 捕获音视频
-(void) setupCaptureVideo {
    //1.创建捕获会话，必须要强引用，否则会被释放
    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
    _captureSession = captureSession;
    
    //初始化视频编码(H264)
    self.h264Encoder = [H264Encoder new];
    [self.h264Encoder initWithConfiguration];
    [self.h264Encoder initEncode:480 height:640];
    self.h264Encoder.delegate = self;
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        //设置分辨率
        _captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    }
    //2.获取摄像头设备，默认是后置摄像头
    AVCaptureDevice *videoDevice = [self getVideoDevice:AVCaptureDevicePositionFront];
    
    //初始化音频编码(AAC)
    self.aacEncoder = [AACEncoder new];
    //3.获取声音设备
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    //4.创建对应视频设备输入对象
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
    _currentVideoDeviceInput = videoDeviceInput;
    
    //5.创建对应音频设备输入对象
    AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    
    //6.添加回话中(注意：最好要判断是否能添加输入，回话不能添加空的)
    //6.1 添加视频
    if ([captureSession canAddInput:videoDeviceInput]) {
        [captureSession addInput:videoDeviceInput];
    }
    //6.2 添加音频
    if ([captureSession canAddInput:audioDeviceInput]) {
        [captureSession addInput:audioDeviceInput];
    }
    
    //7.获取视频数据输出设备
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    //7.1 设置代理，捕获视频样品数据
    // 注意：队列必须是串行队列，才能获取到数据，而且不能为空
    dispatch_queue_t videoQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
    [videoOutput setSampleBufferDelegate:self queue:videoQueue];
    
    //配置输出视频图像格式
    NSDictionary *captureSettings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
    videoOutput.videoSettings = captureSettings;
    videoOutput.alwaysDiscardsLateVideoFrames = YES;
    if ([captureSession canAddOutput:videoOutput]) {
        [captureSession addOutput:videoOutput];
    }
    
    //8. 获取音频数据输出设备
    AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    //8.2设置代理。捕获视频样品数据
    //注意：队列必须是串行队列，才能获取到数据，而且不能为空
    dispatch_queue_t audioQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
    [audioOutput setSampleBufferDelegate:self queue:audioQueue];
    if ([captureSession canAddOutput:audioOutput]) {
        [captureSession addOutput:audioOutput];
    }
    
    //9.获取视频输入与输出连接，用于分辨音视频数据
    _videoConnection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
    
    //10.添加视频预览图层
    AVCaptureVideoPreviewLayer *previedLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
    previedLayer.frame = [UIScreen mainScreen].bounds;
    _previedLayer = previedLayer;
    [self.view.layer insertSublayer:previedLayer atIndex:0];
    
    
    //11. 启动会话
    [captureSession startRunning];
   
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    
    self.h264File = [documentsDirectory stringByAppendingString:@"lyh.h264"];
    [fileManager removeItemAtPath:self.h264File error:nil];
    [fileManager createFileAtPath:self.h264File contents:nil attributes:nil];
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.h264File];
    
}

#pragma mark 指定摄像头方向获取摄像头
-(AVCaptureDevice *) getVideoDevice : (AVCaptureDevicePosition) position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate
//获取输入设备数据，有可能是音频有可能是视频
-(void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
      fromConnection:(AVCaptureConnection *)connection{
    
    CMTime pts = CMSampleBufferGetDuration(sampleBuffer);
    double dPTS = (double)(pts.value);
    NSLog(@"PDTS IS%f",dPTS);
    
    //这里的sampleBuffer就是采集到的数据了，但他是Video还是Audio的数据，得根据connection来判断
    if (_videoConnection == connection) {
        //取得当前视频的尺寸信息
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        NSInteger width = CVPixelBufferGetWidth(pixelBuffer);
        NSInteger height = CVPixelBufferGetHeight(pixelBuffer);
        [self.h264Encoder encode:sampleBuffer];
    }else{
        
        [self.aacEncoder encodeSampleBuffer:sampleBuffer
                            completionBlock:^(NSData *encodedData, NSError *error) {
            if (encodedData) {
                NSLog(@"Audio data (%lu):%@", (unsigned long)encodedData.length,encodedData.description);
#pragma mark - 音频数据（encodedData）
                
            }
        }];
    }
}

#pragma mark - H264编码delegate
-(void)gotSpsPps:(NSData *)sps
             pps:(NSData *)pps {
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = sizeof(bytes) - 1;//字符串文字具有隐含的尾随'\ 0'

    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    [_fileHandle writeData:ByteHeader];
    [_fileHandle writeData:sps];
    [_fileHandle writeData:ByteHeader];
    [_fileHandle writeData:pps];

}

-(void)gotEncodedData:(NSData *)data
           isKeyFrame:(BOOL)isKeyFrame {
    NSLog(@"Video data (%lu):%@",(unsigned long)data.length,data.description);
    
    if (_fileHandle != NULL) {
        const char bytes[] = "\x00\x00\x00\x01";
        size_t length = sizeof(bytes) - 1;
        NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
        
#pragma mark - 视频数据
        [_fileHandle writeData:ByteHeader];
        [_fileHandle writeData:data];
    }
}

#pragma mark - 将捕获的视频转换成图片
-(UIImage *) imageFromSampleBuffer : (CMSampleBufferRef) sampleBuffer {
    //获取CMSampleBufferRef 的medio数据
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    //像素缓冲区的锁基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    //获取每一行的像素缓冲区的字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    
    //获取像素缓冲区的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    //获取每一行的像素缓冲区的字节数
    uint8_t *baseAddress = (uint8_t *)malloc(bytesPerRow * height);
    memcpy(baseAddress, CVPixelBufferGetBaseAddress(imageBuffer), bytesPerRow * height);
    
//    size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
    
    //创建一个设备相关的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    //创建一个位图图形上下文与样品缓冲数据
    //根据上下文画一个位图的宽度
    //像素宽,高度的像素高。指定组件的数量为每个像素由“空间”
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedFirst);
    
    
    //在位图图形上下文中创建一个图像像素数据
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    
    //解锁像素缓冲区
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    //释放上下文和颜色空间
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    //从Quartz图像中创建一个图片对象
    UIImage *image= [UIImage imageWithCGImage:quartzImage scale:1.0 orientation:UIImageOrientationRight];
    //释放像素缓冲区的字节数
    free(baseAddress);
    //释放Quartz图像
    CGImageRelease(quartzImage);
    
    
    
    return image;
}
#pragma mark 切换摄像头
-(void) exchangeAction {
    //获取当前设备方向
    AVCaptureDevicePosition curPosition = _currentVideoDeviceInput.device.position;
    
    //获取需要改变的方向
    AVCaptureDevicePosition togglePosition = curPosition == AVCaptureDevicePositionFront ? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront;
    
    //获取改变的摄像头的设备
    AVCaptureDevice *toggleDevice = [self getVideoDevice:togglePosition];
    
    //获取改变的摄像头的输入设备
    AVCaptureDeviceInput *toggleDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:toggleDevice error:nil];
    
    //移除之前摄像头输入设备
    [_captureSession removeInput:_currentVideoDeviceInput];
    
    //添加新的摄像头输入设备
    [_captureSession addInput:toggleDeviceInput];
    
    //记录当前摄像头输入设备
    _currentVideoDeviceInput = toggleDeviceInput;
    
}

#pragma mark - 点击屏幕，出现聚焦视图
-(void)touchesBegan:(NSSet<UITouch *> *)touches
          withEvent:(UIEvent *)event {
    //获取点击位置
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    
    //把当前位置转换为摄像头点上的位置
    CGPoint cameraPoint = [_previedLayer captureDevicePointOfInterestForPoint:point];
    
    //设置聚焦点光标位置
    [self setFocusCursorWithPoint:point];
    
    //设置聚焦
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}

#pragma mark - 设置聚焦光标位置
/** point：光标位置 */
-(void) setFocusCursorWithPoint : (CGPoint) point {
    self.focusCursorImageView.center = point;
    self.focusCursorImageView.transform = CGAffineTransformMakeScale(1.5, 1.5);
    self.focusCursorImageView.alpha = 1.0;
    [UIView animateWithDuration:1.0 animations:^{
        self.focusCursorImageView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusCursorImageView.alpha = 0;
    }];
}

#pragma mark - 设置聚焦
-(void) focusWithMode : (AVCaptureFocusMode) focusMode
         exposureMode : (AVCaptureExposureMode) exposureMode
              atPoint : (CGPoint) point {
    AVCaptureDevice *captureDevice = _currentVideoDeviceInput.device;
    
    //锁定配置
    [captureDevice lockForConfiguration:nil];
    
    //设置聚焦
    if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
    }
    if ([captureDevice isFocusPointOfInterestSupported]) {
        [captureDevice setFocusPointOfInterest:point];
    }
    
    //设置曝光
    if ([captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
        [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
    }
    if ([captureDevice isExposurePointOfInterestSupported]) {
        [captureDevice setExposurePointOfInterest:point];
    }
    
    //解锁配置
    [captureDevice unlockForConfiguration];
}

#pragma mark - 发送礼物

#pragma mark - 判断当前接受的礼物是否属于连发礼物
-(BOOL) isComboGift : (ZZGiftItem *) gift {
    
    ZZGiftItem *comboGift = nil;
    
    for (ZZGiftItem *giftItem in self.giftQueue) {
        //如果是连发礼物就记录下来
        if (giftItem.giftId == gift.giftId && giftItem.user.ID == gift.user.ID) {
            comboGift = giftItem;
        }
    }
    
    if (comboGift) {//连发礼物有值
        //礼物模型的礼物总数+1
        comboGift.giftCount += 1;
        return YES;
    }
    return NO;
    
}
//处理动画
-(void) handleGiftAnim : (ZZGiftItem *) gift {
    //1 创建礼物动画的view
    ZZGiftAnimView *giftView = [ZZGiftAnimView giftAnimView];
    
    CGFloat h = self.view.bounds.size.height * 0.5;
    CGFloat w = self.view.bounds.size.width;
    
    //取出礼物位置
    id position = self.positions.lastObject;
    
    //从数组移除位置
    [self.positions removeObject:position];
    
    CGFloat y = [position floatValue] * h;
    //2.设置礼物view的frame
    giftView.frame = CGRectMake(0, y, w, h);
    
    //3.传递礼物模型
    
    //记录当前位置
    giftView.tag = [position floatValue];
    
    //添加礼物view
    [self.view addSubview:giftView];
    
    __weak typeof(self) weakself = self;
    
    //设置动画
    giftView.transform = CGAffineTransformMakeTranslation(-w, 0);
    [UIView animateWithDuration:25 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:1 options:UIViewAnimationOptionCurveLinear animations:^{
        giftView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        //开始连击动画
        
    }];
}


-(NSMutableArray *)giftQueue {
    if (_giftQueue == nil) {
        _giftQueue = [NSMutableArray array];
    }
    return _giftQueue;
}
-(NSMutableArray *)giftAnimViews {
    if (_giftAnimViews == nil) {
        _giftAnimViews = [NSMutableArray array];
    }
    return _giftAnimViews;
}
-(NSMutableArray *)positions {
    if (_positions == nil) {
        _positions = [NSMutableArray array];
    }
    return _positions;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
