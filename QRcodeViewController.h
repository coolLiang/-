//
//  QRcodeViewController.h
//  WM
//  二维码扫描页面。
//  Created by  FLY_AY on 15/10/28.
//  Copyright © 2015年 com.TYToO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "BaseViewController.h"

@interface QRcodeViewController : BaseViewController<AVCaptureMetadataOutputObjectsDelegate>

{
    int num;
    BOOL upOrdown;
    NSTimer * timer;
    CGRect rect;
}

@property (strong,nonatomic)AVCaptureDevice *device;
@property (strong,nonatomic)AVCaptureDeviceInput *input;
@property (strong,nonatomic)AVCaptureMetadataOutput *output;
@property (strong,nonatomic)AVCaptureSession *session;
@property (strong,nonatomic)AVCaptureVideoPreviewLayer *preview;


@property (nonatomic,strong) UIButton *inputNumberBtn; //输入设备号的按钮。

@property (nonatomic,strong) UILabel * tipLabel;       //提示信息label

@property (nonatomic,strong) UIImageView * lineView;   //动画line;



@end
