//
//  ViewController.m
//  mySopa
//
//  Created by Kaoru Ashihara on 13/10/03.
//  Copyright (c) 2013, AIST. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController{
    id detailItem;
    UILabel *myText;
    UIImageView *imageView;
    UIProgressView *reproductionBar;
    NSMutableData *headerData;
    NSURL *sopaUrl;
    BOOL is3d;
    UIDeviceOrientation sOrientation;
    SInt16 sFontSize;
}

@synthesize glView=_glView;
@synthesize detailItem = _detailItem;;
@synthesize conn;
@synthesize progressBar;

- (id)initView
{
    self = [super init];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    SInt16 textPosShort,textPosLong;
    NSString *waitPath;
    [super viewDidLoad];
    
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
    [center addObserver:self selector:@selector(byError)
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
        [self.progressBar setFrame:CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height)];
        [reproductionBar setFrame:CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height)];
        waitPath = [[NSBundle mainBundle] pathForResource:@"wait_portrait" ofType:@"gif"];
    }
    else{
        waitPath = [[NSBundle mainBundle] pathForResource:@"wait_landscape" ofType:@"gif"];
        [self.progressBar setFrame:CGRectMake(0,0,self.view.frame.size.height,self.view.frame.size.width)];
        [reproductionBar setFrame:CGRectMake(0,0,self.view.frame.size.height,self.view.frame.size.width)];
    }
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];

    NSData *data = [NSData dataWithContentsOfFile:waitPath];
    UIImage *img    = [[UIImage alloc] initWithData:data];
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        //      iPad
        sFontSize = 24;
        textPosLong = self.view.frame.size.height / 2;
        textPosShort = self.view.frame.size.width / 6;
    }
    else{
        sFontSize = 16;
        textPosLong = self.view.frame.size.height / 3;
        textPosShort= self.view.frame.size.width / 8;
    }

    if(sOrientation == UIDeviceOrientationPortrait){
        myText = [[UILabel alloc]initWithFrame:CGRectMake(textPosShort,textPosLong,self.view.frame.size.width,self.view.frame.size.height / 4)];
    }
    else{
        myText = [[UILabel alloc]initWithFrame:CGRectMake(textPosLong,textPosShort,self.view.frame.size.height,self.view.frame.size.width)];
    }
    myText.textAlignment = NSTextAlignmentLeft;
    myText.backgroundColor = [UIColor clearColor];
    myText.textColor = [UIColor lightTextColor];
    myText.shadowColor = [UIColor darkTextColor];
    myText.numberOfLines = 3;
    myText.font = [UIFont systemFontOfSize:sFontSize];
    myText.text = @"mySopa is loading data.\nPlease wait for a while.";
    
    imageView = [[UIImageView alloc]initWithImage:img];
    
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
        else if(self.view.frame.size.height / self.view.frame.size.width == 1.5)
            imageView.frame = CGRectMake(0,0,self.view.frame.size.height * 1136 / 960,self.view.frame.size.width);
        else
            imageView.frame = CGRectMake(0,0,self.view.frame.size.height,self.view.frame.size.width);
    }
    [self.view addSubview:imageView];
    imageView = nil;    
    
    [self.view addSubview:myText];
    
    if(self.detailItem){
        sopaUrl = [[NSURL alloc]initWithString:[self.detailItem description]];
    }
    else{
        myText.text = @"mySopa could not find the SOPA data.";
        [myIndicator stopAnimating];
        return;
    }

    NSString *sopaStr = [sopaUrl absoluteString];
    NSRange rang = [sopaStr rangeOfString:@"://"];
    if(rang.location == NSNotFound){
        is3d = YES;
        [self setupGLView];
    }
    else
        [self readSopaHeader:sopaUrl];
    
}

-(void)setupGLView{
    CGRect screenRect;
    CGRect screenBounds = [[UIScreen mainScreen] bounds];

    if(sOrientation == UIInterfaceOrientationPortrait)
        screenRect = screenBounds;
    else
        screenRect = CGRectMake(0,0,screenBounds.size.height,screenBounds.size.width);
    
    if(self.conn){
        [[self conn]cancel];
        self.conn = nil;
    }
    
    self.glView = [[OpenGLView alloc] initWithFrame:screenRect];

    self.glView.myOrientation = sOrientation;

    if(is3d)
        self.glView.is3d = YES;
    else
        self.glView.is3d = NO;
    self.glView.urlStr = [sopaUrl absoluteString];
    self.glView.sFontSize = sFontSize;
    
    [self.glView makeWorld];
    [self.view addSubview:_glView];
    [self.glView setupDatabase];
    [self.view addSubview:self.progressBar];
    [self.view addSubview:reproductionBar];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)databaseOK{
    [myIndicator stopAnimating];
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
    
    NSURLRequest *req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0f];
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
    
    if(headerData.length > 44){
        NSData *val0 = (NSData *)[headerData subdataWithRange:NSMakeRange(39,1)];
        if(*(int *)([val0 bytes]) <= 1){
            is3d = NO;
        }
        else{
            is3d = YES;
        }
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

- (unsigned)supportedInterfaceOrientations {
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
    else
        reproductionBar.progress = (long double)[_glView nBytesWritten] / (long double)[_glView expectedLength];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.glView finalizeView];
    [super viewWillDisappear:animated];
}

-(void)dealloc{
    [self.glView removeFromSuperview];
    [myIndicator removeFromSuperview];
    self.navigationItem.rightBarButtonItem = nil;
//    NSLog(@"%@: %@", NSStringFromSelector(_cmd), self);
    
    [[NSNotificationCenter defaultCenter] removeObserver:nil];

}

@end
