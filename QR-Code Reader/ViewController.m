//
//  ViewController.m
//  QR-Code Reader
//
//  Created by Jhonathan Wyterlin on 23/10/15.
//  Copyright © 2015 Jhonathan Wyterlin. All rights reserved.
//

#import "ViewController.h"

// Apple
#import <AVFoundation/AVCaptureDevice.h>
#import <AudioToolbox/AudioToolbox.h>

// Pods
#import "ZBarSDK.h"
#import <ZXingObjC/ZXingObjC.h>

@interface ViewController()<ZBarReaderViewDelegate, ZXCaptureDelegate>

// UI
@property(nonatomic,strong) UIView *viewCamera;
@property(nonatomic,strong) ZBarReaderView *readerqr;
@property(nonatomic,strong) UIImageView *cameraImage;
@property(nonatomic,strong) UIView *viewResult;
@property(nonatomic,strong) UILabel *lbResult;
@property(nonatomic,strong) UIButton *btnRestartScan;
@property(nonatomic,strong) UIButton *btnLight;

@property(nonatomic,strong) NSString *qrcodeData;

@property (nonatomic, strong) ZXCapture *capture;

typedef enum {
    TypeReaderingQRCode,
    TypeReaderingDataMatrix
} TypeReadering;

@property(nonatomic) TypeReadering typeReadering;

@end

@implementation ViewController

#pragma mark - View Lifecycle

-(void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Here you can choose if use ZBar or ZXingObjC
    self.typeReadering = TypeReaderingDataMatrix;
    
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self showScanner];
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewDidLayoutSubviews {

    [super viewDidLayoutSubviews];

    if ( self.typeReadering == TypeReaderingQRCode ) {
    
        self.readerqr.frame = self.viewCamera.frame;
        
        self.cameraImage.center = CGPointMake( self.readerqr.frame.size.width/2, (self.readerqr.frame.size.height/2));
        
    } else {
        
        self.capture.layer.frame = self.view.bounds;
        
        CGAffineTransform captureSizeTransform = CGAffineTransformMakeScale(320 / self.view.frame.size.width, 480 / self.view.frame.size.height);
        self.capture.scanRect = CGRectApplyAffineTransform( self.view.frame, captureSizeTransform );
        
        self.cameraImage.center = CGPointMake( self.view.frame.size.width/2, (self.view.frame.size.height/2));
        
    }

}

-(void)dealloc {
    [self.capture.layer removeFromSuperlayer];
}

#pragma mark - IBAction methods

-(IBAction)btnRestartScanPressed:(id)sender {
    
    [self showScanner];
    [self restartCamera];
    
}

-(IBAction)btnLightPressed:(id)sender {
    
    if ( self.readerqr.torchMode == AVCaptureTorchModeOff )
        self.readerqr.torchMode = AVCaptureTorchModeOn;
    else
        self.readerqr.torchMode = AVCaptureTorchModeOff;
    
}

#pragma mark - ZBarReaderViewDelegate methods

-(void)readerView:(ZBarReaderView *)readerView
   didReadSymbols:(ZBarSymbolSet *)symbols
        fromImage:(UIImage *)image {
    
    for( ZBarSymbol *sym in symbols )
        self.qrcodeData = [sym.data mutableCopy];
    
    if ( [self isQRCodeValid] ) {
        
        [readerView stop];
        
        [self closeCameraScanner];
        
        self.readerqr = nil;
        
        [self showResult];
        
    } else {
        
        [self showInvalidCode];
        
    }
    
}

#pragma mark - ZXCaptureDelegate Methods

-(void)captureResult:(ZXCapture *)capture result:(ZXResult *)result {
    
    if ( ! result )
        return;
    
    // We got a result. Display information about the result onscreen.
    NSString *formatString = [self barcodeFormatToString:result.barcodeFormat];
    NSString *display = [NSString stringWithFormat:@"Scanned!\nFormat: %@\nContents: %@", formatString, result.text];
    
    self.qrcodeData = display;
    
    // Vibrate
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
    [self.capture stop];
    
    [self showResult];
    
}

#pragma mark - Private methods

-(void)showScanner {
    
    if ( self.typeReadering == TypeReaderingQRCode ) {
    
        self.readerqr = [ZBarReaderView new];
        self.readerqr.readerDelegate = self;
        self.readerqr.frame = self.viewCamera.frame;
        [self.readerqr addConstraints: self.viewCamera.constraints];
        [self.view addSubview:self.readerqr];
        [self.readerqr addSubview:self.cameraImage];
        [self.readerqr addSubview:self.btnLight];
        self.readerqr.tag = 99999999;
        self.readerqr.torchMode = AVCaptureTorchModeOff;
        [self.readerqr start];
        
        ZBarImageScanner *scanner = self.readerqr.scanner;
        
        [scanner setSymbology:ZBAR_I25 config:ZBAR_CFG_ENABLE to:0];
        
    } else {
        
        if ( ! self.capture ) {
        
            self.capture = [[ZXCapture alloc] init];
            self.capture.camera = self.capture.back;
            self.capture.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            self.capture.rotation = 90.0f;
            
            self.capture.layer.frame = self.view.bounds;
            [self.view.layer addSublayer:self.capture.layer];
            [self.view.layer addSublayer:self.cameraImage.layer];
            
            self.capture.delegate = self;
            
        }
        
    }
    
}

-(BOOL)isQRCodeValid {
    
    //
    // Here you customize the way you feel is appropriate to you
    //
    
    return true;
    
}

-(void)closeCameraScanner {
    
    UIView *v = [self.view viewWithTag:99999999];
    
    if ( v )
        [v removeFromSuperview];
    
    [self.view endEditing:YES];
    
}

-(void)showResult {
    
    if ( ! [self.viewResult isDescendantOfView:self.view] )
        [self.view addSubview:self.viewResult];
    
    self.lbResult.text = self.qrcodeData;
    
}

-(void)restartCamera {

    self.qrcodeData = @"";
    [self.viewResult removeFromSuperview];
    
    if ( self.typeReadering == TypeReaderingQRCode ) {
        
        if ( ! [self.readerqr isDescendantOfView:self.view] )
            [self.view addSubview:self.readerqr];
        
        [self.readerqr start];
        
    } else {
        
        [self.capture start];
        
    }

}

-(NSString *)barcodeFormatToString:(ZXBarcodeFormat)format {
 
    switch (format) {
        case kBarcodeFormatAztec:
            return @"Aztec";
            
        case kBarcodeFormatCodabar:
            return @"CODABAR";
            
        case kBarcodeFormatCode39:
            return @"Code 39";
            
        case kBarcodeFormatCode93:
            return @"Code 93";
            
        case kBarcodeFormatCode128:
            return @"Code 128";
            
        case kBarcodeFormatDataMatrix:
            return @"Data Matrix";
            
        case kBarcodeFormatEan8:
            return @"EAN-8";
            
        case kBarcodeFormatEan13:
            return @"EAN-13";
            
        case kBarcodeFormatITF:
            return @"ITF";
            
        case kBarcodeFormatPDF417:
            return @"PDF417";
            
        case kBarcodeFormatQRCode:
            return @"QR Code";
            
        case kBarcodeFormatRSS14:
            return @"RSS 14";
            
        case kBarcodeFormatRSSExpanded:
            return @"RSS Expanded";
            
        case kBarcodeFormatUPCA:
            return @"UPCA";
            
        case kBarcodeFormatUPCE:
            return @"UPCE";
            
        case kBarcodeFormatUPCEANExtension:
            return @"UPC/EAN extension";
            
        default:
            return @"Unknown";
    }
    
}

-(void)showInvalidCode {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Invalid QR Code. Try again."
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self restartCamera];
    }];
    
    [alert addAction:ok];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    [self.readerqr stop];
    
}

#pragma mark - Creating components

-(UIView *)viewCamera {
    
    if ( ! _viewCamera ) {
        
        _viewCamera = [[UIView alloc] initWithFrame:self.view.frame];
        [self.view addSubview:_viewCamera];
        
    }
    
    return _viewCamera;
    
}

-(UIImageView *)cameraImage {
    
    if ( ! _cameraImage ) {
        
        _cameraImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 250, 250)];
        _cameraImage.image = [UIImage imageNamed:@"cameraLimits"];
        
    }
    
    return _cameraImage;
    
}

-(UIView *)viewResult {
    
    if ( ! _viewResult ) {
        
        _viewResult = [[UIView alloc] initWithFrame:self.view.frame];
        [_viewResult addSubview:self.lbResult];
        [_viewResult addSubview:self.btnRestartScan];
        _viewResult.backgroundColor = [UIColor whiteColor];
    }
    
    return _viewResult;
    
}

-(UILabel *)lbResult {
    
    if ( ! _lbResult ) {
        
        CGRect f = self.view.frame;
        CGFloat height = 89;
        
        _lbResult = [[UILabel alloc] initWithFrame:CGRectMake( 0, f.size.height/2 - height/2, f.size.width, height )];
        _lbResult.textAlignment = NSTextAlignmentCenter;
        _lbResult.numberOfLines = 0;
        
    }
    
    return _lbResult;
    
}

-(UIButton *)btnRestartScan {
    
    if ( ! _btnRestartScan ) {
        
        CGRect f = self.view.frame;
        CGFloat x = 8;
        CGFloat y = self.lbResult.frame.origin.y + self.lbResult.frame.size.height + 8;
        
        _btnRestartScan = [[UIButton alloc] initWithFrame:CGRectMake( x, y, f.size.width - 2*x, 44 )];
        [_btnRestartScan addTarget:self action:@selector(btnRestartScanPressed:) forControlEvents:UIControlEventTouchUpInside];
        _btnRestartScan.backgroundColor = [UIColor colorWithRed:0.0 green:180.0/256.0 blue:0.0 alpha:1.0];
        [_btnRestartScan setTitle:@"Restart Scan" forState:UIControlStateNormal];
        
    }
    
    return _btnRestartScan;
    
}

-(UIButton *)btnLight {
    
    if ( ! _btnLight ) {
        
        CGRect f = self.view.frame;
        
        CGFloat width = 50;
        CGFloat height = 34;
        CGFloat x = f.size.width - width - 8;
        CGFloat y = 25;
        
        _btnLight = [[UIButton alloc] initWithFrame:CGRectMake( x, y, width, height )];
        [_btnLight addTarget:self action:@selector(btnLightPressed:) forControlEvents:UIControlEventTouchUpInside];
        _btnLight.backgroundColor = [UIColor colorWithRed:0.0 green:180.0/256.0 blue:0.0 alpha:1.0];
        [_btnLight setTitle:@"Light" forState:UIControlStateNormal];
        _btnLight.layer.cornerRadius = 5.0;
        _btnLight.titleLabel.font = [UIFont systemFontOfSize:13.0];
        
    }
    
    return _btnLight;
    
}

@end
