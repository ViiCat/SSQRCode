//
//  ViewController.m
//  SSQRCode
//
//  Created by Liu Jie on 2018/12/19.
//  Copyright © 2018 JasonMark. All rights reserved.
//

#import "ViewController.h"
#import "SSQRCodeManager.h"

@interface ViewController ()
@property (nonatomic, strong) UIColor *fgColor;
@property (nonatomic, strong) UIColor *bgColor;
@property (weak, nonatomic) IBOutlet UITextField *txtUrl;
@end


#ifndef UIColorHex
#define UIColorHex(_hex_)   [UIColor colorWithHexString:((__bridge NSString *)CFSTR(#_hex_))]
#endif

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (UIColor *)colorWithTag:(NSInteger)tag {
    switch (tag) {
        case 0:
            return [UIColor greenColor];
            break;
        case 1:
            return [UIColor brownColor];
            break;
        case 2:
            return [UIColor purpleColor];
            break;
            
        default:
            return nil;
            break;
    }
}

- (IBAction)changeFGColor:(id)sender {
    UIButton *btn = (UIButton *)sender;
    self.fgColor = [self colorWithTag:btn.tag];
    [self processQRCode];
}

- (IBAction)changeBGColor:(id)sender {
    UIButton *btn = (UIButton *)sender;
    self.bgColor = [self colorWithTag:btn.tag];
    [self processQRCode];
}

- (void)processQRCode {
    
    NSURL *url = [NSURL URLWithString:@"www.viicat.com"];
    if (self.txtUrl.text.length) {
        if (![self.txtUrl.text containsString:@"http"]) {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", self.txtUrl.text]];
        } else {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@", self.txtUrl.text]];
        }
    }
    
    if (!self.fgColor) {
        self.fgColor = [UIColor blackColor];
    }
    
    if (!self.bgColor) {
        self.bgColor = [UIColor whiteColor];;
    }
    
    __weak typeof(self) weakSelf = self;
    [[SSQRCodeManager shareInstance] qrCodeWithConfig:^(SSQRCodeConfig *config) {
        config.url = url;//[NSURL URLWithString:@"http://www.viicat.com/"];
        config.foregroundColor = weakSelf.fgColor;//[UIColor blackColor];
        config.backgroundColor = weakSelf.bgColor;//[UIColor whiteColor];
        config.size = weakSelf.imgQRCode.frame.size;
    } completionHandler:^(UIImage *result) {
        weakSelf.imgQRCode.image = result;
    }];
}

@end
