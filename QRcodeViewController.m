//
//  QRcodeViewController.m
//  WM
//
//  Created by  FLY_AY on 15/10/28.
//  Copyright © 2015年 com.TYToO. All rights reserved.
//

#import "QRcodeViewController.h"
#import "InputCodeController.h"
#import "Tools.h"
#import "BindingEquitment.h"
#import "DeviceBindingRequest.h"

@interface QRcodeViewController ()

@property(nonatomic,strong)DeviceBindingRequest * deviceBindingRequest;

@property(nonatomic,strong)NSString * deviceCode;  //设备码。

@end

@implementation QRcodeViewController

#define Xpadding 40;
#define Ypadding 160;

-(void)viewDidLoad
{
    
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem =  [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"return"] style:UIBarButtonItemStyleDone target:self action:@selector(back)];
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    self.title = @"绑定设备";
    
    if ([self setupCamera]) {
    
        NSLog(@"yes");
    }
    else
    {
        
        [Tools showTipViewWithTip:@"摄像头设备未打开" andVc:self];
    }
    
    [self buildUI];

    
}

-(void)buildUI

{
    _tipLabel = [[UILabel alloc]init];
    _tipLabel.textColor = [UIColor whiteColor];
    _tipLabel.textAlignment = 1;
    _tipLabel.text = @"扫描设备说明上的二维码绑定";
    [self.view addSubview:_tipLabel];
    
    [_tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        int rst = rect.origin.y+rect.size.height+15;
        
        make.top.mas_equalTo(rst);
        make.centerX.equalTo(self.view.mas_centerX);
        make.height.mas_equalTo(30);
        
    }];
    
    _inputNumberBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [_inputNumberBtn setTitle:@"请输入设备号绑定" forState: UIControlStateNormal];
    [_inputNumberBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [self.view addSubview:_inputNumberBtn];
    
    [_inputNumberBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.width.mas_equalTo(SCREEN_WIDTH/2);
        make.centerX.equalTo(self.view.mas_centerX);
        make.height.mas_equalTo(44);
        make.bottom.equalTo(self.view.mas_bottom).offset(-60);
        
    }];
    
    [self buildVMBinding];
    
    UIImageView * imgv = [[UIImageView alloc]initWithFrame:rect];
    imgv.image = [UIImage imageNamed:@"pick_bg"];
    [self.view addSubview:imgv];
    
    upOrdown = NO;
    num =0;
    _lineView = [[UIImageView alloc] initWithFrame:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 2)];
    _lineView.image = [UIImage imageNamed:@"line.png"];
    [self.view addSubview:_lineView];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:.02 target:self selector:@selector(animation1) userInfo:nil repeats:YES];
}

-(void)animation1
{
    if (upOrdown == NO) {
        num ++;
        _lineView.frame = CGRectMake(rect.origin.x, rect.origin.y+2*num, rect.size.width, 2);
        if (2*num == rect.size.height) {
            upOrdown = YES;
        }
    }
    else {
        num --;
        _lineView.frame = CGRectMake(rect.origin.x, rect.origin.y+2*num, rect.size.width, 2);
        if (num == 0) {
            upOrdown = NO;
        }
    }
    
}

-(void)buildVMBinding
{
    @weakify(self);
    [[_inputNumberBtn rac_signalForControlEvents:UIControlEventTouchUpInside]subscribeNext:^(id x) {
       
        @strongify(self);
        
        [self.navigationController pushViewController:[InputCodeController new] animated:YES];
        
    }];
}

- (BOOL)setupCamera
{
    // Device
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Input
    NSError * err = nil;
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&err];
    
    if (!self.input) {
        NSLog(@"%@", [err localizedDescription]);
        return NO;
        
    }
    
    // Output
    self.output = [[AVCaptureMetadataOutput alloc]init];
    
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    
    // Session
    self.session = [[AVCaptureSession alloc]init];
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    if ([self.session canAddInput:self.input])
    {
        [self.session addInput:self.input];
    }
    if ([self.session canAddOutput:self.output])
    {
        [self.session addOutput:self.output];
    }
    
    // 条码类型
    /**
     *  可设置属性rectOfInterest。优化扫描。
     */
      [self.output setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    
    
    // Preview
    self.preview = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.preview.videoGravity =AVLayerVideoGravityResizeAspectFill;
    
    
    rect.origin.x = Xpadding;
    rect.origin.y = 1.5*Xpadding;
    rect.size.width = self.view.frame.size.width - 2*Xpadding;
    rect.size.height = self.view.frame.size.height - 2*Ypadding;
    
    
    [self.output setRectOfInterest:CGRectMake(rect.origin.y/SCREEN_HEIGHT, rect.origin.x/SCREEN_WIDTH, rect.size.height/SCREEN_HEIGHT, rect.size.width/SCREEN_WIDTH)];
    
    
    self.preview.frame = self.view.bounds;
    
    
    [self.view.layer addSublayer:self.preview];
    
    // Start
    [self.session startRunning];
    
    return YES;
}

#pragma mark AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    
    if ([metadataObjects count] >0) {
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex:0];
        
        
        self.deviceCode = metadataObject.stringValue;
        
        //...做一系列绑定的操作。成功后走下面。~
        
        [self postDataToServer];
   
    }
    
    [_session stopRunning];
}

-(void)scanSuccess
{
    //创建通知
    NSNotification *notification =[NSNotification notificationWithName:@"bindingSuccess" object:nil userInfo:nil];
    //通过通知中心发送通知
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    
    [self back];
    
}

/**
 *  绑定设备接口工作
 */
-(void)postDataToServer
{
    self.deviceBindingRequest = [DeviceBindingRequest Request];
    
    NSString *string = [BindingEquitment textFromBase64String:self.deviceCode];
    
    self.deviceBindingRequest.deviceCode = string;
    
    self.deviceBindingRequest.bindFlag = @"1";
    
    
    [[RACObserve(self.deviceBindingRequest, state) filter:^BOOL(id value) {
        
        return value == RequestStateSuccess;
        
    }]subscribeNext:^(id x) {
        
        [LoginEntity shareManager].deviceCode = string;
        
        MBProgressHUD * tipView = [[MBProgressHUD alloc]init];
        
        [self.view addSubview:tipView];
        
        [tipView show:YES];
        [tipView hide:YES afterDelay:2];
        [self performSelector:@selector(scanSuccess) withObject:nil afterDelay:2];
    }];
    
    [[SceneModel SceneModel] SEND_ACTION:self.deviceBindingRequest];
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [timer invalidate];
}


-(void)back
{
    
    [timer invalidate];
    [self.navigationController popViewControllerAnimated:YES];
    
}

@end
