//
//  SSQRCodeManager.h
//  SSQRCode
//
//  Created by Liu Jie on 2018/12/20.
//  Copyright © 2018 JasonMark. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * 生成二维码封装
 */
@class SSQRCodeConfig;

typedef void(^SSQRCodeResultBlock)(UIImage *result);
typedef void(^SSQRCodeConfigBlock)(SSQRCodeConfig *config);
@interface SSQRCodeManager : NSObject
+ (instancetype) shareInstance;

- (UIImage *)qrCodeWithConfig:(SSQRCodeConfig *)config;

- (void)qrCodeWithConfig:(SSQRCodeConfigBlock)configBlock completionHandler:(SSQRCodeResultBlock)resultBlock;
@end


@interface SSQRCodeConfig : NSObject
+ (instancetype) shareInstance;

///二维码绑定的地址
@property (nonatomic, strong) NSURL *url;

///二维码大小 默认 80x80
@property (nonatomic, assign) CGSize size;

///二维码前景色
@property (nonatomic, strong) UIColor *foregroundColor;

///二维码背景色
@property (nonatomic, strong) UIColor *backgroundColor;

@end
