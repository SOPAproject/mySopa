//
//  OpenGLView.m
//  mySopa
//
//  Created by Kaoru Ashihara on 29 Mar. 2014
//  Copyright (c) 2014, AIST. All rights reserved.
//

#import "OpenGLView.h"
#import "CC3GLMatrix.h"

@implementation OpenGLView{
    NSString *labelText,*offText,*onText,*mtnText;
    NSMutableData *async_data;
    NSURL *jpgURL;
    float fStamp;
    double dYaw;
    double dPitch;
    double dThrsld;
    double dPan,dTilt;
    double dCurrentX,dCurrentY;
    BOOL isTerminatedByUser;
    BOOL isBtnOn,isPad,isPrepared;
    BOOL isSearchJpg;
    BOOL isImageLoading;
    BOOL isImageReady;
    UInt16 uPitchRoll;
    UInt16 uJpgNum;
    SInt16 sWidth,sHeight;
    SInt16 imageWidth,imageHeight;
    SInt16 sMotion;
    CADisplayLink* displayLink;
    CC3Vector vecVer;
    CC3Vector vecHor;
    CC3Vector vecAt,vecUp;
    CC3Vector vecDir[127];
    UILabel *myLabel;
    UILabel *mtnLabel,*tiltLabel;
    UIButton *mtnBtn,*tiltBtn;
    GLubyte *spriteData;
}

@synthesize urlStr;
@synthesize imageConn = _imageConn;
@synthesize myImage = _myImage;
@synthesize nBytesRead;
@synthesize nBytesWritten;
@synthesize myOrientation;
@synthesize is3d;
@synthesize isRotated;
@synthesize isManagerOn;
@synthesize isAsset;
@synthesize isSequel;
@synthesize isSS;
@synthesize sFontSize;
@synthesize iFirstJpg;
@synthesize iFirstSopa;
@synthesize iMilliSecIntvl;
@synthesize nSR;
@synthesize expectedLength;
@synthesize dRoll;

typedef struct {
    float Position[3];
    float Color[4];
    float TexCoord[2];
} Vertex;

typedef struct{
    float fReal;
    float fX;
    float fY;
    float fZ;
}quaternion;

const Vertex Vertices[] = {
    // Front
    {{8, -8, 8}, {1, 1, 1, 1}, {0, 0.5}},
    {{8, 8, 8}, {1, 1, 1, 1}, {0, 0}},
    {{-8, 8, 8}, {1, 1, 1, 1}, {0.25, 0}},
    {{-8, -8, 8}, {1, 1, 1, 1}, {0.25, 0.5}},
    // Back
    {{8, 8, -8}, {1, 1, 1, 1}, {0.75, 0}},
    {{-8, 8, -8}, {1, 1, 1, 1}, {0.5, 0}},
    {{-8, -8, -8}, {1, 1, 1, 1}, {0.5, 0.5}},
    {{8, -8, -8}, {1, 1, 1, 1}, {0.75, 0.5}},
    // Right
    {{-8, -8, 8}, {1, 1, 1, 1}, {0.25, 0.5}},
    {{-8, 8, 8}, {1, 1, 1, 1}, {0.25, 0}},
    {{-8, 8, -8}, {1, 1, 1, 1}, {0.5,0}},
    {{-8, -8, -8}, {1, 1, 1, 1}, {0.5, 0.5}},
    // Left
    {{8, -8, -8}, {1, 1, 1, 1}, {0.75, 0.5}},
    {{8, 8, -8}, {1, 1, 1, 1}, {0.75, 0}},
    {{8, 8, 8}, {1, 1, 1, 1}, {1, 0}},
    {{8, -8, 8}, {1, 1, 1, 1}, {1, 0.5}},
    // Top
    {{8, 8, 8}, {1, 1, 1, 1}, {0.25, 1}},
    {{8, 8, -8}, {1, 1, 1, 1}, {0.25, 0.5}},
    {{-8, 8, -8}, {1, 1, 1, 1}, {0.5, 0.5}},
    {{-8, 8, 8}, {1, 1, 1, 1}, {0.5, 1}},
    // Bottom
    {{8, -8, -8}, {1, 1, 1, 1}, {0,1}},
    {{8, -8, 8}, {1, 1, 1, 1}, {0,0.5}},
    {{-8, -8, 8}, {1, 1, 1, 1}, {0.25,0.5}},
    {{-8, -8, -8}, {1, 1, 1, 1}, {0.25,1}}
};

const GLubyte Indices[] = {
    // Front
    0, 1, 2,
    2, 3, 0,
    // Back
    4, 5, 6,
    6, 7, 4,
    // Left
    8, 9, 10,
    10, 11, 8,
    // Right
    12, 13, 14,
    14, 15, 12,
    // Top
    16, 17, 18,
    18, 19, 16,
    // Bottom
    20, 21, 22,
    22, 23, 20
};

- (void)setupVBOs {
    
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
}

- (void)setupDisplayLink {
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    displayLink.frameInterval = 2;
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (GLuint)setupTexture:(NSString *)fileName {
    CGImageRef spriteImage;
    // 1
    if(player.isFromDir)
        spriteImage = [UIImage imageNamed:fileName].CGImage;
    else{
        spriteImage = _myImage.CGImage;
        if(!spriteImage){
            spriteImage = [UIImage imageNamed:fileName].CGImage;
        }
    }
    if(!spriteImage){
        //        [self prepareToExit];
        return 0;
    }
    
    // 2
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    imageWidth = width;
    imageHeight = height;
    
    spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    
    // 3
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    // 4
    GLuint texName;
    glGenTextures(1, &texName);
        
    if(player.numBytesWritten == 0){
        glBindTexture(GL_TEXTURE_2D, texName);
    
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)width, (int)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
        free(spriteData);
        
        dTilt = dPan = 0;
        dCurrentX = dCurrentY = imageWidth;
        [self openScroller];
    }
    _myImage = nil;
    async_data = nil;
//    isPrepared = YES;
    isImageReady = NO;
    
    return texName;
    
}

- (id)initWithFrame:(CGRect)frame
{
    UInt16 btnUnit;
    dThrsld = M_PI / 16;
    sMotion = 0;
    isManagerOn = NO;
    isBtnOn = NO;
    isPrepared = NO;
    isImageLoading = NO;
    isImageReady = NO;
    isSequel = NO;
    isSS = NO;
    uJpgNum = 0;
    
    self = [super initWithFrame:frame];
    if(self){
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){   //      iPad
            isPad = YES;
        }
        else{
            isPad = NO;
        }
        
        myOrientation = [[UIDevice currentDevice]orientation];
        sWidth = self.frame.size.width;
        sHeight = self.frame.size.height;
        if(myOrientation == UIInterfaceOrientationPortrait)
            btnUnit = sWidth / 12;
        else
            btnUnit = sHeight /12;
        dYaw = dPitch = 0;
        dRoll = 0;
        
        mtnBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        mtnBtn.frame = CGRectMake(sWidth * 4 / 5,sHeight * 5 / 6,btnUnit,btnUnit);
        mtnBtn.backgroundColor = [UIColor orangeColor];
        [mtnBtn setOpaque: YES];
        [mtnBtn setAlpha:0.25f];
        [mtnBtn addTarget:self action:@selector(btnOnOff:) forControlEvents:UIControlEventTouchDown];
        
        tiltBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        tiltBtn.frame = CGRectMake(sWidth / 16,sHeight * 5 / 6,btnUnit,btnUnit);
        tiltBtn.backgroundColor = [UIColor yellowColor];
        [tiltBtn setOpaque:YES];
        [tiltBtn setAlpha:0.25f];
        [tiltBtn addTarget:self action:@selector(tiltOnOff:) forControlEvents:UIControlEventTouchDown];
        
        _manager = [[CMMotionManager alloc]init];
        if(!_manager.gyroAvailable){
            mtnBtn.enabled = NO;
            mtnText = @"Gyro is not available";
            offText = @"Pitch is off";
            onText = @"Pitch is on";
        }
        else{
            mtnText = @"Self Motion";
            offText = @"Pitch, roll are off";
            onText = @"Pitch, roll are on";
        }
        
        [self setupLayer];
        [self setupContext];
        [self setupDepthBuffer];
        [self setupRenderBuffer];
        [self setupFrameBuffer];
        [self compileShaders];
        [self setupVBOs];
        
        player = [[sopaObject alloc]init];
        [player setIsCanceled:NO];
        [player setIStage:0];
        
        NSNotificationCenter* center;
        center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(sopaReproductionFinished)
                       name:@"sopaReproductionFinished" object:player];
        [center addObserver:self selector:@selector(sopaInfo)
                       name:@"sopaInfo" object:player];
        [center addObserver:self selector:@selector(databaseReady)
                       name:@"databaseReady" object:player];
        [center addObserver:self selector:@selector(errorDetection)
                       name:@"errorDetection" object:player];
        [center addObserver:self selector:@selector(connectionFailed)
                       name:@"connectionFailed" object:player];
        [center addObserver:self selector:@selector(fileError)
                       name:@"fileError" object:player];
        [center addObserver:self selector:@selector(notifyProgress)
                       name:@"connectionProgress" object:player];
        [center addObserver:self selector:@selector(notifyReproduction)
                       name:@"reproductionProgress" object:player];
        [center addObserver:self selector:@selector(notifyNewImage)
                       name:@"getNewImage" object:player];
        
    }
    return  self;
}

-(void)makeWorld{
    double dVal,dCos;
    float fY,fX,fZ;
    SInt16 sInt;
    NSString *tmpStr;
    NSURL *tmpUrl;
    
    uJpgNum = iFirstJpg;
    
    player.urlStr = self.urlStr;
    player.numSampleRate = nSR;
    player.lChunkSize = expectedLength;
    player.isSequel = isSequel;
    player.isSS = isSS;
    player.iFileNum = iFirstSopa;
    player.iMilliSecIntvl = iMilliSecIntvl;
    
    tmpStr = [self.urlStr substringToIndex:self.urlStr.length - 7];
    if(player.isSequel){
        NSString *jpgStr = [tmpStr stringByAppendingFormat:@"%04u",uJpgNum];
        tmpUrl = [NSURL URLWithString:jpgStr];
        jpgURL = [tmpUrl URLByAppendingPathExtension:@"jpg"];
    }
    else{
        tmpUrl = [[NSURL alloc]initWithString:self.urlStr];
        NSURL *myURL = [tmpUrl URLByDeletingPathExtension];
        jpgURL = [myURL URLByAppendingPathExtension:@"jpg"];
    }

    mtnLabel = [[UILabel alloc]init];
    mtnLabel.text = mtnText;
    if(isPad){
        mtnLabel = [[UILabel alloc]initWithFrame:CGRectMake(sWidth * 4 / 5,sHeight * 3 / 4,sWidth / 4,sHeight / 16)];
        mtnLabel.textAlignment = NSTextAlignmentLeft;
    }
    else{
        mtnLabel = [[UILabel alloc]initWithFrame:CGRectMake(sWidth * 7 / 10,sHeight * 3 / 4,sWidth / 3,sHeight / 16)];
        mtnLabel.textAlignment = NSTextAlignmentCenter;
    }
    mtnLabel.backgroundColor = [UIColor clearColor];
    mtnLabel.textColor = [UIColor lightTextColor];
    mtnLabel.shadowOffset = CGSizeMake(1,1);
    mtnLabel.shadowColor = [UIColor darkTextColor];
    
    tiltLabel = [[UILabel alloc]init];
    tiltLabel = [[UILabel alloc]initWithFrame:CGRectMake(sWidth / 16,sHeight * 3 / 4,sWidth,sHeight / 16)];
    tiltLabel.textAlignment = NSTextAlignmentLeft;
    tiltLabel.backgroundColor = [UIColor clearColor];
    tiltLabel.textColor = [UIColor lightTextColor];
    tiltLabel.shadowOffset = CGSizeMake(1,1);
    tiltLabel.shadowColor = [UIColor darkTextColor];
    
    vecAt = CC3VectorMake(0,0,1);
    vecUp = CC3VectorMake(0,1,0);
    vecVer = CC3VectorMake(0,1,0);
    vecHor = CC3VectorCross(vecUp,vecAt);
    
    vecDir[0] = CC3VectorMake(0,1,0);
    
    if(is3d){
        for(sInt = 1;sInt < 9;sInt ++){
            dVal = 5 * M_PI / 12;
            fY = sin(dVal);
            dCos = cos(dVal);
            dVal = (double)sInt - 1;
            dVal *= M_PI / 4;
            fZ = cos(dVal) * dCos;
            fX = sin(dVal) * dCos;
            vecDir[sInt] = CC3VectorMake(-fX, fY, fZ);
        }
        for(sInt = 9;sInt < 25;sInt ++){
            dVal = M_PI / 3;
            fY = sin(dVal);
            dCos = cos(dVal);
            dVal = (double)sInt - 9;
            dVal *= M_PI / 8;
            fZ = cos(dVal) * dCos;
            fX = sin(dVal) * dCos;
            vecDir[sInt] = CC3VectorMake(-fX, fY, fZ);
        }
        for(sInt = 25;sInt < 49;sInt ++){
            dVal = M_PI / 4;
            fY = sin(dVal);
            dCos = cos(dVal);
            dVal = (double)sInt - 25;
            dVal *= M_PI / 12;
            fZ = cos(dVal) * dCos;
            fX = sin(dVal) * dCos;
            vecDir[sInt] = CC3VectorMake(-fX, fY, fZ);
        }
        for(sInt = 49;sInt < 79;sInt ++){
            dVal = M_PI / 6;
            fY = sin(dVal);
            dCos = cos(dVal);
            dVal = (double)sInt - 49;
            dVal *= M_PI / 15;
            fZ = cos(dVal) * dCos;
            fX = sin(dVal) * dCos;
            vecDir[sInt] = CC3VectorMake(-fX, fY, fZ);
        }
        for(sInt = 79;sInt < 111;sInt ++){
            dVal = M_PI / 12;
            fY = sin(dVal);
            dCos = cos(dVal);
            dVal = (double)sInt - 79;
            dVal *= M_PI / 16;
            fZ = cos(dVal) * dCos;
            fX = sin(dVal) * dCos;
            vecDir[sInt] = CC3VectorMake(-fX, fY, fZ);
        }
        for(sInt = 111;sInt < 127;sInt ++){
            fY = 0;
            dVal = (double)sInt - 111;
            dVal *= M_PI / 16;
            fZ = cos(dVal);
            fX = sin(dVal);
            vecDir[sInt] = CC3VectorMake(-fX, fY, fZ);
        }
    }
    else{
        fY = 0;
        for(sInt = 1;sInt <= 72;sInt ++){
            dVal = (double)sInt * M_PI / 36;
            dVal -= M_PI;
            fZ = cos(dVal);
            fX = sin(dVal);
            vecDir[sInt] = CC3VectorMake(-fX,fY,fZ);
        }
    }
}

-(void)tiltOnOff:(UIButton*)btn{
    if(uPitchRoll == 2){
        uPitchRoll = 0;
        [tiltBtn setAlpha:0.25f];
        tiltLabel.text = offText;
    }
    else if(uPitchRoll == 0){
        uPitchRoll = 1;
        [tiltBtn setAlpha:0.5f];
        tiltLabel.text = @"Pitch is on";
    }
    else{
        if(isBtnOn){
            uPitchRoll = 2;
            [tiltBtn setAlpha:0.75f];
            tiltLabel.text = onText;
        }
        else{
            uPitchRoll = 0;
            [tiltBtn setAlpha:0.25f];
            tiltLabel.text = offText;
        }
    }
}

-(void)btnOnOff:(UIButton*)btn{
    if(isBtnOn){
        isBtnOn = NO;
        [mtnBtn setAlpha:0.25f];
        mtnLabel.text = @"Self motion";
        if(uPitchRoll > 0){
            tiltLabel.text = @"Pitch is on";
            if(uPitchRoll == 2){
                uPitchRoll = 1;
            }
            [tiltBtn setAlpha:0.5f];
        }
    }
    else{
        isBtnOn = YES;
        [mtnBtn setAlpha:0.75f];
        mtnLabel.text = @"Gyro is on";
        if(uPitchRoll == 2)
            tiltLabel.text = onText;
        else if(uPitchRoll == 1)
            tiltLabel.text = @"Pitch is on";
    }
    [self gyroOnOff];
}

- (void)gyroOnOff
{
    if(isBtnOn) {
        [self activateManager];
        self.isManagerOn = YES;
    }
    else{
        if(_manager.gyroActive)
            [_manager stopGyroUpdates];
        self.isManagerOn = NO;
    }
}

-(void)activateManager{
    double dMin;
    
    dMin = M_PI / 32;
    
    if(_manager.gyroAvailable){
        _manager.gyroUpdateInterval = 0.1;
        CMGyroHandler deviceMotionHandler;
        fStamp = 0;
        deviceMotionHandler = ^(CMGyroData *data, NSError *error){
            if(fStamp == 0){
                fStamp = data.timestamp;
            }
            double dElapsed = data.timestamp - fStamp;
            fStamp = data.timestamp;
            if(uPitchRoll == 2){
                if(fabs(data.rotationRate.x) > fabs(data.rotationRate.y)){
                    if(fabs(data.rotationRate.x) > fabs(data.rotationRate.z)){
                        if(fabs(data.rotationRate.x) > dMin){
                            if(myOrientation == UIInterfaceOrientationPortrait){
                                sMotion = 1;
                                dPitch -= dElapsed * data.rotationRate.x;
                            }
                            else if(myOrientation == UIInterfaceOrientationLandscapeRight){
                                sMotion = 2;
                                dYaw -= dElapsed * data.rotationRate.x;
                            }
                            else{
                                sMotion = 2;
                                dYaw += dElapsed * data.rotationRate.x;
                            }
                        }
                    }
                    else{
                        if(fabs(data.rotationRate.z) > dThrsld){
                            sMotion = 3;
                            dRoll += dElapsed * data.rotationRate.z;
                        }
                    }
                }
                else{
                    if(fabs(data.rotationRate.y) > fabs(data.rotationRate.z)){
                        if(fabs(data.rotationRate.y) > dMin){
                            if(myOrientation == UIInterfaceOrientationPortrait){
                                sMotion = 2;
                                dYaw -= dElapsed * data.rotationRate.y;
                            }
                            else if(myOrientation == UIInterfaceOrientationLandscapeRight){
                                sMotion = 1;
                                dPitch += dElapsed * data.rotationRate.y;
                            }
                            else{
                                sMotion = 1;
                                dPitch -= dElapsed * data.rotationRate.y;
                            }
                        }
                    }
                    else{
                        if(fabs(data.rotationRate.z) > dThrsld){
                            sMotion = 3;
                            dRoll += dElapsed * data.rotationRate.z;
                        }
                    }
                }
            }
            else if(uPitchRoll == 1){
                if(fabs(data.rotationRate.x) < fabs(data.rotationRate.y)){
                    if(fabs(data.rotationRate.y) > dMin){
                        if(myOrientation == UIInterfaceOrientationPortrait){
                            sMotion = 2;
                            dYaw -= dElapsed * data.rotationRate.y;
                        }
                        else if(myOrientation == UIInterfaceOrientationLandscapeRight){
                            sMotion = 1;
                            dPitch += dElapsed * data.rotationRate.y;
                        }
                        else{
                            sMotion = 1;
                            dPitch -= dElapsed * data.rotationRate.y;
                        }
                    }
                }
                else{
                    if(fabs(data.rotationRate.x) > dMin){
                        if(myOrientation == UIInterfaceOrientationPortrait){
                            sMotion = 1;
                            dPitch -= dElapsed * data.rotationRate.x;
                        }
                        else if(myOrientation == UIInterfaceOrientationLandscapeRight){
                            sMotion = 2;
                            dYaw -= dElapsed * data.rotationRate.x;
                        }
                        else{
                            sMotion = 2;
                            dYaw += dElapsed * data.rotationRate.x;
                        }
                    }
                }
            }
            
            else if(myOrientation == UIDeviceOrientationPortrait && fabs(data.rotationRate.y) > dMin){
                sMotion = 2;
                dYaw -= dElapsed * data.rotationRate.y;
            }
            else if(myOrientation == UIDeviceOrientationLandscapeRight && fabs(data.rotationRate.x) > dMin){
                sMotion = 2;
                dYaw += dElapsed * data.rotationRate.x;
            }
            else if(fabs(data.rotationRate.x) > dMin){
                sMotion = 2;
                dYaw -= dElapsed * data.rotationRate.x;
            }
            
        };
        [_manager startGyroUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:deviceMotionHandler];
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    if(isPrepared){
        if([player isPlaying] == NO){
            if(isSS && !isSearchJpg){
                isSearchJpg = YES;
                [self loadImage:jpgURL];
            }
            NSString *tmpStr = [self.urlStr lastPathComponent];
            NSString *labelStr = [[NSString alloc]initWithFormat:@"Playing %@\nTo stop reproduction, tap on screen",tmpStr];
            labelText = labelStr;
            
            uJpgNum = iFirstJpg;
            myLabel.text = labelText;
            nBytesWritten = 0;
            player.urlStr = self.urlStr;
            player.iSize = 0;
            isTerminatedByUser = NO;
            [player setIsPlaying:YES];                      // Start reproduction
            [player start];
        }
        else{
            isTerminatedByUser = YES;
            [player setIsPlaying:NO];
            [player stop:NO];                  // Stop reproduction
        }
    }
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)setupLayer {
    _eaglLayer = (CAEAGLLayer*) self.layer;
    _eaglLayer.opaque = YES;
}

- (void)setupContext {
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if (!_context) {
        [self prepareToExit];
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        [self prepareToExit];
    }
}

- (void)setupRenderBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

- (void)setupDepthBuffer {
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);
    //    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.height, self.frame.size.width);
}

- (void)setupFrameBuffer {
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
}

-(void)render:(CADisplayLink*)displayLink{
    float h;
    double dNumero;
    double dPt = dPitch;
    double dYw = dYaw;
    double dRl = dRoll;
    SInt16 sInt,sVal;
    SInt16 Numero[2];
    CC3Vector vecSoundHor,vecSoundDepth,vecSoundUp;
    
    dRoll = dPitch = dYaw = 0;
    
    vecSoundHor = CC3VectorMake(1,0,0);
    vecSoundDepth = CC3VectorMake(0,0,1);
    vecSoundUp = CC3VectorMake(0,1,0);
    
//    if(!CC3VectorsAreEqual(vecAt,vecTop))
//        vecHor = CC3VectorCross(vecTop,vecAt);
    
    if(sMotion == 1){                       // Pitch changed
        vecAt = [self vecRotate:vecAt aroundVec:vecHor byRad:-dPt];
        vecUp = [self vecRotate:vecUp aroundVec:vecHor byRad:-dPt];
    }
    else if(sMotion == 2){                  // Yaw changed
        vecAt = [self vecRotate:vecAt aroundVec:vecUp byRad:dYw];
        vecHor = [self vecRotate:vecHor aroundVec:vecUp byRad:dYw];
    }
    else if(sMotion == 3){                  // Roll changed
        vecHor = [self vecRotate:vecHor aroundVec:vecAt byRad:dRl];
        vecUp = [self vecRotate:vecUp aroundVec:vecAt byRad:dRl];
    }
    
    for(sInt = 0;sInt < 127;sInt ++){
        
        if(sMotion == 1)                    // Pitch changed
            vecDir[sInt] = [self vecRotate:vecDir[sInt] aroundVec:vecSoundHor byRad:dPt];
        else if(sMotion == 2)               // Yaw changed
            vecDir[sInt] = [self vecRotate:vecDir[sInt] aroundVec:vecSoundUp byRad:-dYw];
        else if(sMotion == 3)              // Roll changed
            vecDir[sInt] = [self vecRotate:vecDir[sInt] aroundVec:vecSoundDepth byRad:-dRl];
        
        if(vecDir[sInt].y > sin(11 * M_PI / 24)){
            Numero[0] = Numero[1] = 0;
        }
        else if(vecDir[sInt].y < sin(-11 * M_PI /24)){
            Numero[0] = Numero[1] = 253;
        }
        else if(vecDir[sInt].y > sin(3 * M_PI / 8)){
            h = atan2(-vecDir[sInt].x,vecDir[sInt].z);
            h += M_PI / 8;
            if(h < 0)
                h += 2 * M_PI;
            dNumero = h * 4 / M_PI;
            Numero[1] = 1 + (SInt16)dNumero;
        }
        else if(vecDir[sInt].y < sin(-3 * M_PI / 8)){
            h = atan2(-vecDir[sInt].x,vecDir[sInt].z);
            h += M_PI / 8;
            dNumero = h * 4 / M_PI;
            Numero[1] = 248 - (SInt16)dNumero;
        }
        else if(vecDir[sInt].y > sin(7 * M_PI / 24)){
            h = atan2(-vecDir[sInt].x,vecDir[sInt].z);
            h += M_PI / 16;
            if(h < 0)
                h += 2 * M_PI;
            dNumero = h * 8 / M_PI;
            Numero[1] = 9 + (SInt16)dNumero;
        }
        else if(vecDir[sInt].y < sin(-7 * M_PI / 24)){
            h = atan2(-vecDir[sInt].x,vecDir[sInt].z);
            h += M_PI / 16;
            dNumero = h * 8 / M_PI;
            Numero[1] = 236 - (SInt16)dNumero;
        }
        else if(vecDir[sInt].y > sin(5 * M_PI / 24)){
            h = atan2(-vecDir[sInt].x,vecDir[sInt].z);
            h += M_PI / 24;
            if(h < 0)
                h += 2 * M_PI;
            dNumero = h * 12 / M_PI;
            Numero[1] = 25 + (SInt16)dNumero;
        }
        else if(vecDir[sInt].y < sin(-5 * M_PI / 24)){
            h = atan2(-vecDir[sInt].x,vecDir[sInt].z);
            h += M_PI / 24;
            dNumero = h * 12 / M_PI;
            Numero[1] = 216 - (SInt16)dNumero;
        }
        else if(vecDir[sInt].y > sin(M_PI / 8)){
            h = atan2(-vecDir[sInt].x,vecDir[sInt].z);
            h += M_PI / 30;
            if(h < 0)
                h += 2 * M_PI;
            dNumero = h * 15 / M_PI;
            Numero[1] = 49 + (SInt16)dNumero;
        }
        else if(vecDir[sInt].y < sin(-M_PI / 8)){
            h = atan2(-vecDir[sInt].x,vecDir[sInt].z);
            h += M_PI / 30;
            dNumero = h * 15 / M_PI;
            Numero[1] = 189 - (SInt16)dNumero;
        }
        else if(vecDir[sInt].y > sin(M_PI / 24)){
            h = atan2(-vecDir[sInt].x,vecDir[sInt].z);
            h += M_PI / 32;
            if(h < 0)
                h += 2 * M_PI;
            dNumero = h * 16 / M_PI;
            Numero[1] = 79 + (SInt16)dNumero;
        }
        else if(vecDir[sInt].y < sin(-M_PI / 24)){
            h = atan2(-vecDir[sInt].x,vecDir[sInt].z);
            h += M_PI / 32;
            dNumero = h * 16 / M_PI;
            Numero[1] = 158 - (SInt16)dNumero;
        }
        else{
            h = atan2(-vecDir[sInt].x,vecDir[sInt].z);
            h += M_PI / 32;
            if(h < 0)
                h += 2 * M_PI;
            dNumero = h * 16 / M_PI;
            if(dNumero < 16){
                Numero[1] = 111 + (SInt16)dNumero;
            }
            else{
                Numero[1] = 158 - (SInt16)dNumero;
            }
        }
        if(Numero[1] == 0 || Numero[1] == 1 || Numero[1] == 9 || Numero[1] == 25 || Numero[1] == 49 || Numero[1] == 79 || Numero[1] == 111 || Numero[1] == 142 || Numero[1] == 174 || Numero[1] == 204 || Numero[1] == 228 || Numero[1] == 244 || Numero[1] == 252)
            Numero[0] = Numero[1];
        else if(Numero[1] < 9)
            Numero[0] = 10 - Numero[1];
        else if(Numero[1] < 25)
            Numero[0] = 34 - Numero[1];
        else if(Numero[1] < 49)
            Numero[0] = 74 - Numero[1];
        else if(Numero[1] < 79)
            Numero[0] = 128 - Numero[1];
        else if(Numero[1] < 111)
            Numero[0] = 190 - Numero[1];
        else if(Numero[1] < 127)
            Numero[0] = 15 + Numero[1];
        else if(Numero[1] < 142)
            Numero[0] = Numero[1] - 15;
        else if(Numero[1] < 174)
            Numero[0] = 174 - Numero[1] + 142;
        else if(Numero[1] < 204)
            Numero[0] = 204 - Numero[1] + 174;
        else if(Numero[1] < 228)
            Numero[0] = 228 - Numero[1] + 204;
        else if(Numero[1] < 244)
            Numero[0] = 244 - Numero[1] + 228;
        else
            Numero[0] = 252 - Numero[1] + 244;
        
        Byte cByte;
        cByte = Numero[0] & 0xff;
        [[player dilID]replaceBytesInRange:NSMakeRange(sInt,sizeof(Byte)) withBytes:&cByte];
        SInt16 iByte = 253 - sInt;
        sVal = 253 - Numero[0];
        cByte = sVal & 0xff;
        [[player dilID]replaceBytesInRange:NSMakeRange(iByte,sizeof(Byte)) withBytes:&cByte];
        cByte = Numero[1] & 0xff;
        [[player dirID]replaceBytesInRange:NSMakeRange(sInt,sizeof(Byte)) withBytes:&cByte];
        sVal = 253 - Numero[1];
        cByte = sVal & 0xff;
        [[player dirID]replaceBytesInRange:NSMakeRange(iByte,sizeof(Byte)) withBytes:&cByte];
        
    }
    sMotion = 0;
    
    glClearColor(0, 104.0 / 255.0, 55.0 / 255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    CC3GLMatrix *projection = [CC3GLMatrix matrix];
    
    h = 4.0f * self.frame.size.height / self.frame.size.width;
    [projection populateFromFrustumLeft:-2 andRight:2 andBottom:-h / 2 andTop:h / 2 andNear:2 andFar:14];
    glUniformMatrix4fv(_projectionUniform, 1, 0, projection.glMatrix);
    
    CC3GLMatrix *modelView = [CC3GLMatrix matrix];
    [modelView populateToLookAt:vecAt withEyeAt:CC3VectorMake(0, 0, 0) withUp:vecUp];
    
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelView.glMatrix);
    
    glViewport(0,0,sWidth,sHeight);
    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
    
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE,
                          sizeof(Vertex), (GLvoid*) (sizeof(float) * 7));
    
    glActiveTexture(GL_TEXTURE0);
    
    if(player.isImageUpdate){
        glActiveTexture(GL_TEXTURE0);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, imageWidth, imageHeight, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
        free(spriteData);
        player.isImageUpdate = NO;
        myLabel.text = labelText;
    }
    
    glUniform1i(_textureUniform, 0);
    
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

-(GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType{
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        [self prepareToExit];
    }
    
    // 2
    GLuint shaderHandle = glCreateShader(shaderType);
    
    // 3
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    // 4
    glCompileShader(shaderHandle);
    
    // 5
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        //        NSString *messageString = [NSString stringWithUTF8String:messages];
        //        NSLog(@"%@", messageString);
        [self prepareToExit];
    }
    
    return shaderHandle;
}

- (void)compileShaders {
    
    // 1
    GLuint vertexShader = [self compileShader:@"SimpleVertex" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"SimpleFragment" withType:GL_FRAGMENT_SHADER];
    
    // 2
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    // 3
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        //        NSString *messageString = [NSString stringWithUTF8String:messages];
        //        NSLog(@"%@", messageString);
        [self prepareToExit];
    }
    
    // 4
    glUseProgram(programHandle);
    
    // 5
    _positionSlot = glGetAttribLocation(programHandle, "Position");
    _colorSlot = glGetAttribLocation(programHandle, "SourceColor");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
    
    _projectionUniform = glGetUniformLocation(programHandle, "Projection");
    _modelViewUniform = glGetUniformLocation(programHandle, "Modelview");
    
    _texCoordSlot = glGetAttribLocation(programHandle, "TexCoordIn");
    glEnableVertexAttribArray(_texCoordSlot);
    _textureUniform = glGetUniformLocation(programHandle, "Texture");
}

-(quaternion)qMult:(quaternion)left withQuatarnion:(quaternion)right{
    quaternion   qRet;
    double   d1, d2, d3, d4;
    
    d1   =  left.fReal * right.fReal;
    d2   = -left.fX * right.fX;
    d3   = -left.fY * right.fY;
    d4   = -left.fZ * right.fZ;
    qRet.fReal = d1+ d2+ d3+ d4;
    
    d1   =  left.fReal * right.fX;
    d2   =  right.fReal * left.fX;
    d3   =  left.fY * right.fZ;
    d4   = -left.fZ * right.fY;
    qRet.fX =  d1+ d2+ d3+ d4;
    
    d1   =  left.fReal * right.fY;
    d2   =  right.fReal * left.fY;
    d3   =  left.fZ * right.fX;
    d4   = -left.fX * right.fZ;
    qRet.fY =  d1+ d2+ d3+ d4;
    
    d1   =  left.fReal * right.fZ;
    d2   =  right.fReal * left.fZ;
    d3   =  left.fX * right.fY;
    d4   = -left.fY * right.fX;
    qRet.fZ =  d1+ d2+ d3+ d4;
    
    return   qRet;
}

-(CC3Vector)vecRotate:(CC3Vector)vecOrig aroundVec:(CC3Vector)vecAxis byRad:(float)fRad{
    
    quaternion qQ,qR,qRet;
    quaternion qOrig;
    
    qOrig.fReal = 0;
    qOrig.fX = vecOrig.x;
    qOrig.fY = vecOrig.y;
    qOrig.fZ = vecOrig.z;
    
    float fCos = cos(fRad / 2);
    float fSin = sin(fRad / 2);
    
    qQ.fReal = fCos;
    qQ.fX = vecAxis.x * fSin;
    qQ.fY = vecAxis.y * fSin;
    qQ.fZ = vecAxis.z * fSin;
    
    qR.fReal = fCos;
    qR.fX = -vecAxis.x * fSin;
    qR.fY = -vecAxis.y * fSin;
    qR.fZ = -vecAxis.z * fSin;
    
    qRet = [self qMult:qR withQuatarnion:qOrig];
    qOrig = [self qMult:qRet withQuatarnion:qQ];
    
    vecOrig.x = qOrig.fX;
    vecOrig.y = qOrig.fY;
    vecOrig.z = qOrig.fZ;
    
    return vecOrig;
}

-(void)errorDetection{
    myLabel.text = @"mySopa failed to load data";
    
    if(player.isPlaying){
        [player setIsPlaying:NO];
        [player stop:NO];                  // Stop reproduction
    }
}

-(void)connectionFailed{
    if(player.isPlaying)
        [player setIsPlaying:NO];
    
    myLabel.text = @"mySopa failed to load data";
    
    NSNotification* notification;
    notification = [NSNotification notificationWithName:@"URLError" object:self];
    NSNotificationCenter* center;
    center = [NSNotificationCenter defaultCenter];
    
    // Post notification
    [center postNotification:notification];
}

-(void)fileError{
    myLabel.text = @"mySopa failed to load data";
    
    NSNotification* notification;
    notification = [NSNotification notificationWithName:@"URLError" object:self];
    NSNotificationCenter* center;
    center = [NSNotificationCenter defaultCenter];
    
    // Post notification
    [center postNotification:notification];
}

-(void)setupDatabase{
    NSURL *tmUrl = [[NSURL alloc]initWithString:self.urlStr];
    NSURL *tmpUrl = tmUrl.URLByDeletingPathExtension;
    NSURL *newUrl = [tmpUrl URLByAppendingPathExtension:@"jpg"];
    NSString *newStr = [[NSString alloc]initWithString:newUrl.absoluteString];
    [player setIStage:0];
    
    mtnLabel.font = [UIFont systemFontOfSize:sFontSize];
    tiltLabel.font = [UIFont systemFontOfSize:sFontSize];
    if(is3d){
        [tiltBtn setAlpha:0.5f];
        tiltLabel.text = @"Pitch is on";
        uPitchRoll = 1;
    }
    else{
        [tiltBtn setAlpha:0.25f];
        tiltLabel.text = offText;
        uPitchRoll = 0;
    }
    if(isAsset){
        player.isAsset = YES;
        player.isFromDir = YES;
        _floorTexture = [self setupTexture:newStr];
        if(_floorTexture == 0){
            newStr = [newUrl lastPathComponent];
            _floorTexture = [self setupTexture:newStr];
            if(_floorTexture == 0)
                _floorTexture = [self setupTexture:@"default_cube.png"];
        }
        [player performSelector:@selector(loadDatabaseFromDir) withObject:nil afterDelay:0.1];
    }
    else{
        player.isAsset = NO;
        player.isFromDir = NO;
        [player performSelector:@selector(loadDatabase) withObject:nil afterDelay:0.1];
    }
}

-(void)databaseReady{
    
    labelText = [[NSString alloc]initWithFormat:@"%@\nTap on screen to start reproduction",self.urlStr];
    
    myLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,0,sWidth,sHeight / 4)];
    myLabel.textAlignment = NSTextAlignmentCenter;
    myLabel.backgroundColor = [UIColor clearColor];
    myLabel.textColor = [UIColor lightTextColor];
    myLabel.numberOfLines = 4;
    myLabel.font = [UIFont systemFontOfSize:sFontSize];
    myLabel.text = labelText;
    myLabel.shadowOffset = CGSizeMake(1,1);
    myLabel.shadowColor = [UIColor darkTextColor];
    
    if(!player.isFromDir){
        isSearchJpg = YES;
        [self loadImage:jpgURL];
    }
    else{
        myLabel.shadowOffset = CGSizeMake(1,1);
        myLabel.shadowColor = [UIColor darkTextColor];
        if(_manager.gyroAvailable){
            mtnLabel.text = @"Self motion";
            [self addSubview:mtnBtn];
            [self addSubview:mtnLabel];
        }
        [self addSubview:tiltLabel];
        [self addSubview:tiltBtn];
        
        [self addSubview:myLabel];
        NSNotification* notification;
        notification = [NSNotification notificationWithName:@"readyToGo" object:self];
        NSNotificationCenter* center;
        center = [NSNotificationCenter defaultCenter];
        
        // Post notification
        [center postNotification:notification];
        
        [self setupDisplayLink];
        [player play];
        isPrepared = YES;
    }
}

-(void)loadImage:(NSURL *)url {
    
    isImageLoading = YES;
//    NSURLRequest *req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0f];
    NSURLRequest *req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:3.0f];
    _imageConn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    int statusCode = (int)[((NSHTTPURLResponse *)response) statusCode];
    NSURL *tmpUrl;
    NSURL *newUrl;
    
    if (statusCode == 404){
        isImageLoading = NO;
        [connection cancel];

        if(isSearchJpg && !player.isSequel){
            isSearchJpg = NO;
            if(isSS && player.isPlaying){
                uJpgNum = 0;
            }
            else{
                NSURL *url = [[NSURL alloc]initWithString:self.urlStr];
                tmpUrl = url.URLByDeletingPathExtension;
                newUrl = [tmpUrl URLByAppendingPathExtension:@"png"];
                NSURLRequest *req = [NSURLRequest requestWithURL:newUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
                _imageConn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
                if(_imageConn == nil){
                    myLabel.text = @"mySopa failed to load data";
                    
                    NSNotification* notification;
                    notification = [NSNotification notificationWithName:@"imageError" object:self];
                    NSNotificationCenter* center;
                    center = [NSNotificationCenter defaultCenter];
                    
                    // Post notification
                    [center postNotification:notification];
                }
            }
        }
        else{
            if(isSS)
                myLabel.text = @"Image not found";
            else if(!player.isSequel || uJpgNum == 0){
                myLabel.text = @"Image file not found";
                NSNotification* notification;
                notification = [NSNotification notificationWithName:@"imageError" object:self];
                NSNotificationCenter* center;
                center = [NSNotificationCenter defaultCenter];
                
                // Post notification
                [center postNotification:notification];
            }
            else if(isSequel){
                uJpgNum = 0;
                NSString *newStr = jpgURL.absoluteString;
                NSString *tmpStr = [newStr substringToIndex:self.urlStr.length - 7];
                NSString *jpgStr = [tmpStr stringByAppendingFormat:@"%04u",uJpgNum];
                tmpUrl = [NSURL URLWithString:jpgStr];
                jpgURL = [tmpUrl URLByAppendingPathExtension:@"jpg"];
                [self loadImage:jpgURL];
            }
        }
    }
    else
        async_data = [[NSMutableData alloc] initWithLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [async_data appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    myLabel.text = @"mySopa failed to load data";
    isImageLoading = NO;    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    
    isImageLoading = NO;
    if([self dataIsValidJPEG:async_data] || !isSearchJpg){
        isImageReady = YES;
        _myImage = [[UIImage alloc]initWithData:async_data];
        _floorTexture = [self setupTexture:@"default_cube.png"];
        
        if(player.numBytesWritten > 0)
            player.isImageUpdate = YES;
        
        if(player.numBytesWritten > 0){
            return;
        }
        if(_manager.gyroAvailable){
            mtnLabel.text = @"Self motion";
            [self addSubview:mtnBtn];
            [self addSubview:mtnLabel];
        }
        [self addSubview:tiltLabel];
        [self addSubview:tiltBtn];
        
        NSNotification* notification;
        notification = [NSNotification notificationWithName:@"readyToGo" object:self];
        NSNotificationCenter* center;
        center = [NSNotificationCenter defaultCenter];
        
        // Post notification
        [center postNotification:notification];
        
        myLabel.shadowOffset = CGSizeMake(1,1);
        myLabel.shadowColor = [UIColor darkTextColor];
        
        [self addSubview:myLabel];
        [self setupDisplayLink];
        if(!player.isPlaying){
            [player play];
            isPrepared = YES;
        }
    }
    
}

-(BOOL)dataIsValidJPEG:(NSData *)data
{
    if (!data || data.length < 2) return NO;
    
    NSInteger totalBytes = data.length;
    const char *bytes = (const char*)[data bytes];
    
    return (bytes[0] == (char)0xff &&
            bytes[1] == (char)0xd8 &&
            bytes[totalBytes-2] == (char)0xff &&
            bytes[totalBytes-1] == (char)0xd9);
}

-(void)sopaInfo{
}

-(void)sopaReproductionFinished{
    NSString *labelStr;
    UInt32 uVal = player.numBytesWritten;
    
    nBytesWritten = nBytesRead = 0;
    if(isTerminatedByUser){
        NSNotification* notification;
        notification = [NSNotification notificationWithName:@"reproductionProgress" object:self];
        NSNotificationCenter* center;
        center = [NSNotificationCenter defaultCenter];
        
        // Post notification
        [center postNotification:notification];
        
        labelStr = [[NSString alloc]initWithFormat:@"%u bytes reproduced\nReproduction terminated",(unsigned int)uVal];
    }
    else{
        labelStr = [[NSString alloc]initWithFormat:@"%u bytes reproduced\nReproduction completed",(unsigned int)uVal];
    }
    if(isSearchJpg)
        isSearchJpg = NO;
    labelText = labelStr;
    myLabel.text = labelText;
    player.isPlaying = NO;
    [_imageConn cancel];
    if(isSS){
        player.iFileNum = iFirstSopa;
//        uJpgNum = iFirstJpg;
    }
}

-(void)openScroller{
    scrollView = [[scroller alloc]initWithFrame:CGRectMake(0.0,0.0,sWidth,sHeight)];
    
    scrollView.pagingEnabled = NO;
    scrollView.contentSize = CGSizeMake(imageWidth * 3,imageWidth * 3);
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.bounces = NO;
    scrollView.contentOffset = CGPointMake(imageWidth,imageWidth);
    [scrollView setDelegate:(id)self];
    
    [self addSubview:scrollView];
}

#pragma mark - scrollView Delegate

-(void)scrollViewDidScroll:(UIScrollView *)sender{
    CGPoint p = [sender contentOffset];
    CGPoint point;
    double dDifX = 0;
    double dDifY = 0;
    
    if(myOrientation == UIDeviceOrientationPortrait){
        dDifX = p.x - dCurrentX;
        dDifY = p.y - dCurrentY;
        if(fabs(dDifX) > fabs(dDifY)){
            sMotion = 2;
            if(p.x < imageWidth / 2){
                sender.contentOffset = CGPointMake(imageWidth + (SInt16)p.x,(SInt16)p.y);
            }
            else if(p.x >= (double)imageWidth * 3 / 2){
                sender.contentOffset = CGPointMake((SInt16)p.x - imageWidth,(SInt16)p.y);
            }
            point = sender.contentOffset;
            dCurrentX = point.x;
            dPan += dDifX * M_PI * 2 / (double)imageWidth;
            dYaw += dPan;
            dPan = 0;
        }
        else{
            if(p.y < imageWidth / 2){
                sender.contentOffset = CGPointMake((SInt16)p.x,imageWidth + (SInt16)p.y);
            }
            else if(p.y >= (double)imageWidth * 3 / 2){
                sender.contentOffset = CGPointMake((SInt16)p.x,(SInt16)p.y - imageWidth);
            }
            point = [sender contentOffset];
            dCurrentY = point.y;
            if(uPitchRoll > 0){
                sMotion = 1;
                dTilt += dDifY * M_PI * 2 / (double)imageWidth;
                dPitch += dTilt;
                dTilt = 0;
            }
        }
    }
    else{
        dDifX = p.x - dCurrentX;
        dDifY = p.y - dCurrentY;
        if(fabs(dDifX) > fabs(dDifY)){
            sMotion = 2;
            if(p.x < imageWidth / 2){
                sender.contentOffset = CGPointMake(imageWidth + (SInt16)p.x,(SInt16)p.y);
            }
            else if(p.x >= (double)imageWidth * 3 / 2){
                sender.contentOffset = CGPointMake((SInt16)p.x - imageWidth,(SInt16)p.y);
            }
            point = sender.contentOffset;
            dCurrentX = point.x;
            dPan += dDifX * M_PI * 2 / (double)imageWidth;
            dYaw += dPan;
            dPan = 0;
        }
        else{
            if(p.y < imageWidth / 2){
                sender.contentOffset = CGPointMake((SInt16)p.x,imageWidth + (SInt16)p.y);
            }
            else if(p.y >= (double)imageWidth * 3 / 2){
                sender.contentOffset = CGPointMake((SInt16)p.x,(SInt16)p.y - imageWidth);
            }
            point = [sender contentOffset];
            dCurrentY = point.y;
            if(uPitchRoll > 0){
                sMotion = 1;
                dTilt += dDifY * M_PI * 2 / (double)imageWidth;
                dPitch += dTilt;
                dTilt = 0;
            }
        }
    }
}

-(void)notifyNewImage{
    NSURL *url = [[NSURL alloc]initWithString:[player urlStr]];
    NSURL *tmpUrl = url.URLByDeletingPathExtension;
    NSURL *newUrl;
    if(!player.isSequel){
        if(!isSS)
            return;
        uJpgNum ++;
        NSString *newStr = [tmpUrl absoluteString];
        NSString *formattedStr = [NSString stringWithFormat:@"%04u",(unsigned int)uJpgNum];
        tmpUrl = [NSURL URLWithString:[newStr stringByAppendingString:formattedStr]];
        newUrl = [tmpUrl URLByAppendingPathExtension:@"jpg"];
    }
    else{
        if(player.isNewLoop){
            uJpgNum = 0;
            player.isNewLoop = NO;
        }
        else
            uJpgNum ++;
        NSString *newStr = jpgURL.absoluteString;
        NSString *tmpStr = [newStr substringToIndex:self.urlStr.length - 7];
        NSString *jpgStr = [tmpStr stringByAppendingFormat:@"%04u",uJpgNum];
        tmpUrl = [NSURL URLWithString:jpgStr];
        jpgURL = [tmpUrl URLByAppendingPathExtension:@"jpg"];
        newUrl = jpgURL;
    }
//    NSLog(@"%@",newUrl.absoluteString);
    
    if(isAsset){
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:[newUrl absoluteString] ofType:@"jpg"];
        _myImage = [UIImage imageWithData:[NSData dataWithContentsOfFile:imagePath]];
        if(_myImage == nil)
            isImageLoading = NO;
        else
            _floorTexture = [self setupTexture:[newUrl absoluteString]];
    }
    else if(isSearchJpg && !isImageLoading)
        [self loadImage:newUrl];
}

-(void)notifyProgress{
    if(expectedLength <= 0)
        expectedLength = (long)player.expectedLength;
    nBytesRead = player.nBytesRead;
    
    NSNotification* notification;
    notification = [NSNotification notificationWithName:@"connectionProgress" object:self];
    NSNotificationCenter* center;
    center = [NSNotificationCenter defaultCenter];
    
    // Post notification
    [center postNotification:notification];
    
}

-(void)notifyReproduction{
    nBytesWritten = (UInt32)player.lBytesDone;

    if(!player.isProceed){
        NSString *tmpStr = [player.urlStr lastPathComponent];
        NSString *labelStr = [[NSString alloc]initWithFormat:@"Playing %@\nTo stop reproduction, tap on screen",tmpStr];
        labelText = labelStr;
        
    }
}

-(void)prepareToExit{
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle : @"Exit mySopa"
                              message:@"Failed to setup mySopa!"
                              delegate : nil cancelButtonTitle : @"OK"
                              otherButtonTitles : nil];
    [alertView show];
    myLabel.text = @"Operation was terminated by an error";
    //    exit(1);
}

/*
 - (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
 {
 [self startDisplayLinkIfNeeded];
 }
 
 - (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
 {
 if (!decelerate) {
 [self stopDisplayLink];
 }
 }
 
 - (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
 {
 [self stopDisplayLink];
 }
 
 #pragma mark Display Link
 
 - (void)startDisplayLinkIfNeeded
 {
 if (!displayLink) {
 // do not change the method it calls as its part of the GLKView
 displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(display)];
 [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:UITrackingRunLoopMode];
 }
 }
 
 - (void)stopDisplayLink
 {
 [displayLink invalidate];
 displayLink = nil;
 }   */

-(BOOL)finalizeView{
    [player stop:YES];
    [player cancelLoading];
    [player setIsCanceled:YES];
    [player finalize];
    
    if(_imageConn != nil)
        [_imageConn cancel];
    [displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [displayLink invalidate];
    
    return TRUE;
}

-(void)dealloc{
    if(_manager.gyroActive) {
        [_manager stopGyroUpdates];
    }
    _manager = nil;
}

@end