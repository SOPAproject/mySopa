//
//  sopaObject.m
//  mySopa
//
//  Created by Kaoru Ashihara on 13/10/03.
//  Copyright (c) 2013, AIST. All rights reserved.
//

#import "sopaObject.h"

static void outputCallback(void *inUserData,AudioQueueRef inAQ,AudioQueueBufferRef inBuffer){
    if(!inUserData){
        return;
    }
    sopaObject *player = (__bridge sopaObject*)inUserData;
    [player _processor:inAQ queueBuffer:inBuffer];
}

@implementation sopaObject{
    SInt32 iOff;
    SInt32 iDBSize;
    SInt16 iRatio;
    SInt16 *ResultLeft;
    SInt16 *ResultRight;
    SInt16 *sHrtf;
    SInt16 *sPhase;
    SInt16 iProc;
    SInt16 iProcBytes;
    SInt16 iFrames;
    SInt16 iRem;
    SInt16 iHlf;
    SInt16 sCurrentData;
    SInt32 sCurrentDataOffset;
    SInt16 *sAngl;
    SInt16 *sAngr;
    SInt16 *sStream;
    SInt16 connStatusCode;
    double *dHan;
    double dAtt;
    BOOL isVersion1;
    NSMutableData *mData0,*mData1,*mHrtf,*mPhase;
    
    SInt16 sPrev;
}

@synthesize ExtBufSize;
@synthesize myConn;
@synthesize databaseConn;
@synthesize urlStr;
@synthesize numBytesWritten;
@synthesize numOffset;
@synthesize nBytesRead;
@synthesize nBytesReady;
@synthesize nTrial;
@synthesize isLoaded;
@synthesize isPrepared;
@synthesize isPlaying;
@synthesize isCanceled;
@synthesize isFromDir;
@synthesize iSize;
@synthesize iStage;
@synthesize iDirNum;
@synthesize iOverlapFactor;
@synthesize numSampleRate;
@synthesize numPacketsToRead;
@synthesize expectedLength;
@synthesize dirID;
@synthesize dilID;

-(id)init{
    Byte sB;
    
    self = [super init];
    
    ExtBufSize = 16384;
    iDirNum = 254;
    iDBSize = 512 * iDirNum;
    dAtt = 3800;
    [self setNumPacketsToRead:ExtBufSize / 4];
    [self setNumSampleRate:22050];
    
    dirID = [[NSMutableData alloc] init];
    dilID = [[NSMutableData alloc] init];
    for(sB = 0;sB < iDirNum;sB ++){
        Byte sG;
        [dirID appendBytes:&sB length:sizeof(Byte)];

        if(sB == 0 || sB == 1 || sB == 9 || sB == 25 || sB == 49 || sB == 79 || sB == 111 || sB == 142 || sB == 174 || sB == 204 || sB == 228 || sB == 244 || sB == 252 || sB == 253)
            sG = sB;
        else if(sB < 9){
            sG = 10 - sB;
        }
        else if(sB < 25)
            sG = 25 + 9 - sB;
        else if(sB < 49)
            sG = 49 + 25 - sB;
        else if(sB < 79)
            sG = 79 + 49 - sB;
        else if(sB < 111)
            sG = 111 + 79 - sB;
        else if(sB < 127)
            sG = 126 - 111 + sB;
        else if(sB < 142)
            sG = 111 - 126 + sB;
        else if(sB < 174)
            sG = 174 + 142 - sB;
        else if(sB < 204)
            sG = 204 + 174 - sB;
        else if(sB < 228)
            sG = 228 + 204 - sB;
        else if(sB < 244)
            sG = 244 + 228 - sB;
        else
            sG = 252 + 244 - sB;

        [dilID appendBytes:&sG length:sizeof(Byte)];
    }
    sB = 0;
    [dilID appendBytes:&sB length:sizeof(Byte)];
    [dirID appendBytes:&sB length:sizeof(Byte)];
    [dilID appendBytes:&sB length:sizeof(Byte)];
    [dirID appendBytes:&sB length:sizeof(Byte)];
    
    sHrtf = (malloc(sizeof(SInt16) * iDBSize));
    sPhase = (malloc(sizeof(SInt16) * iDBSize));
    
    iStage = 0;
    
    return self;
}

-(void)loadDatabaseFromDir{
    SInt32 nInt;
    NSData *val0,*val1;
    
//    NSLog(@"Search files in the application directories");
    if(iStage == 0){
        NSString *hrtfPath = [[NSBundle mainBundle] pathForResource:@"hrtf3d512" ofType:@"bin"];
        mHrtf = [NSData dataWithContentsOfFile:hrtfPath];
    }
    NSString *phasePath = [[NSBundle mainBundle] pathForResource:@"phase3d512" ofType:@"bin"];
    mPhase = [NSData dataWithContentsOfFile:phasePath];
    
    if(mHrtf == nil || mPhase == nil){
        NSNotification* notification;
        notification = [NSNotification notificationWithName:@"databaseError" object:self];
        NSNotificationCenter* center;
        center = [NSNotificationCenter defaultCenter];
        
        // Post notification
        [center postNotification:notification];
    }
    else{
        nInt = 0;
        while (nInt < iDBSize && !isCanceled){
            val0 = [mHrtf subdataWithRange:NSMakeRange(nInt * 2,1)];
            val1 = [mHrtf subdataWithRange:NSMakeRange(nInt * 2 + 1,1)];
            sHrtf[nInt] = *(SInt16 *)[val0 bytes];
            sHrtf[nInt] += *(SInt16 *)[val1 bytes] * 256;
            val0 = [mPhase subdataWithRange:NSMakeRange(nInt * 2,1)];
            val1 = [mPhase subdataWithRange:NSMakeRange(nInt * 2 + 1,1)];
            sPhase[nInt] = *(SInt16 *)[val0 bytes];
            sPhase[nInt] += *(SInt16 *)[val1 bytes] * 256;
            nInt ++;
        }
        if(isCanceled){
            NSNotification* notification;
            notification = [NSNotification notificationWithName:@"databaseError" object:self];
            NSNotificationCenter* center;
            center = [NSNotificationCenter defaultCenter];
            
            // Post notification
            [center postNotification:notification];
            return;
        }
        
        iStage = 2;
        
        isPrepared = NO;
        [self setIsPlaying:NO];
        
        NSNotification* notification;
        notification = [NSNotification notificationWithName:@"databaseReady" object:self];
        NSNotificationCenter* center;
        center = [NSNotificationCenter defaultCenter];
        
        // Post notification
        [center postNotification:notification];
    }
}

-(void)loadDatabase{
    NSURL *hrtfUrl,*phaseUrl;
    NSURL *sopaUrl;
    
    //  Prepare HRTF database
    SInt32 nInt;
    NSData *val0,*val1;
    
    if(iStage == 0){
        sopaUrl = [[NSURL alloc]initWithString:self.urlStr];
        NSURL *newUrl = sopaUrl.URLByDeletingLastPathComponent;
        hrtfUrl = [newUrl URLByAppendingPathComponent:@"hrtf3d512.bin"];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:hrtfUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
        self.databaseConn = [[NSURLConnection alloc]initWithRequest : request delegate : self];
        if(!self.databaseConn){
            [self loadDatabaseFromDir];
        }
    }
    else if(iStage == 1){
        sopaUrl = [[NSURL alloc]initWithString:self.urlStr];
        NSURL *newUrl = sopaUrl.URLByDeletingLastPathComponent;
        phaseUrl = [newUrl URLByAppendingPathComponent:@"phase3d512.bin"];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:phaseUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
        self.databaseConn = [[NSURLConnection alloc]initWithRequest : request delegate : self];
        if(!self.databaseConn){
            [self loadDatabaseFromDir];
        }
    }
    else if(iStage == 2){
        nInt = 0;
        while(nInt < iDBSize && !isCanceled){
            val0 = [mHrtf subdataWithRange:NSMakeRange(nInt * 2,1)];
            val1 = [mHrtf subdataWithRange:NSMakeRange(nInt * 2 + 1,1)];
            sHrtf[nInt] = *(SInt16 *)[val0 bytes];
            sHrtf[nInt] += *(SInt16 *)[val1 bytes] * 256;
            
            val0 = [mPhase subdataWithRange:NSMakeRange(nInt * 2,1)];
            val1 = [mPhase subdataWithRange:NSMakeRange(nInt * 2 + 1,1)];
            sPhase[nInt] = *(SInt16 *)[val0 bytes];
            sPhase[nInt] += *(SInt16 *)[val1 bytes] * 256;
            nInt ++;
        }
        mHrtf = nil;
        mPhase = nil;
        
        if(isCanceled){
            NSNotification* notification;
            notification = [NSNotification notificationWithName:@"databaseError" object:self];
            NSNotificationCenter* center;
            center = [NSNotificationCenter defaultCenter];
            
            // Post notification
            [center postNotification:notification];
            return;
        }
        isPrepared = NO;
        [self setIsPlaying:NO];
        
        NSNotification* notification;
        notification = [NSNotification notificationWithName:@"databaseReady" object:self];
        NSNotificationCenter* center;
        center = [NSNotificationCenter defaultCenter];
        
        // Post notification
        [center postNotification:notification];
    }
}

-(void)cancelLoading{
    if(!self.databaseConn)
        return;
    [[self databaseConn] cancel];
    self.databaseConn = nil;
    mHrtf = nil;
    mPhase = nil;
}

-(void)prepareSopaQueue{
    
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate = numSampleRate;
    audioFormat.mFormatID = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    audioFormat.mFramesPerPacket = 1;
    audioFormat.mChannelsPerFrame = 2;
    audioFormat.mBitsPerChannel = 16;
    audioFormat.mBytesPerPacket = 4;
    audioFormat.mBytesPerFrame = 4;
    audioFormat.mReserved = 0;
    
    AudioQueueNewOutput(&audioFormat,outputCallback,(__bridge void *)(self),NULL,NULL,0,&sopaQueueObject);
    
    AudioQueueBufferRef buffers[3];
    
    UInt32 bufferByteSize = numPacketsToRead * audioFormat.mBytesPerPacket;
    
    int bufferIndex;
    for(bufferIndex = 0;bufferIndex < 3;bufferIndex ++){
        AudioQueueAllocateBuffer(sopaQueueObject,bufferByteSize,&buffers[bufferIndex]);
        outputCallback((__bridge void *)(self),sopaQueueObject,buffers[bufferIndex]);
    }
    isPrepared = YES;
    AudioQueueStart(sopaQueueObject, NULL);
}

-(void)play{
    NSURL *sopaUrl;
    
    sPrev = 0;
    
    if(sopaQueueObject){
        AudioQueueDispose(sopaQueueObject,YES);
        sopaQueueObject = nil;
    }
    
    NSRange rang = [self.urlStr rangeOfString:@"://"];
    if(rang.location == NSNotFound){
        NSString *tmpStr = [[NSBundle mainBundle] pathForResource:@"default_cube" ofType:@"png"];
        NSString *newStr = [tmpStr stringByDeletingLastPathComponent];
        tmpStr = [newStr stringByAppendingPathComponent:self.urlStr];
        sopaUrl = [[NSURL alloc]initFileURLWithPath:tmpStr];
        
    }
    else {
        sopaUrl = [[NSURL alloc]initWithString:self.urlStr];
    }
    
    if(!sopaUrl){
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle : @"File not found"
                              message : @"The URL does not contain a proper file"
                              delegate : nil cancelButtonTitle : @"OK"
                              otherButtonTitles : nil];
        [alert show];
    }
    else{
        NSURLRequest *request = [NSURLRequest requestWithURL:sopaUrl];
    
        self.isLoaded = NO;
        numBytesWritten = nBytesRead = nBytesReady = 0;
    
        sCurrentData = 0;
        sCurrentDataOffset = 44;
        nTrial = NO;
        iSize = 0;
        self.myConn = [[NSURLConnection alloc]initWithRequest : request delegate : self];
        if (self.myConn == nil) {
            [self setIsPlaying:NO];            
            sCurrentDataOffset = 0;

            UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle : @"ConnectionError"
                              message : @"ConnectionError"
                              delegate : nil cancelButtonTitle : @"OK"
                              otherButtonTitles : nil];
            [alert show];
 
            [self setIsPlaying:NO];
        
            NSNotification* notification;
            notification = [NSNotification notificationWithName:@"errorDetection" object:self];
            NSNotificationCenter* center;
            center = [NSNotificationCenter defaultCenter];
        
        // Post notification
            [center postNotification:notification];
        }
        else
            [self setIsPlaying:YES];
    }
}

-(void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
	NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;

    if(!isFromDir){
        connStatusCode = [res statusCode];

        if(connStatusCode >= 400){
            [connection cancel];
            [self connection:connection didFailWithError:nil];
        }
        else if (connStatusCode != 200) {
            [connection cancel];
            [self connection:connection didFailWithError:nil];
        }
        else if(iStage < 2){
            if(iStage == 0)
                mHrtf = [[NSMutableData alloc]initWithLength:0];
            else if(iStage == 1)
                mPhase = [[NSMutableData alloc]initWithLength:0];
        }
    }
    self.expectedLength = [res expectedContentLength];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    BOOL isWrong = NO;
    
    if(iStage == 0){
        [mHrtf appendData:data];
        return;
    }
    else if(iStage == 1){
        [mPhase appendData:data];
        return;
    }
    else if(!isPlaying)
        return;
    //  Append data to data stream
    if(sCurrentData == 0){
        if(mData0 == nil){
            mData0 = [[NSMutableData alloc] initWithData:data];
        }
        else{
            [mData0 appendData:data];
        }
    }
    else{
        if(mData1 == nil){
            mData1 = [[NSMutableData alloc] initWithData:data];
        }
        else{
            [mData1 appendData:data];
        }
    }
    
    self.nBytesRead += [data length];

    //  Check file header
    if(sCurrentData == 0 && self.nBytesRead > ExtBufSize * 4 && !nTrial){
        int nDat[4];
        int nTerm0[] = {82,73,70,70};   // RIFF
        int nTerm1[] = {83,79,80,65};   // SOPA
        int nTerm2[] = {102,109,116};   // fmt
        int nInt,nBit,nSampleRate;
        NSMutableData *val0;
        
        for(nInt = 0;nInt < 4;nInt ++){
            val0 = (NSMutableData *)[mData0 subdataWithRange:NSMakeRange(nInt,1)];
            nDat[nInt] = *(int *)([val0 bytes]);
        }
        if(memcmp(nDat,nTerm0,4) != 0){
            val0 = nil;
            isWrong = YES;
        }
        if(self.expectedLength < 0){
            val0 = (NSMutableData *)[mData0 subdataWithRange:NSMakeRange(4,1)];
            expectedLength = *(int *)([val0 bytes]);
            val0 = (NSMutableData *)[mData0 subdataWithRange:NSMakeRange(5,1)];
            expectedLength += *(int *)([val0 bytes]) * 256;
            val0 = (NSMutableData *)[mData0 subdataWithRange:NSMakeRange(6,1)];
            expectedLength += *(int *)([val0 bytes]) * 65536;
            val0 = (NSMutableData *)[mData0 subdataWithRange:NSMakeRange(7,1)];
            expectedLength += *(int *)([val0 bytes]) * 16777216;
        }
        for(nInt = 0;nInt < 4;nInt ++){
            val0 = (NSMutableData *)[mData0 subdataWithRange:NSMakeRange(8 + nInt,1)];
            nDat[nInt] = *(int *)([val0 bytes]);
        }
        if(memcmp(nDat,nTerm1,4) != 0){
            val0 = nil;
            isWrong = YES;
        }
        for(nInt = 0;nInt < 3;nInt ++){
            val0 = (NSMutableData *)[mData0 subdataWithRange:NSMakeRange(12 + nInt,1)];
            nDat[nInt] = *(int *)([val0 bytes]);
        }
        if(memcmp(nDat,nTerm2,3) != 0){
            val0 = nil;
            return;
        }
        val0 = (NSMutableData *)[mData0 subdataWithRange:NSMakeRange(16,1)];
        nBit = *(int *)([val0 bytes]);
        if(nBit != 16){
            val0 = nil;
            isWrong = YES;
        }
        val0 = (NSMutableData *)[mData0 subdataWithRange:NSMakeRange(20,1)];
        nBit = *(int *)([val0 bytes]);
        if(nBit != 1){
            val0 = nil;
            isWrong = YES;
        }
        val0 = (NSMutableData *)[mData0 subdataWithRange:NSMakeRange(22,1)];
        iOverlapFactor = *(int *)([val0 bytes]);
        if(iOverlapFactor != 2 && iOverlapFactor != 4){
            val0 = nil;
            isWrong = YES;
        }
        val0 = (NSMutableData *)[mData0 subdataWithRange:NSMakeRange(24,1)];
        nSampleRate = *(int *)([val0 bytes]);
        val0 = (NSMutableData *)[mData0 subdataWithRange:NSMakeRange(25,1)];
        nSampleRate += *(int *)([val0 bytes]) * 256;
        if(nSampleRate <= 0){
            val0 = nil;
            isWrong = YES;
        }
        val0 = (NSMutableData *)[mData0 subdataWithRange:NSMakeRange(39,1)];
        if(*(int *)([val0 bytes]) <= 1){
            isVersion1 = YES;
        }
        else
            isVersion1 = NO;
        
        if(isWrong){
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle : @"SOPA HeaderError"
                                      message:@"Can not decode this file!"
                                      delegate : nil cancelButtonTitle : @"OK"
                                      otherButtonTitles : nil];
            [alertView show];
            
            NSNotification* notification;
            notification = [NSNotification notificationWithName:@"errorDetection" object:self];
            NSNotificationCenter* center;
            center = [NSNotificationCenter defaultCenter];
            
            // Post notification
            [center postNotification:notification];
        }
        else{
            [self setNumSampleRate:nSampleRate];
            iOff = numOffset = 44;
            nTrial = YES;
            sCurrentData ++;
            [self prepareSopaQueue];
        }
    }
    NSNotification* notification;
    notification = [NSNotification notificationWithName:@"connectionProgress" object:self];
    NSNotificationCenter* center;
    center = [NSNotificationCenter defaultCenter];
    
    // Post notification
    [center postNotification:notification];
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    connection = nil;
    if(iStage == 0)
        [self loadDatabaseFromDir];
    else if(isPlaying){
        isLoaded = YES;
        
        NSNotification* notification;
        notification = [NSNotification notificationWithName:@"connectionFailed" object:self];
        NSNotificationCenter* center;
        center = [NSNotificationCenter defaultCenter];
        
        // Post notification
        [center postNotification:notification];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    connection = nil;
    if(!isPlaying){
        mData0 = nil;
        mData1 = nil;
    }
    if(iStage == 0 || iStage == 1){
        iStage ++;
        [self loadDatabase];
    }
    else{
        isLoaded = YES;
        if(!nTrial || connStatusCode >= 400){
            NSNotification* notification;
            notification = [NSNotification notificationWithName:@"fileError" object:self];
            NSNotificationCenter* center;
            center = [NSNotificationCenter defaultCenter];
            
            // Post notification
            [center postNotification:notification];
        }
    }
}

-(void)stop:(BOOL)shouldStopImmediate{
    AudioQueueStop(sopaQueueObject, shouldStopImmediate);
    isPrepared = NO;
    
    nTrial = NO;
    
    self.nBytesRead = 0;
    mData0 = nil;
    mData1 = nil;
    if(self.myConn != nil){
        [[self myConn] cancel];
        self.myConn = nil;
    }
    
    NSNotification* notification;
    notification = [NSNotification notificationWithName:@"sopaReproductionFinished" object:self];
    NSNotificationCenter* center;
    center = [NSNotificationCenter defaultCenter];
    
    // Post notification
    [center postNotification:notification];
    
}

-(SInt16)inputData:(UInt32)nNum asByte:(BOOL)isByte{
    SInt16 sVal;
    SInt32 sNumRead;
    unsigned char cByte;
    BOOL isNil = NO;
    
    if(sCurrentData == 1){
        if(mData0 == nil)
            isNil = YES;
        sNumRead = mData0.length;
        if(self.iSize == 0)
            sCurrentDataOffset = nNum;
    }
    else{
        if(mData1 == nil)
            isNil = YES;
        sNumRead = mData1.length;
    }
    
    if(!isLoaded && isNil){
        NSNotification* notification;
        notification = [NSNotification notificationWithName:@"errorDetection" object:self];
        NSNotificationCenter* center;
        center = [NSNotificationCenter defaultCenter];
        
        // Post notification
        [center postNotification:notification];
        return 0;
    }
    
    if(nNum < self.nBytesRead){
        if(sCurrentData == 1)
            [mData0 getBytes: &cByte range: NSMakeRange(sCurrentDataOffset,sizeof(unsigned char))];
        else
            [mData1 getBytes: &cByte range: NSMakeRange(sCurrentDataOffset,sizeof(unsigned char))];
        if(isByte)
            sVal = (Byte)cByte;
        else
            sVal = (SInt16)cByte;
    }
    else if(self.isLoaded == NO){
        if([self isPlaying] == YES && nNum == self.nBytesRead){
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle : @"Streaming error!"
                                      message : @"Error detected while streaming SOPA data"
                                      delegate: nil
                                      cancelButtonTitle : @"OK"
                                      otherButtonTitles : nil];
            [alertView performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
            NSNotification* notification;
            notification = [NSNotification notificationWithName:@"errorDetection" object:self];
            NSNotificationCenter* center;
            center = [NSNotificationCenter defaultCenter];
            
            // Post notification
            [center postNotification:notification];
        }
        sVal = 0;
    }
    else
        sVal = 0;
    sCurrentDataOffset ++;
    if(sCurrentDataOffset == sNumRead){
        if(sCurrentData == 1){
            mData0 = nil;
            sCurrentData = 0;
        }
        else{
            mData1 = nil;
            sCurrentData ++;
        }
        sCurrentDataOffset = 0;
    }
    
    return sVal;
}

-(void)_processor:(AudioQueueRef)inAQ queueBuffer:(AudioQueueBufferRef)inBuffer{
    OSStatus err;
    unsigned char cByte;
    UInt32 iCount,iFnum;
    UInt32 numPackets = self.numPacketsToRead;
    SInt32 iInt,sSample,iNum,iPos,iPosImage;
    SInt32 iBufSize = 0;
    SInt16 iMarg,iEnd;
    SInt16 sAnglePoint,sAnglRef;
    SInt16 sStreamPoint;
    double dSpL,dSpR,dSpImageL,dSpImageR,dPhaseL,dPhaseR,dPhaseImageL,dPhaseImageR;
    
    SInt16 nSin;
    
    SInt16 *output = inBuffer->mAudioData;
    
    if(!isPlaying){
        return;
    }
    else if(self.numOffset == 44){
        
        iInt = 5;
        sSample = 1;
        if(isVersion1){
            while(sSample > 0){
                sSample = [self inputData:self.numOffset + iInt asByte:TRUE];
                iInt += 4;
            }
        }
        else{
            while(sSample != 255){
                sSample = [self inputData:self.numOffset + iInt asByte:TRUE];
                iInt += 4;
            }
        }

        iSize = iInt - 5;                    // Frame size
        iRatio = 44100 / numSampleRate;
        iRatio *= iSize / 512;
        iProc = iSize / iOverlapFactor;
        iProcBytes = iProc * 4;
        iFrames = numPackets / iProc;
        iRem = iSize - iProc;
        iHlf = iSize / 2;
        
        sCurrentDataOffset = numOffset;
        
        ResultLeft = (malloc(sizeof(SInt16) * iSize));
        ResultRight = (malloc(sizeof(SInt16) * iSize));
        
        sAngl = malloc(sizeof(SInt16) * iHlf * iOverlapFactor);
        sAngr = malloc(sizeof(SInt16) * iHlf * iOverlapFactor);
        sStream = (malloc(sizeof(SInt16) * iSize));
        
        /* Prepare Hanning window */
        dHan = (malloc(sizeof(double) * iSize));
        for(iNum = 0;iNum < iSize;iNum ++){
            dHan[iNum] = (1 - cos(2 * M_PI * (double)iNum / (double)iSize)) / 4;
        }
        
        NSNotification* notification;
        notification = [NSNotification notificationWithName:@"sopaInfo" object:self];
        NSNotificationCenter* center;
        center = [NSNotificationCenter defaultCenter];
        
        // Post notification
        [center postNotification:notification];
    }
    
    double realLeft[iSize + 1];
    double imageLeft[iSize + 1];
    double realRight[iSize + 1];
    double imageRight[iSize + 1];
    
    fft *trans;
    trans = [[fft alloc] initWithFrameSize:iSize];
    if(![trans isPowerOfTwo]){
        [self stop:YES];
        return;
    }
    
    for(iFnum = 0;iFnum < iFrames;iFnum ++){
        
        if(numOffset == 44){
            sAnglePoint = sStreamPoint = 0;
            iEnd = iSize * 4;
        }
        else if(iFnum == 0){
            sAnglePoint = (iOverlapFactor - 1) * iHlf;
            sStreamPoint = (iOverlapFactor - 1) * iProc;
            iEnd = iProcBytes;
        }
        else{
            sAnglePoint = ((iFnum - 1) % iOverlapFactor) * iHlf;
            sStreamPoint = ((iFnum - 1) % iOverlapFactor) * iProc;
            iEnd = iProcBytes;
        }
        for(iCount = 0;iCount < iEnd;iCount += 4){
            SInt16 sLoc = [self inputData:iOff + iCount asByte:TRUE];
//            if(isVersion1)
//                sLoc = [self convertDir:sLoc];
            [dilID getBytes:&cByte range:NSMakeRange(sLoc,1)];
            sAngl[sAnglePoint + iCount / 2 + 1] = (SInt16)cByte;
            [dirID getBytes:&cByte range:NSMakeRange(sLoc,1)];
            sAngr[sAnglePoint + iCount / 2 + 1] = (SInt16)cByte;
            
            sLoc = [self inputData:iOff + iCount + 1 asByte:TRUE];
//            if(isVersion1)
//                sLoc = [self convertDir:sLoc];
            [dilID getBytes:&cByte range:NSMakeRange(sLoc,1)];
            sAngl[sAnglePoint + iCount / 2] = (SInt16)cByte;
            [dirID getBytes:&cByte range:NSMakeRange(sLoc,1)];
            sAngr[sAnglePoint + iCount / 2] = (SInt16)cByte;

            nSin = [self inputData:iOff + iCount + 2 asByte:FALSE];
            nSin += [self inputData:iOff + iCount + 3 asByte:FALSE] * 256;
            if(iEnd == iSize * 4){
                sStream[iCount / 4] = nSin;          // PCM data
            }
            else{
                sStream[sStreamPoint + iCount / 4] = nSin;        // PCM data
            }
        }
        iOff += iEnd;
        for(iNum = 0;iNum < iSize;iNum ++){
            SInt16 sRef;
            if(iEnd == iSize * 4)
                sRef = iNum;
            else
                sRef = sStreamPoint + iProc + iNum;
            if(sRef >= iSize)
                sRef -= iSize;
            realRight[iNum] = sStream[sRef];
            imageRight[iNum] = 0;
        }
        
        [trans fastFt:realRight:imageRight:NO];
        
        for(sAnglRef = 0;sAnglRef < iHlf;sAnglRef ++){
            iNum = (iHlf * (iFnum % iOverlapFactor) + sAnglRef);
            if(iNum >= iHlf * iOverlapFactor)
                iNum -= iHlf * iOverlapFactor;
            SInt32 iFreq = (sAnglRef / iRatio);
            if(sAngl[iNum] < 0 || iFreq == 0 || sAngl[iNum] == 255){
                dSpL = dSpR = realRight[sAnglRef];
                dSpImageL = dSpImageR = realRight[sAnglRef];
                dPhaseL = dPhaseR = imageRight[sAnglRef];
                dPhaseImageL = dPhaseImageR = imageRight[sAnglRef];
            }
            else{
                //              Construct Temporal HRTF by using HRTF database (left channel)
                iPos = 512 * sAngl[iNum] + iFreq;
                iPosImage = 512 * sAngl[iNum] + 512 - iFreq;
                if(iPosImage >= iDBSize)
                    iPosImage -= iDBSize;
                else if(iPosImage < 0)
                    iPosImage += iDBSize;
                if(iPos >= iDBSize)
                    iPos -= iDBSize;
                else if(iPos < 0)
                    iPos += iDBSize;
                
                //              Superimpose Temporal HRTF on spectrum of reference signal (left channel)
                dSpL = realRight[sAnglRef] * (double)sHrtf[iPos] / dAtt;
                dSpImageL = realRight[iSize - sAnglRef] * (double)sHrtf[iPosImage] / dAtt;
                dPhaseL = imageRight[sAnglRef] + (double)sPhase[iPos] / 10000.0;
                dPhaseImageL = imageRight[iSize - sAnglRef] + (double)sPhase[iPosImage] / 10000.0;
                
                //              Construct Temporal HRTF by using HRTF database (right channel)
                iPos = 512 * sAngr[iNum] + iFreq;
                iPosImage = 512 * sAngr[iNum] + 512 - iFreq;
                if(iPosImage >= iDBSize)
                    iPosImage -= iDBSize;
                else if(iPosImage < 0)
                    iPosImage += iDBSize;
                if(iPos >= iDBSize)
                    iPos -= iDBSize;
                else if(iPos < 0)
                    iPos += iDBSize;
                
                //              Superimpose Temporal HRTF on spectrum of reference signal (right channel)
                dSpR = realRight[sAnglRef] * (double)sHrtf[iPos] / dAtt;
                dSpImageR = realRight[iSize - sAnglRef] * (double)sHrtf[iPosImage] / dAtt;
                dPhaseR = imageRight[sAnglRef] + (double)sPhase[iPos] / 10000.0;
                dPhaseImageR = imageRight[iSize - sAnglRef] + (double)sPhase[iPosImage] / 10000.0;
            }
            realLeft[sAnglRef] = dSpL * cos(dPhaseL);
            realRight[sAnglRef] = dSpR * cos(dPhaseR);
            imageLeft[sAnglRef] = dSpL * sin(dPhaseL);
            imageRight[sAnglRef] = dSpR * sin(dPhaseR);
            realLeft[iSize - sAnglRef] = dSpImageL * cos(dPhaseImageL);
            realRight[iSize - sAnglRef] = dSpImageR * cos(dPhaseImageR);
            imageLeft[iSize - sAnglRef] = dSpImageL * sin(dPhaseImageL);
            imageRight[iSize - sAnglRef] = dSpImageR * sin(dPhaseImageR);
        }
        
        realLeft[iHlf] = realRight[iHlf];
        imageLeft[iHlf] = imageRight[iHlf];
        
        [trans fastFt:realLeft:imageLeft:YES];              // Inverse FFT (left channel)
        [trans fastFt:realRight:imageRight:YES];            // Inverse FFT (right channel)
        
        //      Overlap and add process
        for(iNum = 0;iNum < iSize;iNum ++){
            realLeft[iNum] *= dHan[iNum];
            realRight[iNum] *= dHan[iNum];
            
            if(numBytesWritten == 0){
                ResultLeft[iNum] = (SInt16)realLeft[iNum];
                ResultRight[iNum] = (SInt16)realRight[iNum];
            }
            else{
                ResultLeft[iNum] += (SInt16)realLeft[iNum];
                ResultRight[iNum] += (SInt16)realRight[iNum];
            }
        }
        
        iMarg = 44;
        if(!isLoaded)
            iMarg += iSize * 4;
        nBytesReady = nBytesRead - iMarg;
        for(iCount = 0;iCount < iSize;iCount ++){
            if(iCount < iProc){
                if(inBuffer->mAudioData == nil){
                    UIAlertView *alert = [[UIAlertView alloc]
                                          initWithTitle : @"Streaming error"
                                          message : @"Time out"
                                          delegate : nil
                                          cancelButtonTitle : @"OK"
                                          otherButtonTitles : nil];
                    [alert show];
                    NSNotification* notification;
                    notification = [NSNotification notificationWithName:@"errorDetection" object:self];
                    NSNotificationCenter* center;
                    center = [NSNotificationCenter defaultCenter];
                    
                    // Post notification
                    [center postNotification:notification];
                    
                    return;
                }
                *output = ResultLeft[iCount];
                output++;
                *output = ResultRight[iCount];
                output++;
                iBufSize += 4;
                numBytesWritten += 4;
                numOffset += 4;
                if(numBytesWritten > nBytesReady){
                    if(!isLoaded){
                        UIAlertView *alert = [[UIAlertView alloc]
                                              initWithTitle : @"Streaming error"
                                              message : @"Terminated because not enough data are loaded"
                                              delegate : self
                                              cancelButtonTitle : @"OK"
                                              otherButtonTitles : nil];
                        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
                    }
                    NSNotification* notification;
                    notification = [NSNotification notificationWithName:@"errorDetection" object:self];
                    NSNotificationCenter* center;
                    center = [NSNotificationCenter defaultCenter];
                    
                    // Post notification
                    [center postNotification:notification];
                    
                    return;
                }
            }
            if(iCount < iRem){
                ResultLeft[iCount] = ResultLeft[iCount + iProc];
                ResultRight[iCount] = ResultRight[iCount + iProc];
            }
            else{
                ResultLeft[iCount] = 0;
                ResultRight[iCount] = 0;
            }
        }

        NSNotification* notification;
        notification = [NSNotification notificationWithName:@"reproductionProgress" object:self];
        NSNotificationCenter* center;
        center = [NSNotificationCenter defaultCenter];
        
        // Post notification
        [center postNotification:notification];
 
    }
    if(nTrial){
        inBuffer->mAudioDataByteSize = iBufSize;
        err = AudioQueueEnqueueBuffer(inAQ,inBuffer,0,NULL);
        if(err){
            if(isPlaying){
                [self setIsPlaying:NO];
                [self stop:YES];
            }
        }
    }
}

-(SInt16)convertDir:(SInt16)dir{
    SInt16 sRet,sTmp;
    if(dir > 72)
        return dir;
    sTmp = dir - 1;
    dir = 71 - sTmp;
/*
    if(dir <= 36)
        sRet = dir * 16 / 36 + 127;
    else
        sRet = 111 + ((71 - dir) * 16 / 36);    */

    if(dir < 36)
        sRet = 126 - dir * 16 / 36;
    else
        sRet = 127 + (dir - 35) * 16 / 36;
    return sRet;
}

-(void)dealloc{
    free(ResultLeft);
    free(ResultRight);
    free(sHrtf);
    free(sPhase);
    free(dHan);
    free(sAngl);
    free(sStream);
    if(sopaQueueObject)
        AudioQueueDispose(sopaQueueObject,YES);
}

@end