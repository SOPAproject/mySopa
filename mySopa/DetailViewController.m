//
//  DetailViewController.m
//  mySopa
//
//  Created by K. Ashihara on 29 Mar. 2014
//  Revised on 2 Mar. 2015
//  Copyright (c) 2015, AIST. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation DetailViewController{
    UILabel *myText;
    UIImageView *imageView;
    UIProgressView *reproductionBar;
    NSMutableData *headerData;
    NSURL *sopaUrl;
    BOOL is3d;
    BOOL isAsset;
    BOOL isSequel;
    BOOL isSS;
    UIDeviceOrientation sOrientation;
    SInt16 sFontSize;
    SInt16 iMilliSecIntvl;
    SInt16 iFirstJpg;
    SInt16 iFileNum;
    SInt16 iSR;             // Sample rate
    UInt32 uCS;             // Chunk size
}

@synthesize glView=_glView;
@synthesize conn;
@synthesize progressBar;

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.detailItem) {
        sopaUrl = [[NSURL alloc]initWithString:[[self.detailItem valueForKey:@"path"] description]];
    }
}

- (void)viewDidLoad
{
    SInt16 textPosShort,textPosLong;
    NSString *waitPath;
    SInt16 sProgressX = self.view.frame.size.width - 2;
    SInt16 sProgressY = self.view.frame.size.height - 2;
    float osVer = [[[UIDevice currentDevice] systemVersion] floatValue];
    
    [super viewDidLoad];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]){
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];

    myIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:myIndicator];
    [myIndicator setColor:[UIColor blueColor]];
    
    [myIndicator startAnimating];
    
    self.progressBar = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleBar];
    self.progressBar.progressTintColor = [UIColor blueColor];
    reproductionBar = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleBar];
    reproductionBar.trackTintColor = [UIColor clearColor];
    reproductionBar.progressTintColor = [UIColor greenColor];
    
    NSNotificationCenter* center;
    center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(databaseOK)
                   name:@"readyToGo" object:nil];
    [center addObserver:self selector:@selector(byImageError)
                   name:@"imageError" object:nil];
    [center addObserver:self selector:@selector(byError)
                   name:@"URLError" object:nil];
    [center addObserver:self selector:@selector(byError)
                   name:@"databaseError" object:nil];
    [center addObserver:self selector:@selector(transmitProgress)
                   name:@"connectionProgress" object:_glView];
    [center addObserver:self selector:@selector(reproductionProgress)
                   name:@"reproductionProgress" object:_glView];
    
    sOrientation = [[UIDevice currentDevice]orientation];
    if(sOrientation == UIDeviceOrientationPortrait){
        [self.progressBar setFrame:CGRectMake(0,sProgressY,self.view.frame.size.width,self.view.frame.size.height)];
        [reproductionBar setFrame:CGRectMake(0,sProgressY,self.view.frame.size.width,self.view.frame.size.height)];
        waitPath = [[NSBundle mainBundle] pathForResource:@"wait_portrait" ofType:@"gif"];
    }
    else{
        waitPath = [[NSBundle mainBundle] pathForResource:@"wait_landscape" ofType:@"gif"];
        if(osVer < 8){
            [self.progressBar setFrame:CGRectMake(0,sProgressX,self.view.frame.size.height,self.view.frame.size.width)];
            [reproductionBar setFrame:CGRectMake(0,sProgressX,self.view.frame.size.height,self.view.frame.size.width)];
        }
        else{
            [self.progressBar setFrame:CGRectMake(0,sProgressY,self.view.frame.size.width,self.view.frame.size.height)];
            [reproductionBar setFrame:CGRectMake(0,sProgressY,self.view.frame.size.width,self.view.frame.size.height)];
        }
    }
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    NSData *data = [NSData dataWithContentsOfFile:waitPath];
    UIImage *img    = [[UIImage alloc] initWithData:data];
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        //      iPad
        sFontSize = 24;
        textPosLong = self.view.frame.size.height * 3 / 4;
        textPosShort = self.view.frame.size.width / 2;
    }
    else{
        sFontSize = 16;
        textPosLong = self.view.frame.size.height * 3 / 5;
        textPosShort= self.view.frame.size.width / 3;
    }
    
    if(sOrientation == UIDeviceOrientationPortrait){
        myText = [[UILabel alloc]initWithFrame:CGRectMake(textPosShort,textPosLong,self.view.frame.size.width,self.view.frame.size.height / 4)];
    }
    else{
        myText = [[UILabel alloc]initWithFrame:CGRectMake(textPosLong,textPosShort,self.view.frame.size.width,self.view.frame.size.height / 4)];
//        myText = [[UILabel alloc]initWithFrame:CGRectMake(textPosLong,textPosShort,self.view.frame.size.height,self.view.frame.size.width)];
    }
    myText.textAlignment = NSTextAlignmentLeft;
    myText.backgroundColor = [UIColor clearColor];
    myText.textColor = [UIColor lightTextColor];
    myText.shadowColor = [UIColor darkTextColor];
    myText.numberOfLines = 3;
    myText.font = [UIFont systemFontOfSize:sFontSize];
    myText.text = @"mySopa is loading data.\nPlease wait for a while.";
    
    imageView = [[UIImageView alloc]initWithImage:img];

    if(osVer < 8){
        if(sOrientation == UIInterfaceOrientationPortrait){
            if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                imageView.frame = CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height * 1.33125);
            else if(self.view.frame.size.height / self.view.frame.size.width == 1.5)
                imageView.frame = CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height * 1136 / 960);
            else
                imageView.frame = CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height);
        }
        else{
            if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                imageView.frame = CGRectMake(0,0,self.view.frame.size.height * 1.33125,self.view.frame.size.width);
            else if(self.view.frame.size.width / self.view.frame.size.height == 1.5)
                imageView.frame = CGRectMake(0,0,self.view.frame.size.height * 1136 / 960,self.view.frame.size.width);
            else
                imageView.frame = CGRectMake(0,0,self.view.frame.size.height,self.view.frame.size.width);
        }
    }
    else{
        if(sOrientation == UIInterfaceOrientationPortrait){
            if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                imageView.frame = CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height * 1.33125);
            else if(self.view.frame.size.height / self.view.frame.size.width == 1.5)
                imageView.frame = CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height * 1136 / 960);
            else
                imageView.frame = CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height);
        }
        else{
            if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                imageView.frame = CGRectMake(0,0,self.view.frame.size.width * 1.33125,self.view.frame.size.height);
            else if(self.view.frame.size.width / self.view.frame.size.height == 1.5)
                imageView.frame = CGRectMake(0,0,self.view.frame.size.width * 1136 / 960,self.view.frame.size.height);
            else
                imageView.frame = CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height);
        }
    }
    [self.view addSubview:imageView];
    imageView = nil;
    
    [self.view addSubview:myText];
    
    NSString *sopaStr = [sopaUrl absoluteString];
    NSRange rang = [sopaStr rangeOfString:@"://"];
    if(rang.location == NSNotFound){
        isAsset = YES;
        NSString *tmpStr = [[NSBundle mainBundle] pathForResource:@"default_cube" ofType:@"png"];
        NSString *newStr = [tmpStr stringByDeletingLastPathComponent];
        tmpStr = [newStr stringByAppendingPathComponent:sopaStr];
        sopaUrl = [[NSURL alloc]initFileURLWithPath:tmpStr];
        [self readSopaHeader:sopaUrl];
    }
    else{
        isAsset = NO;
        [self readSopaHeader:sopaUrl];
    }
}

-(void)setupGLView{
    CGRect screenRect;
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    SInt16 sNavHeight = self.navigationController.navigationBar.bounds.size.height;
    float osVer = [[[UIDevice currentDevice] systemVersion] floatValue];
    
    if(osVer < 8){
        if(sOrientation == UIInterfaceOrientationPortrait)
            screenRect = CGRectMake(0,sNavHeight,screenBounds.size.width,screenBounds.size.height - sNavHeight);
        else
            screenRect = CGRectMake(0,sNavHeight,screenBounds.size.height,screenBounds.size.width - sNavHeight);
    }
    else{
        if(sOrientation == UIInterfaceOrientationPortrait)
            screenRect = CGRectMake(0,sNavHeight,screenBounds.size.width,screenBounds.size.height - sNavHeight);
        else
            screenRect = CGRectMake(0,sNavHeight,screenBounds.size.width,screenBounds.size.height - sNavHeight);
    }
    if(self.conn){
        [[self conn]cancel];
        self.conn = nil;
    }
    
    [self checkTxt];
    
    self.glView = [[OpenGLView alloc] initWithFrame:screenRect];
    self.glView.myOrientation = sOrientation;
    
    if(is3d)
        self.glView.is3d = YES;
    else
        self.glView.is3d = NO;
    if(isAsset)
        self.glView.isAsset = YES;
    else
        self.glView.isAsset = NO;
    self.glView.urlStr = [sopaUrl absoluteString];
    self.glView.sFontSize = sFontSize;
    self.glView.nSR = iSR;
    self.glView.expectedLength = uCS;
    self.glView.isSequel = isSequel;
    self.glView.isSS = isSS;
    self.glView.iMilliSecIntvl = iMilliSecIntvl;
    self.glView.iFirstJpg = iFirstJpg;
    self.glView.iFirstSopa = iFileNum;
    
    [self.glView makeWorld];
    [self.view addSubview:_glView];
    [self.glView setupDatabase];
    [self.view addSubview:self.progressBar];
    [self.view addSubview:reproductionBar];
}

-(void)checkTxt{
    NSError *err = nil;
    NSString *txtStr,*myStr;
    NSURL *tmpUrl,*myURL;
    NSString *tmpStr = [sopaUrl absoluteString];
    
    NSRange range = [tmpStr rangeOfString:@"00.sopa"];
    if(range.location == NSNotFound){
        isSequel = NO;
        myURL = [sopaUrl URLByDeletingPathExtension];
        tmpUrl = [myURL URLByAppendingPathExtension:@"txt"];
    }
    else{
        isSequel = YES;
        myStr = [tmpStr substringToIndex:tmpStr.length - 7];
        myURL = [[NSURL alloc]initWithString:myStr];
        tmpUrl = [myURL URLByAppendingPathExtension:@"txt"];
    }
    txtStr = [tmpUrl absoluteString];
    NSURL *txtURL = [[NSURL alloc]initWithString:txtStr];
    UInt32 uSkipSamples = 0;
    
    iMilliSecIntvl = 2000;
    NSString *str = [NSString stringWithContentsOfURL:txtURL encoding:NSUTF8StringEncoding error:&err];
    range = [str rangeOfString:@"\n"];
    if(str.length == 0 || range.location == NSNotFound){
        isSS = NO;
    }
    else{
        isSS = YES;
        NSString *subStr = [str substringToIndex:range.location];
        iFirstJpg = [subStr intValue];
        //    iFirstJpg = 0;
        
        subStr = [str substringFromIndex:range.location + 1];
        iMilliSecIntvl = [subStr intValue];
        uSkipSamples = iSR * iMilliSecIntvl * iFirstJpg / 1000;
        iFileNum = uSkipSamples * 4 / uCS;
        
        if(isSequel){
            NSString *strSopa = [NSString stringWithFormat:@"%02d.sopa",iFileNum];
            NSString *newStr = [tmpStr stringByReplacingOccurrencesOfString:@"00.sopa" withString:strSopa];
            sopaUrl = [[NSURL alloc]initWithString:newStr];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)databaseOK{
    [myIndicator stopAnimating];
}

-(void)byImageError{
    [myIndicator stopAnimating];
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle : @"URL connection failed"
                              message:@"URL connection terminated by error!"
                              delegate : self cancelButtonTitle : @"OK"
                              otherButtonTitles : nil];
    [alertView show];
    myText.text = @"mySopa failed to load image.";
}

-(void)byError{
    [myIndicator stopAnimating];
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle : @"URL connection failed"
                              message:@"URL connection terminated by error!"
                              delegate : self cancelButtonTitle : @"OK"
                              otherButtonTitles : nil];
    [alertView show];
    myText.text = @"mySopa failed to load data.";
}

-(void)readSopaHeader:(NSURL *)url {
    
//    NSURLRequest *req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0f];
    NSURLRequest *req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    conn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    
    if (conn==nil) {
        [myIndicator stopAnimating];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ConnectionError" message:@"ConnectionError" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        myText.text = @"mySopa failed to load data.";
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    headerData = [[NSMutableData alloc] initWithData:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [headerData appendData:data];
    NSData *val0;
    SInt16 nSampleRate;
    UInt32 uChunkSize;
    
    if(headerData.length > 44){
        val0 = (NSMutableData *)[headerData subdataWithRange:NSMakeRange(24,1)];
        nSampleRate = *(int *)([val0 bytes]);
        val0 = (NSMutableData *)[headerData subdataWithRange:NSMakeRange(25,1)];
        nSampleRate += *(int *)([val0 bytes]) * 256;
        iSR = nSampleRate;
        val0 = (NSData *)[headerData subdataWithRange:NSMakeRange(39,1)];
        if(*(int *)([val0 bytes]) <= 1){
            is3d = NO;
        }
        else{
            is3d = YES;
        }
        val0 = (NSMutableData *)[headerData subdataWithRange:NSMakeRange(40,1)];
        uChunkSize = *(int *)([val0 bytes]);
        val0 = (NSMutableData *)[headerData subdataWithRange:NSMakeRange(41,1)];
        uChunkSize += *(int *)([val0 bytes]) * 256;
        val0 = (NSMutableData *)[headerData subdataWithRange:NSMakeRange(42,1)];
        uChunkSize += *(int *)([val0 bytes]) * 65536;
        val0 = (NSMutableData *)[headerData subdataWithRange:NSMakeRange(43,1)];
        uChunkSize += *(int *)([val0 bytes]) * 16777216;
        uCS = uChunkSize;
        
        headerData = nil;
        [self setupGLView];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSString *error_str = [error localizedDescription];
    [myIndicator stopAnimating];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"RequestError" message:error_str delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    myText.text = @"mySopa failed to load data.";
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

-(void)transmitProgress{
    [self.progressBar setProgress:(long double)[_glView nBytesRead] / (long double)[_glView expectedLength]];
}

-(void)reproductionProgress{
    if(_glView.nBytesRead == 0){
        self.progressBar.progress = 0;
        reproductionBar.progress = 0;
    }
    else if([_glView nBytesWritten] < [_glView expectedLength])
        reproductionBar.progress = (long double)[_glView nBytesWritten] / (long double)[_glView expectedLength];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if(conn != nil)
        [conn cancel];
    [self.glView finalizeView];
}

-(void)dealloc{
    [self.glView removeFromSuperview];
    [myIndicator removeFromSuperview];
    self.navigationItem.rightBarButtonItem = nil;
    //    NSLog(@"%@: %@", NSStringFromSelector(_cmd), self);
    
    [[NSNotificationCenter defaultCenter] removeObserver:nil];
    
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Back", @"Back");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

@end
