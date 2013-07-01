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
-(void)databaseFromDir;

@end

@implementation ViewController{
    id detailItem;
    UILabel *Info;
    UILabel *Segue;
    UIImageView *imageView;
    NSString *strFileName;
    NSMutableData *imageData;
    
    UIColor *backColor;
    SInt16 iOrientation;
    SInt16 iPrevious;
    SInt16 sCurrentX;
    SInt16 iOffset;
    SInt16 imageWidth;
    SInt16 sAdj;
    SInt16 sTopMargin;
    SInt16 sCurrentRoll;
    SInt16 statusCode;
    SInt16 sSeaching;
    SInt16 sHoriSize;
    SInt16 sVerSize;
    float fStamp;
    
    BOOL isRotate;
    BOOL isYet;
    BOOL isTerminatedByUser;
    BOOL isMotion;
    BOOL isFromDir;
    BOOL isUpsideDown;
    CMMotionManager *manager;
    
}

@synthesize detailItem = _detailItem;;
@synthesize Info = _Info;
@synthesize Segue = _Segue;
@synthesize imageConn = _imageConn;
@synthesize mtnSwitch;
@synthesize imageData = _imageData;
@synthesize manager = _manager;

- (void)configureView
{
    // Update the user interface for the detail item.
    
    NSURL *tmpUrl,*newUrl;
    NSString *text,*gifPath;
    SInt16 height,iTmp;
    SInt16 iTimeout = 20;
    double dRatio,dWidth;
    
    if(!isRotate){
        text = player.urlStr;
        if(sSeaching == 0){
            NSURL *url = [[NSURL alloc]initWithString:text];
            
            NSRange rang = [text rangeOfString:@"://"];
            if(rang.location == NSNotFound){
                NSString *newStr = [text stringByDeletingPathExtension];
                gifPath = [[NSBundle mainBundle] pathForResource:newStr ofType:@"gif"];
                _imageData = [NSData dataWithContentsOfFile:gifPath];
                if(!_imageData){
                    gifPath = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"gif"];
                    _imageData = [NSData dataWithContentsOfFile:gifPath];
                    if(!_imageData){
                        [myIndicator stopAnimating];
                        _Segue.textColor = [UIColor orangeColor];
                        _Segue.text = @"Sorry, file not found";
                        return;
                    }
                }
                sSeaching = -1;
            }
            else {
                tmpUrl = url.URLByDeletingPathExtension;
                newUrl = [tmpUrl URLByAppendingPathExtension:@"gif"];
                NSURLRequest *request = [NSURLRequest requestWithURL:newUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:iTimeout];
                _imageConn = [[NSURLConnection alloc]initWithRequest : request delegate : self];
                if (_imageConn == nil) {
                    tmpUrl = [url URLByDeletingLastPathComponent];
                    newUrl = [tmpUrl URLByAppendingPathComponent:@"default.gif"];
                    NSURLRequest *request = [NSURLRequest requestWithURL:newUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:iTimeout];
                    _imageConn = [[NSURLConnection alloc]initWithRequest : request delegate : self];
                    if(_imageConn == nil){
                        gifPath = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"gif"];
                        _imageData = [NSData dataWithContentsOfFile:gifPath];
                        sSeaching = -1;
                    }
                    else
                        return;
                }
                else
                    return;
            }
        }
        else if(sSeaching == 1){
            NSURL *url = [[NSURL alloc]initWithString:text];
            tmpUrl = [url URLByDeletingLastPathComponent];
            newUrl = [tmpUrl URLByAppendingPathComponent:@"default.gif"];
            NSURLRequest *request = [NSURLRequest requestWithURL:newUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:iTimeout];
            _imageConn = [[NSURLConnection alloc]initWithRequest : request delegate : self];
            return;
        }
        [player setIRot:0];
        
        _Segue.numberOfLines = 2;
        if(!_manager.gyroAvailable){
            mtnSwitch.enabled = NO;
            _Segue.textColor = [UIColor yellowColor];
            _Segue.textAlignment = NSTextAlignmentRight;
            _Segue.text = @"Self motion mode is not available\non this device";
        }
        else if(isMotion){
            mtnSwitch.enabled = YES;
            _Segue.textAlignment = NSTextAlignmentCenter;
            _Segue.textColor = [UIColor yellowColor];
            _Segue.text = @"Using gyro sensor dorains the power!\n-mySopa- Copyright (c) 2013, AIST";
        }
        else{
            mtnSwitch.enabled = YES;
            _Segue.textAlignment = NSTextAlignmentRight;
            _Segue.text = @"Self motion\n";
        }
        
        UIImage *img    = [[UIImage alloc] initWithData:_imageData];
        _imageData = nil;
        UIImageView *imageView0 = [[UIImageView alloc]initWithImage:img];
        UIImageView *imageView1 = [[UIImageView alloc]initWithImage:img];
        
        imageWidth = imageView0.frame.size.width;
        dRatio = (double)sVerSize * 4 / (double)imageWidth;
        dWidth = (double)imageWidth * dRatio;
        imageWidth = (SInt16)dWidth;
        height = imageView0.frame.size.height;
        dWidth = (double)height * dRatio;
        height = (SInt16)dWidth;
        [imageView0 setFrame:CGRectMake(0.0, 0.0, imageWidth, height)];
        [imageView1 setFrame:CGRectMake(imageWidth, 0.0, imageWidth, height)];
        
        [imageView removeFromSuperview];
        [scrollview removeFromSuperview];
        
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
            sAdj = 32;
            scrollview = [[scroller alloc]initWithFrame:CGRectMake(0.0,sTopMargin,sVerSize,height)];
        }
        else{
            sAdj = 18;
            scrollview = [[scroller alloc]initWithFrame:CGRectMake(0.0,sTopMargin,sVerSize,height)];
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
    if(sSeaching != -1)
        return;
    int orientation = self.interfaceOrientation;
    if(orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown){
        iOffset = imageWidth / sAdj;
    }
    else{
        iOffset = 0;
    }
    if(isRotate){
        iTmp = scrollview.contentOffset.x;
        if(isUpsideDown)
            isUpsideDown = NO;
        else if(iOffset == 0){                                   // Portrait -> landscape
            iTmp -= imageWidth / sAdj;
            _Info.frame = CGRectMake(0,_Info.frame.origin.y,sVerSize,240);
        }
        else{
            iTmp += iOffset;
            _Info.frame = CGRectMake(0,_Info.frame.origin.y,sHoriSize,240);
        }
        scrollview.contentOffset = CGPointMake(iTmp,0);
        isRotate = FALSE;
    }
    else{
        if([player numPacketsToRead] != 0){
            isYet = YES;
        }
        scrollview.contentOffset = CGPointMake(imageWidth + iOffset,0);
        [myIndicator stopAnimating];
        NSString *strTmp = [NSString stringWithFormat:@"%@\nTap on imageview to start reproduction\nUse stereo headphones",strFileName];
        _Info.textColor = [UIColor lightTextColor];
        _Info.text = strTmp;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *waitPath;
    NSData *data;
    SInt16 height,sLeftMargin,sFontSize,sVerPos;
    
    backColor = [UIColor colorWithRed:0.0625f green:0.25f blue:0.125f alpha:1.0f];
    self.view.backgroundColor = backColor;
    
    int orientation = self.interfaceOrientation;
    iPrevious = orientation;
    
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
        //      iPad
        sTopMargin = 16;
        sHoriSize = 720;
        sVerSize = 1020;
        sVerPos = 192;
        if(iOrientation == 0 || iOrientation == 2){
            sLeftMargin = -170;
        }
        else{
            sLeftMargin = 0;
        }
        sFontSize = 24;
    }
    else{
        CGFloat scale = [[UIScreen mainScreen] scale];
        sHoriSize = 320;
        if(scale > 1.0){
            if([[ UIScreen mainScreen ] bounds ].size.height == 568)
            {
                //iphone 5
                sVerSize = 568;
                sVerPos = 56;
                sFontSize = 14;
                sTopMargin = 4;
                if(iOrientation == 0 || iOrientation == 2){
                    sLeftMargin = -95;
                }
                else{
                    sLeftMargin = 0;
                }
            }
            else
            {
                //iphone retina screen
                sTopMargin = 4;
                sVerSize = 480;
                sVerPos = 36;
                if(iOrientation == 0 || iOrientation == 2){
                    sLeftMargin = -80;
                }
                else{
                    sLeftMargin = 0;
                }
                sFontSize = 16;
            }
        }
        else{
            sTopMargin = 4;
            sVerSize = 480;
            sVerPos = 36;
            if(iOrientation == 0 || iOrientation == 2){
                sLeftMargin = -80;
            }
            else{
                sLeftMargin = 0;
            }
            sFontSize = 16;
        }
    }
    if(player && player.isPlaying)
        return;
    NSNotificationCenter* center;
    center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(sopaReproductionFinished)
                   name:@"sopaReproductionFinished" object:player];
    [center addObserver:self selector:@selector(sopaInfo)
                   name:@"sopaInfo" object:player];
    [center addObserver:self selector:@selector(databaseReady)
                   name:@"databaseReady" object:player];
    [center addObserver:self selector:@selector(databaseError)
                   name:@"databaseError" object:player];
    [center addObserver:self selector:@selector(errorDetection)
                   name:@"errorDetection" object:player];
    [center addObserver:self selector:@selector(connectionFailed)
                   name:@"connectionFailed" object:player];
    [center addObserver:self selector:@selector(fileError)
                   name:@"fileError" object:player];
    
    waitPath = [[NSBundle mainBundle] pathForResource:@"waiting1" ofType:@"gif"];
    data = [NSData dataWithContentsOfFile:waitPath];
    UIImage *img    = [[UIImage alloc] initWithData:data];
    
    imageView = [[UIImageView alloc]initWithImage:img];
    img = nil;
    double dheight = (double)sVerSize / 4.5;
    height = (SInt16)dheight;
    imageView.frame = CGRectMake(sLeftMargin,sTopMargin,sVerSize,height);
    
    if(iOrientation == 0 || iOrientation == 2)
        _Info = [[UILabel alloc] initWithFrame:CGRectMake(0,sVerPos,sHoriSize,240)];
    else
        _Info = [[UILabel alloc] initWithFrame:CGRectMake(0,sVerPos,sVerSize,240)];
    _Info.textAlignment = NSTextAlignmentCenter;
    _Info.backgroundColor = [UIColor clearColor];
    _Info.textColor = [UIColor lightTextColor];
    _Info.numberOfLines = 4;
    _Info.font = [UIFont systemFontOfSize:sFontSize];
    _Segue.font = [UIFont systemFontOfSize:sFontSize];
    
    isYet = NO;
    isMotion = NO;
    iOffset = 0;
    isRotate = FALSE;
    sCurrentRoll = sCurrentX = 0;
    sSeaching = statusCode = 0;
    fStamp = 0.0;
    
    _manager = [[CMMotionManager alloc] init];
    player = [[SopaQueue alloc]init];
    
    [self.view addSubview:_Info];
    
    _Segue.textColor = [UIColor lightTextColor];
    _Segue.numberOfLines = 2;
    [self.view addSubview:_Segue];
    _Segue.text = @"Welcome to the panoramic world\nPlease use stereo headphones";
    
    if(self.detailItem) {
        player.urlStr = [self.detailItem description];
    }
    else
        player.urlStr = @"sopa22k.sopa";
    
    [player setIsCanceled:NO];
    strFileName = [[player.urlStr componentsSeparatedByString:@"/"]lastObject];
    
    NSRange rang = [player.urlStr rangeOfString:@"://"];
    if(rang.location == NSNotFound){
        isFromDir = YES;
    }
    else
        isFromDir = NO;
    
    myIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:myIndicator];
    [myIndicator setColor:[UIColor blueColor]];
    
    [self.view addSubview:imageView];
    imageView = nil;
    
    NSString *strTmp = [NSString stringWithFormat:@"%@\nLoading database",player.urlStr];
    //  Load HRTF database
    [myIndicator startAnimating];
    _Info.textColor = [UIColor yellowColor];
    _Info.text = strTmp;
    [player setIStage:0];
    if(isFromDir){
        [self performSelector:@selector(databaseFromDir)withObject:nil afterDelay:0.1];     // Dummy
    }
    else{
        [player loadDatabase];
    }
}

-(void)databaseFromDir{
    [player loadDatabaseFromDir];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    // initialize data
	NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
	statusCode = [res statusCode];
    _imageData = [[NSMutableData alloc] initWithData:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    // append data
    [_imageData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSString *error_str = [error localizedDescription];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"RequestError" message:error_str delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    [myIndicator stopAnimating];
    _Segue.text = @"Request error";
    statusCode = 0;
    _imageData = nil;
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    connection = nil;
    if(statusCode == 200){
        sSeaching = -1;
    }
    else{
        if(sSeaching == 1){
            sSeaching = -1;
            NSString *gifPath = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"gif"];
            _imageData = [NSData dataWithContentsOfFile:gifPath];
        }
        else
            sSeaching ++;
    }
    [self performSelector:@selector(configureView)withObject:nil afterDelay:0.1];
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
        if(_manager.isGyroActive) {
            [_manager stopGyroUpdates];
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
    if(!isMotion){
        isMotion = YES;
        if(_manager.gyroAvailable){
            scrollview.scrollEnabled = NO;
            sCurrentRoll = sCurrentX;
            
            _Segue.textAlignment = NSTextAlignmentCenter;
            _Segue.textColor = [UIColor yellowColor];
            _Segue.text = @"It drains the power in this mode!";
            
            _manager.gyroUpdateInterval = 0.1;               //10 Hz
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
                else if(sCurrentRoll >= imageWidth * 2 - sVerSize){
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
            [_manager startGyroUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:deviceMotionHandler];
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
                [player play];                      // Start reproduction
                _Info.text = @"Searching for a SOPA file";
            }
            else{
                isTerminatedByUser = YES;
                [player setIsPlaying:NO];
                [player stop:NO];                  // Stop reproduction
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
    else if(p.x >= width * 2 - sVerSize){
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
    BOOL isAnimate;
    if(!isYet)
        isAnimate = NO;
    else
        isAnimate = TRUE;
    if(interfaceOrientation == UIInterfaceOrientationPortrait){
        iOrientation = 0;
    }
    else if(interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown){
        iOrientation = 2;
    }
    else if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft){
        iOrientation = 1;
        if(iPrevious == UIInterfaceOrientationLandscapeRight)
            isUpsideDown = YES;
    }
    else{
        iOrientation = 3;
        if(iPrevious == UIInterfaceOrientationLandscapeLeft)
            isUpsideDown = YES;
    }
    iPrevious = interfaceOrientation;
    if(isAnimate){
        isRotate = TRUE;
        [self configureView];
    }
}

-(void)errorDetection{
    [myIndicator stopAnimating];
    
    if(player.isPlaying){
        [player setIsPlaying:NO];
        [player stop:NO];                  // Stop reproduction
    }
}

-(void)connectionFailed{
    [myIndicator stopAnimating];
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle : @"URL connection failed"
                              message:@"URL connection terminated by error!"
                              delegate : nil cancelButtonTitle : @"OK"
                              otherButtonTitles : nil];
    [alertView show];
    
    NSString *strWarning = @"Error detected while streaming";
    _Info.textColor = [UIColor orangeColor];
    _Info.text = strWarning;
    if(player.isPlaying)
        [player setIsPlaying:NO];
}

-(void)fileError{
    [myIndicator stopAnimating];
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle : @"Transmittion Error"
                              message:@"URL does not contain data!"
                              delegate : nil cancelButtonTitle : @"OK"
                              otherButtonTitles : nil];
    [alertView show];
    
    NSString *strWarning = [NSString stringWithFormat:@"%@\nseems to be a wrong URL",player.urlStr];
    _Info.textColor = [UIColor orangeColor];
    _Info.text = strWarning;
}

-(void)databaseReady{
    NSString *strTmp;
    
    strTmp = [NSString stringWithFormat:@"%@\nLoading imageview",player.urlStr];
    _Info.text = strTmp;
    [self performSelector:@selector(configureView)withObject:nil afterDelay:0.1];
}

-(void)databaseError{
    _Info.textColor = [UIColor redColor];
    _Info.text = @"Failed to load database";
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
    else{
        [self hidesButton:NO];
    }
}

-(void)didRotate:(id)sender{
    /*
     UIDeviceOrientation orientation = [[UIDevice currentDevice]orientation];
     if(orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown){
     NSLog(@"Portrait");
     }
     else
     NSLog(@"Landscape");
     */
}

- (void)dealloc {
    
    if([player isPlaying])
        [player stop:YES];
    else{
        [player cancelLoading];
        [player setIsCanceled:YES];
    }
    player = nil;
    
    if (_manager.gyroActive) {
        [_manager stopGyroUpdates];
    }
    _manager = nil;
    
    if(_imageConn != nil){
        [_imageConn cancel];
        _imageConn = nil;
    }
    if(_imageData != nil)
        _imageData = nil;
    [myIndicator removeFromSuperview];
    [scrollview removeFromSuperview];
    self.navigationItem.rightBarButtonItem = nil;
    //    NSLog(@"%@: %@", NSStringFromSelector(_cmd), self);
    
    [[NSNotificationCenter defaultCenter] removeObserver:nil];
}

@end