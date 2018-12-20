//
//  SSQRCodeManager.m
//  SSQRCode
//
//  Created by Liu Jie on 2018/12/20.
//  Copyright © 2018 JasonMark. All rights reserved.
//

#import "SSQRCodeManager.h"

@interface SSQRCodeManager()
@property (nonatomic, strong) SSQRCodeConfig *config;
@end

@implementation SSQRCodeManager

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static SSQRCodeManager *_instance = nil;
    dispatch_once(&onceToken, ^{
        _instance = [[SSQRCodeManager alloc] init];
    });
    return _instance;
}

- (UIImage *)qrCodeWithConfig:(SSQRCodeConfig *)config {
    
    UIImage *result = [self qrCodeWithUrl:config.url];
    
    if (config.foregroundColor && result) {
        NSMutableArray *multArr = [self changeUIColorToRGB:config.foregroundColor];
        if (multArr.count >= 3) {
            result = [self imageTransform:result Foreground:config.foregroundColor background:config.backgroundColor];
        }
    }
    return result;
}

- (void)qrCodeWithConfig:(SSQRCodeConfigBlock)configBlock completionHandler:(SSQRCodeResultBlock)resultBlock {
    
    if (!configBlock) { return; }
    
    ///初始化 SSQRCodeConfig
    if (!self.config) {
        self.config = [[SSQRCodeConfig alloc] init];
    }
    configBlock(self.config);
    
    UIImage *result = [self qrCodeWithConfig:self.config];
    resultBlock(result);
}

#pragma mark - 生成二维码
- (UIImage *)qrCodeWithUrl:(NSURL *)url {
    
    // 1. 创建一个二维码滤镜实例(CIFilter)
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // 滤镜恢复默认设置
    [filter setDefaults];
    
    // 2. 给滤镜添加数据
    NSString *string = url.absoluteString;
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    [filter setValue:data forKeyPath:@"inputMessage"];
    
    // 3. 生成二维码
    CIImage *image = [filter outputImage];
    
    
    ///使二维码变高清
    //    NSLog(@"Width:%f\nHeigh:%f", self.config.size.width, self.config.size.height);
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(self.config.size.width/CGRectGetWidth(extent), self.config.size.height/CGRectGetHeight(extent));
    
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}

#pragma mark 改变二维码颜色
- (UIImage *)imageTransform:(UIImage *)image Foreground:(UIColor *)foreground background:(UIColor *)background {
    int imageWidth = image.size.width;
    int imageHeight = image.size.height;
    size_t bytesPerRow = imageWidth * 4;
    uint32_t *rgbImageBuf = (uint32_t *)malloc(bytesPerRow * imageHeight);
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpaceRef, kCGBitmapByteOrder32Little|kCGImageAlphaNoneSkipLast);
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), image.CGImage);
    
    NSMutableArray *foregroundArr = nil;
    NSMutableArray *backgroundArr = nil;
    if (foreground) { foregroundArr = [self changeUIColorToRGB:foreground]; }
    if (background) { backgroundArr = [self changeUIColorToRGB:background]; }
    
    //遍历像素, 改变像素点颜色
    int pixelNum = imageWidth * imageHeight;
    uint32_t *pCurPtr = rgbImageBuf;
    for (int i = 0; i<pixelNum; i++, pCurPtr++) {
        if ((*pCurPtr & 0xFFFFFF00) < 0x99999900 && foregroundArr.count >= 3) { // 将白色变成透明
            uint8_t* ptr = (uint8_t*)pCurPtr;
            
            ptr[3] = ((NSString *)foregroundArr[0]).floatValue;//red;//*255;
            ptr[2] = ((NSString *)foregroundArr[1]).floatValue;//green;//*255;
            ptr[1] = ((NSString *)foregroundArr[2]).floatValue;//blue;//*255;
        }else{
            uint8_t* ptr = (uint8_t*)pCurPtr;
            if (backgroundArr.count >= 3) {
                ptr[3] = ((NSString *)backgroundArr[0]).floatValue;//red;//*255;
                ptr[2] = ((NSString *)backgroundArr[1]).floatValue;//green;//*255;
                ptr[1] = ((NSString *)backgroundArr[2]).floatValue;//blue;//*255;
            } else {
                ptr[0] = 0;
            }
        }
    }
    //取出图片
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rgbImageBuf, bytesPerRow * imageHeight, NULL);
    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, 8, 32, bytesPerRow, colorSpaceRef,
                                        kCGImageAlphaLast | kCGBitmapByteOrder32Little, dataProvider,
                                        NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    UIImage *resultImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpaceRef);
    
    return resultImage;
}

#pragma mark UIColor转换为RGB
//将UIColor转换为RGB值
- (NSMutableArray *) changeUIColorToRGB:(UIColor *)color
{
    NSMutableArray *RGBStrValueArr = [[NSMutableArray alloc] init];
    NSString *RGBStr = nil;
    //获得RGB值描述
    NSString *RGBValue = [NSString stringWithFormat:@"%@",color];
    //将RGB值描述分隔成字符串
    NSArray *RGBArr = [RGBValue componentsSeparatedByString:@" "];
    
    
    //获取红色值
    if (RGBArr.count < 2) return RGBStrValueArr;
    CGFloat r = [[RGBArr objectAtIndex:1] floatValue] * 255;
    RGBStr = [NSString stringWithFormat:@"%f",r];
    [RGBStrValueArr addObject:RGBStr];
    //获取绿色值
    if (RGBArr.count < 3) return RGBStrValueArr;
    CGFloat g = [[RGBArr objectAtIndex:2] floatValue] * 255;
    RGBStr = [NSString stringWithFormat:@"%f",g];
    [RGBStrValueArr addObject:RGBStr];
    //获取蓝色值
    if (RGBArr.count < 4) return RGBStrValueArr;
    CGFloat b = [[RGBArr objectAtIndex:3] floatValue] * 255;
    RGBStr = [NSString stringWithFormat:@"%f",b];
    [RGBStrValueArr addObject:RGBStr];
    return RGBStrValueArr;
}
@end

#pragma mark -
@implementation SSQRCodeConfig

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static SSQRCodeConfig *_instance = nil;
    dispatch_once(&onceToken, ^{
        _instance = [[SSQRCodeConfig alloc] init];
    });
    _instance.size = CGSizeMake(80.0, 80.0);
    return _instance;
}
@end
