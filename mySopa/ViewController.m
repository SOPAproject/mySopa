//
//  ViewController.m
//  mySopa
//
//  Created by Kaoru Ashihara on 13/04/04.
//  Copyright (c) 2013, AIST. All rights reserved.
//

#import "ViewController.h"

@interface ViewController (){
    UIActivityIndicatorView *myIndicator;

}

-(void)configureView;
-(void)setMotion;

@end

@implementation ViewController{
    id detailItem;
    UILabel *Info;
    UILabel *Segue;
    NSString *strFileName;

    UIColor *backColor;
    SInt16 iOrientation;
    SInt16 sCurrentX;
    SInt16 iniWidth;
    SInt16 iOffset;
    SInt16 imageWidth;
    SInt16 sAdj;
    SInt16 sTopMargin;
    SInt16 sCurrentRoll;
    float fStamp;
    
    BOOL isRotate;
    BOOL isYet;
    BOOL isTerminatedByUser;
    BOOL isMotion;
    CMMotionManager *manager;

}

@synthesize detailItem = _detailItem;;
@synthesize Info = _Info;
@synthesize Segue = _Segue;
@synthesize mtnSwitch;

- (void)configureView
{
// Update the user interface for the detail item.
    
    SInt16 height,iTmp;
    double dRatio,dWidth;
    NSString *gifPath,*text;
    NSURL *tmpUrl,*newUrl;
    NSData *data;
    
    if(!isRotate){
        [player setIRot:0];
        
        isYet = NO;
        
        if (self.detailItem) {
            _Info.text = [self.detailItem description];
        }
        else
            _Info.text = @"panther22k.sopa";
        text = _Info.text;
        
        _Segue.numberOfLines = 2;
        if(!manager.gyroAvailable){
            mtnSwitch.enabled = NO;
            _Segue.textColor = [UIColor yellowColor];
            _Segue.textAlignment = NSTextAlignmentRight;
            _Segue.text = @"Self motion mode is not available on this devise";
        }
        else if(isMotion){
            _Segue.textAlignment = NSTextAlignmentCenter;
            _Segue.textColor = [UIColor yellowColor];
            _Segue.text = @"Using gyro sensor dorains the power!\n-mySopa- Copyright (c) 2013, AIST";
        }
        else{
            _Segue.textAlignment = NSTextAlignmentRight;
            _Segue.text = @"Self motion";
        }
        
        NSURL *url = [[NSURL alloc]initWithString:text];
        
        NSRange rang = [text rangeOfString:@"://"];
        if(rang.location == NSNotFound){
            NSString *newStr = [text stringByDeletingPathExtension];
            gifPath = [[NSBundle mainBundle] pathForResource:newStr ofType:@"gif"];
            data = [NSData dataWithContentsOfFile:gifPath];
        }
        else {
            tmpUrl = url.URLByDeletingPathExtension;
            newUrl = [tmpUrl URLByAppendingPathExtension:@"gif"];
            data    = [NSData dataWithContentsOfURL:newUrl];
            if(data == nil){
                tmpUrl = [url URLByDeletingLastPathComponent];
                newUrl = [tmpUrl URLByAppendingPathComponent:@"default.gif"];
                data = [NSData dataWithContentsOfURL:newUrl];
            }
        }
        if(data == nil){
            gifPath = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"gif"];
            data = [NSData dataWithContentsOfFile:gifPath];
        }
        UIImage *img    = [[UIImage alloc] initWithData:data];
        UIImageView *imageView0 = [[UIImageView alloc]initWithImage:img];
        UIImageView *imageView1 = [[UIImageView alloc]initWithImage:img];
        
        imageWidth = imageView0.frame.size.width;
        dRatio = (double)iniWidth * 4 / (double)imageWidth;
        dWidth = (double)imageWidth * dRatio;
        imageWidth = (SInt16)dWidth;
        height = imageView0.frame.size.height;
        dWidth = (double)height * dRatio;
        height = (SInt16)dWidth;
        [imageView0 setFrame:CGRectMake(0.0, 0.0, imageWidth, height)];
        [imageView1 setFrame:CGRectMake(imageWidth, 0.0, imageWidth, height)];
        
        [scrollview removeFromSuperview];
        
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
            sAdj = 32;
            scrollview = [[scroller alloc]initWithFrame:CGRectMake(0.0,sTopMargin,iniWidth,height)];
        }
        else{
            sAdj = 18;
            scrollview = [[scroller alloc]initWithFrame:CGRectMake(0.0,sTopMargin,iniWidth,height)];
        }
        
        scrollview.pagingEnabled = NO;
        scrollview.contentSize = CGSizeMake(imageView0.frame.size.width * 2, imageView0.frame.size.height);
        scrollview.showsHorizontalScrollIndicator = NO;
        scrollview.showsVerticalScrollIndicator = NO;
        scrollview.bounces = NO;
        [scrollview setDelegate:(id)self];
        
        [scrollview addSubview:imageView0];
        [scrollview addSubview:imageView1];
        
        scrollview.contentOffset = CGPointMake(imageWidth + iOffset,0);
        [self.view addSubview:scrollview];
        
    }
    int orientation = self.interfaceOrientation;
    if(orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown){
        iOffset = imageWidth / sAdj;
    }
    else{
        iOffset = 0;
    }
    if(isRotate){
        iTmp = scrollview.contentOffset.x;
        if(iOffset == 0){                   // landscape -> portrait
            iTmp -= imageWidth / sAdj;
        }
        else{
            iTmp += iOffset;
        }
        scrollview.contentOffset = CGPointMake(iTmp,0);
        isRotate = FALSE;
    }
    else{
        scrollview.contentOffset = CGPointMake(imageWidth + iOffset,0);
        player.urlStr = text;
        if([player isPlaying] == NO){
            if(![player loadDatabase]){
                _Info.text = @"Check path of the SOPA file";
                UIAlertView *alertView = [[UIAlertView alloc]
                                          initWithTitle : @"Database error!"
                                          message : @"Database not found"
                                          delegate: nil
                                          cancelButtonTitle : @"OK"
                                          otherButtonTitles : nil];
                [alertView show];
                return;
            }
            if([player numPacketsToRead] != 0){
                isYet = YES;
            }
//            NSLog(@"Packets to read = %lu",player.numPacketsToRead);
        }

        strFileName = [[text componentsSeparatedByString:@"/"]lastObject];
        NSString *strTmp = [NSString stringWithFormat:@"%@\nTap on imageview to start reproduction",strFileName];
        _Info.text = strTmp;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    backColor = [UIColor colorWithRed:0.0625f green:0.25f blue:0.125f alpha:1.0f];
    self.view.backgroundColor = backColor;
    int orientation = self.interfaceOrientation;
    if(orientation == UIInterfaceOrientationPortrait){
        iOrientation = 0;
//        NSLog(@"Portrait");
    }
    else if(orientation == UIInterfaceOrientationPortraitUpsideDown){
        iOrientation = 2;
//        NSLog(@"Portrait upside-down");
    }
    else if(orientation == UIInterfaceOrientationLandscapeLeft){
        iOrientation = 1;
//        NSLog(@"landscape left");
    }
    else{
        iOrientation = 3;
//        NSLog(@"landscape right");
    }
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        sTopMargin = 16;
        _Info.font = [UIFont systemFontOfSize:24];
        iniWidth = 1020;
    }
    else{
        sTopMargin = 4;
        _Info.font = [UIFont systemFontOfSize:16];
        iniWidth = 480;
    }
    if(player && player.isPlaying)
        return;
    NSNotificationCenter* center;
    center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(sopaReproductionFinished)
                   name:@"sopaReproductionFinished" object:player];
    [center addObserver:self selector:@selector(sopaInfo)
                   name:@"sopaInfo" object:player];
    [center addObserver:self selector:@selector(errorDetection)
                   name:@"errorDetection" object:player];
    
    iOffset = 0;
    isRotate = FALSE;
    sCurrentRoll = sCurrentX = 0;
    fStamp = 0.0;

    manager = [[CMMotionManager alloc] init];
    player = [[SopaQueue alloc]init];
    _Info.textAlignment = NSTextAlignmentCenter;
    _Info.backgroundColor = [UIColor clearColor];
    _Info.textColor = [UIColor lightTextColor];
    _Info.numberOfLines = 4;
    [self.view addSubview:_Info];
    [self.view addSubview:_Segue];
    [self configureView];

    myIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:myIndicator];
    [myIndicator setColor:[UIColor blueColor]];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)gyroOn:(id)sender{
    NSString *newStr;
    int iVal = player.numSampleRate;
    if (((UISwitch*)sender).on){
        if(!player.isPlaying){
            self.navigationItem.hidesBackButton = YES;
        }   
        newStr = [NSString stringWithFormat:@"%@\nSampling rate %d Hz\nRotate device to control the panning\nTap on imageview to stop reproduction",strFileName,iVal];
        fStamp = 0;
        isMotion = NO;
        [self setMotion];
    }
    else{
        _Segue.textAlignment = NSTextAlignmentRight;
        _Segue.textColor = [UIColor whiteColor];
        if(manager.isGyroActive) {
            [manager stopGyroUpdates];
            isMotion = NO;
        }
        newStr = [NSString stringWithFormat:@"%@\nSampling rate %d Hz\nScroll imageview to control the panning\nTap on imageview to stop reproduction",strFileName,iVal];
        scrollview.scrollEnabled = YES;
        if(!player.isPlaying)
            [self hidesButton:NO];
        _Segue.text = @"Self motion";
    }
    if(player.isPlaying)
        _Info.text = newStr;
}

-(void)setMotion{
    NSLog(@"setMotion called");
    if(!isMotion){
        isMotion = YES;
        if (manager.gyroAvailable){
            scrollview.scrollEnabled = NO;
            sCurrentRoll = sCurrentX;

            _Segue.textAlignment = NSTextAlignmentCenter;
            _Segue.textColor = [UIColor yellowColor];
            _Segue.text = @"It drains the power in this mode!";

            manager.gyroUpdateInterval = 0.1;               //10 Hz
            CMGyroHandler   deviceMotionHandler;
            deviceMotionHandler = ^ (CMGyroData* data, NSError* error) {
                double dRoll;
                if(fStamp == 0)
                    dRoll = 0;
                else{
                    double dElapsed = data.timestamp - fStamp;
                    dRoll = dElapsed / M_PI;
                }
                fStamp = data.timestamp;
                if(iOrientation == 0)
                    dRoll *= -data.rotationRate.y;
                else if(iOrientation == 2)
                    dRoll *= data.rotationRate.y;
                else if(iOrientation == 1)
                    dRoll *= data.rotationRate.x;
                else
                    dRoll *= -data.rotationRate.x;
                dRoll *= imageWidth / 2;
                SInt16 sRoll = dRoll;
                sCurrentRoll += sRoll;
                if(sCurrentRoll <= 0){
                    sCurrentRoll += imageWidth;
                }
                else if(sCurrentRoll >= imageWidth * 2 - iniWidth){
                    sCurrentRoll -= imageWidth;
                }
                sCurrentX = sCurrentRoll;
                scrollview.contentOffset = CGPointMake(sCurrentRoll,0);
                double dVal = (double)sCurrentRoll - (double)imageWidth;
                dVal /= (double)imageWidth;
                dVal *= -72;
                if(isYet)
                    [player setIRot:(SInt16)dVal];
            };
           [manager startGyroUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:deviceMotionHandler];
        }
    }
    else{
        return;
    }
}

- (void)setDetailItem:(id)newDetailItem
{
    if(_detailItem != newDetailItem){
        _detailItem = newDetailItem;
        
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self.view];

    if(isYet){
        if(location.y < scrollview.frame.size.height + sTopMargin && location.y > sTopMargin){
            if([player isPlaying] == NO){
                isTerminatedByUser = NO;
                [myIndicator startAnimating];
                [self performSelector:@selector(hidesButton:)withObject:@"YES" afterDelay:0.1];
                [player play];                      // Start reproduction
                _Info.text = @"Searching for a SOPA file";
                NSLog(@"Reproducing SOPA");
            }
            else{
                isTerminatedByUser = YES;
                [player setIsPlaying:NO];
                [player stop:YES];                  // Stop reproduction
            }
        }
    }
}

-(void)hidesButton:(BOOL)isBool{
    self.navigationItem.hidesBackButton = isBool;
}

-(void)scrollViewDidScroll:(UIScrollView *)sender{
    CGPoint p = [sender contentOffset];
    SInt16 width = imageWidth;
    double dVal;
    
    if(isMotion)
        return;
    sCurrentX = p.x;
    if(p.x <= 0){
        sender.contentOffset = CGPointMake(width + iOffset + (SInt16)p.x,0);
    }
    else if(p.x >= width * 2 - iniWidth){
        sender.contentOffset = CGPointMake((SInt16)p.x - width,0);
    }
    dVal = (double)p.x - (double)imageWidth;
    dVal /= (double)imageWidth;
    dVal *= -72;
    if(isYet)
        [player setIRot:(SInt16)dVal];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return TRUE;
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    BOOL isAnimate = TRUE;
    if(interfaceOrientation == UIInterfaceOrientationPortrait){
        iOrientation = 0;
//        NSLog(@"Portrait");
    }
    else if(interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown){
        iOrientation = 2;
//        NSLog(@"Portrait upside-down");
    }
    else if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft){
        iOrientation = 1;
//        NSLog(@"Landscape left");
    }
    else{
        iOrientation = 3;
//        NSLog(@"Landscape right");
    }
    if(isAnimate){
        isRotate = TRUE;
        [self configureView];
    }
}

-(void)errorDetection{
    if([player isPlaying] == NO){
        [myIndicator stopAnimating];
        return;
    }
    else{
        [player setIsPlaying:NO];
        [player stop:YES];                  // Stop reproduction
    }
}

-(void)sopaInfo{
    NSString *newStr;
    int iVal = player.numSampleRate;

    if(isMotion)
        newStr = [NSString stringWithFormat:@"%@\nSampling rate %d Hz\nRotate device to control the panning\nTap on imageview to stop reproduction",strFileName,iVal];
    else
        newStr = [NSString stringWithFormat:@"%@\nSampling rate %d Hz\nScroll imageview to control the panning\nTap on imageview to stop reproduction",strFileName,iVal];
    _Info.text = newStr;
    [myIndicator stopAnimating];
    [self hidesButton:YES];
}

-(void)sopaReproductionFinished{
    UInt32 uVal = player.numBytesWritten;
    NSString *newStr;
    
    if(isTerminatedByUser)
        newStr = [NSString stringWithFormat:@"%@\n%lu bytes reproduced\nand terminated",strFileName,uVal];
    else
        newStr = [NSString stringWithFormat:@"%@\n%lu bytes reproduced\nand finished",strFileName,uVal];
    _Info.text = newStr;
    if(isMotion){
        _Segue.textAlignment = NSTextAlignmentRight;
        _Segue.text = @"Gyro is still running!";
    }
    else
        [self hidesButton:NO];
}

-(void)didRotate:(id)sender{
    UIDeviceOrientation orientation = [[UIDevice currentDevice]orientation];
    if(orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown){
        NSLog(@"Portrait");
    }
    else
        NSLog(@"Landscape");
}

- (void)dealloc {
    if([player isPlaying])
        [player stop:YES];
    if (manager.gyroActive) {
        [manager stopGyroUpdates];
    }
    [myIndicator removeFromSuperview];
    NSLog(@"%@: %@", NSStringFromSelector(_cmd), self);

    [[NSNotificationCenter defaultCenter] removeObserver:nil];
}

@end