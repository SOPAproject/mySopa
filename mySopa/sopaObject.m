//
//  sopaObject.m
//  mySopa
//
//  Created by Kaoru Ashihara on 29 Mar. 2014
//  Revised on 2 Mar. 2015
//  Copyright (c) 2015, AIST. All rights reserved.
//

#import "sopaObject.h"

static const double dWPi = M_PI * 2;

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
    SInt16 connStatusCode;
    SInt16 sHeaderSize;
    SInt16 sSec;
    SInt16 sVersion;
    SInt16 sDirArry[256][72][36];
    double *dHan;
    double dAtt;
    double *dAttRt;
    BOOL isFileNew;
    NSMutableData *mData0,*mData1,*mHrtf,*mPhase;
    CC3Vector vecAngl[256];
}

@synthesize ExtBufSize;
@synthesize numIntvl;
@synthesize myConn;
@synthesize databaseConn;
@synthesize urlStr;
@synthesize numBytesWritten;
@synthesize numOffset;
@synthesize nBytesRead;
@synthesize nBytesReady;
@synthesize bCardioid;
@synthesize nTrial;
@synthesize isLoaded;
@synthesize isPrepared;
@synthesize isPlaying;
@synthesize isCanceled;
@synthesize isFromDir;
@synthesize isAsset;
@synthesize isSequel;
@synthesize isSS;
@synthesize isImageUpdate;
@synthesize isNewLoop;
@synthesize isProceed;
@synthesize isBeginning;
@synthesize iSize;
@synthesize iStage;
@synthesize iDirNum;
@synthesize iOverlapFactor;
@synthesize iFileNum;
@synthesize iMilliSecIntvl;
@synthesize iAzim;
@synthesize iElev;
@synthesize iRoll;
@synthesize numSampleRate;
@synthesize numPacketsToRead;
@synthesize expectedLength;
@synthesize lChunkSize;
@synthesize lBytesDone;
@synthesize sStream;
@synthesize ResultLeft;
@synthesize ResultRight;
@synthesize softAtt;
@synthesize sharpAtt;

typedef struct{
    float fReal;
    float fX;
    float fY;
    float fZ;
}quaternion;

-(id)init{
    SInt16 sNum,sAz,sEl;
    double dAz,dEl;
    
    self = [super init];
    
    ExtBufSize = 16384;
    numIntvl = 44100 * 4;
    iDirNum = 254;
    iDBSize = 512 * iDirNum;
    dAtt = 4096;
    [self setNumPacketsToRead:ExtBufSize / 4];
    [self setNumSampleRate:22050];
    isFileNew = NO;
    isImageUpdate = NO;
    [self setIsBeginning:NO];
    
    sharpAtt = [[NSMutableData alloc] init];
    softAtt = [[NSMutableData alloc] init];
    
    iAzim = 0;
    iElev = 18;
    iRoll = 18;
    
    for(sNum = 0;sNum < 127;sNum++){
        [self initCoord:sNum];
    }
    for(sNum = 0;sNum < 127;sNum++){
        for(sAz = 0;sAz < 72;sAz ++){
            dAz = M_PI * ((double)sAz - 36) / 36;
            
            for(sEl = -18;sEl < 18;sEl ++){
                dEl = M_PI * (double)sEl / 36;
                sDirArry[sNum][sAz][sEl + 18] = [self modifySector:sNum withPan:dAz withTilt:dEl];
            }
        }
    }
    for(sNum = 0;sNum < 127;sNum++){
        for(sAz = 0;sAz < 72;sAz ++){
            for(sEl = 0;sEl < 36;sEl ++){
                sDirArry[253 - sNum][sAz][sEl] = 253 - sDirArry[sNum][sAz][sEl];
            }
        }
    }
    
    sHrtf = (malloc(sizeof(SInt16) * iDBSize));
    sPhase = (malloc(sizeof(SInt16) * iDBSize));
    
    iStage = 0;
    
    if(sopaQueueObject){
        AudioQueueDispose(sopaQueueObject,YES);
        sopaQueueObject = nil;
    }
    
    return self;
}

-(void)loadDatabaseFromDir{
    SInt32 nInt;
    NSData *val0,*val1;
    
    if(iStage > 1){
        return;
    }
//    NSLog(@"Search files in the application directories");
    if(iStage == 0){
        NSString *hrtfPath = [[NSBundle mainBundle] pathForResource:@"hrtf3d512" ofType:@"bin"];
        mHrtf = [[NSMutableData alloc]initWithData:[NSData dataWithContentsOfFile:hrtfPath]];
        iStage ++;
    }
    if(iStage == 1){
        NSString *phasePath = [[NSBundle mainBundle] pathForResource:@"phase3d512" ofType:@"bin"];
        mPhase = [[NSMutableData alloc]initWithData:[NSData dataWithContentsOfFile:phasePath]];
        iStage ++;
    }
    
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
    SInt32 nInt,nIw;
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
            nIw = nInt * 2;
            val0 = [mHrtf subdataWithRange:NSMakeRange(nIw,1)];
            val1 = [mHrtf subdataWithRange:NSMakeRange(nIw + 1,1)];
            sHrtf[nInt] = *(SInt16 *)[val0 bytes];
            sHrtf[nInt] += *(SInt16 *)[val1 bytes] * 256;
            
            val0 = [mPhase subdataWithRange:NSMakeRange(nIw,1)];
            val1 = [mPhase subdataWithRange:NSMakeRange(nIw + 1,1)];
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

-(void)start{
    if(isBeginning){
        sCurrentData ++;
        [self prepareSopaQueue];
        [self setIsBeginning:NO];
    }
    else if(myConn == nil){
        [self play];
    }
}

-(void)play{
    NSURL *sopaUrl;
    
    if(self.isAsset){
//        sopaUrl = [NSURL fileURLWithPath:[self urlStr]];
        sopaUrl = [NSURL URLWithString:self.urlStr];
        
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
        NSURLRequest *request = [NSURLRequest requestWithURL:sopaUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
    
        self.isLoaded = NO;
        if(iSize == 0){
            nTrial = NO;
            [self setIsBeginning:NO];
            numBytesWritten = nBytesRead = nBytesReady = 0;
            sCurrentData = 0;
            sSec = 0;
            sCurrentDataOffset = 44;
            lBytesDone = 0;
            isProceed = NO;
            isNewLoop = NO;
        }
    
        self.myConn = [[NSURLConnection alloc]initWithRequest : request delegate : self];
        if(self.myConn == nil) {
            [self setIsPlaying:NO];
            sCurrentDataOffset = 0;
            
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle : @"ConnectionError"
                                  message : @"ConnectionError"
                                  delegate : nil cancelButtonTitle : @"OK"
                                  otherButtonTitles : nil];
            [alert show];
            
            NSNotification* notification;
            notification = [NSNotification notificationWithName:@"errorDetection" object:self];
            NSNotificationCenter* center;
            center = [NSNotificationCenter defaultCenter];
            
            // Post notification
            [center postNotification:notification];
        }
        else{
            if(isSequel){
                if(self.nBytesRead > 0)
                    isFileNew = YES;
                sHeaderSize = 44;
            }
            else
                isFileNew = NO;
        }
    }
}

-(void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
	NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
    NSString *strNum;
    NSString *strNext;
    NSString *tmpStr;
    
    if(!isFromDir){
        connStatusCode = [res statusCode];
        if(connStatusCode == 404 && isSequel && iFileNum > 0){
            [connection cancel];
            if(iStage < 2)
                [self loadDatabaseFromDir];
            else if(iStage == 2){
                strNum = [NSString stringWithFormat:@"%02d.",iFileNum];
                strNext = [NSString stringWithFormat:@"%02d.",0];
                iFileNum = 0;
                isNewLoop = YES;
                tmpStr = [[self urlStr]stringByReplacingOccurrencesOfString:strNum withString:strNext];
                self.urlStr = tmpStr;
                
                [self play];
            }
        }
        else{
            if(connStatusCode >= 400){
                [connection cancel];
                //            [self connection:connection didFailWithError:nil];
                return;
            }
            else if (connStatusCode != 200) {
                [connection cancel];
                //            [self connection:connection didFailWithError:nil];
                return;
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
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSMutableData *)data{
    BOOL isWrong = NO;
    NSMutableData *newData;
    
    if(iStage == 0){
        [mHrtf appendData:data];
        return;
    }
    else if(iStage == 1){
        [mPhase appendData:data];
        return;
    }
/*
    else if(!isPlaying)
        return; */
    //  Append data to data stream
    if(isFileNew){
        if(data.length <= sHeaderSize)
            sHeaderSize -= data.length;
        else{
            newData = [[NSMutableData alloc]initWithData:[data subdataWithRange:NSMakeRange(sHeaderSize,data.length - sHeaderSize)]];
//            [data replaceBytesInRange:NSMakeRange(0,sHeaderSize) withBytes:NULL length:0];
            data = newData;
            isFileNew = NO;
            sHeaderSize = 44;
        }
    }
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
    
    self.nBytesRead += (UInt32)[data length];

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
        else
            iOverlapFactor = 2;
        val0 = (NSMutableData *)[mData0 subdataWithRange:NSMakeRange(24,1)];
        nSampleRate = *(int *)([val0 bytes]);
        val0 = (NSMutableData *)[mData0 subdataWithRange:NSMakeRange(25,1)];
        nSampleRate += *(int *)([val0 bytes]) * 256;
        if(nSampleRate <= 0){
            val0 = nil;
            isWrong = YES;
        }
        numIntvl = nSampleRate * iMilliSecIntvl / 1000 * 4;
        val0 = (NSMutableData *)[mData0 subdataWithRange:NSMakeRange(39,1)];
        sVersion = *(int *)([val0 bytes]);
/*
        if(sVersion >= 3 || isSS){
            iOverlapFactor = 2;
        }   */
       
        val0 = (NSMutableData *)[mData0 subdataWithRange:NSMakeRange(40,1)];
        lChunkSize = *(int *)([val0 bytes]);
        val0 = (NSMutableData *)[mData0 subdataWithRange:NSMakeRange(41,1)];
        lChunkSize += *(int *)([val0 bytes]) * 256;
        val0 = (NSMutableData *)[mData0 subdataWithRange:NSMakeRange(42,1)];
        lChunkSize += *(int *)([val0 bytes]) * 65536;
        val0 = (NSMutableData *)[mData0 subdataWithRange:NSMakeRange(43,1)];
        lChunkSize += *(int *)([val0 bytes]) * 16777216;
//        NSLog(@"Chunk size %ld",lChunkSize);

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
            [self setIsBeginning:YES];
        }
        if(nTrial && isPlaying){
            [self start];
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
    NSString *strNum;
    NSString *strNext;
    NSString *newStr;
    
    connection = nil;
/*
    if(!isPlaying){
        mData0 = nil;
        mData1 = nil;
    }   */
    if(iStage == 0 || iStage == 1){
        iStage ++;
        [self loadDatabase];
    }
    else{
        isLoaded = YES;
        if(connStatusCode >= 400){
            NSNotification* notification;
            notification = [NSNotification notificationWithName:@"fileError" object:self];
            NSNotificationCenter* center;
            center = [NSNotificationCenter defaultCenter];
            
            // Post notification
            [center postNotification:notification];
        }
        else{
            if(isSequel){
                strNum = [NSString stringWithFormat:@"%02d.",iFileNum];
                iFileNum ++;
                strNext = [NSString stringWithFormat:@"%02d.",iFileNum];
                newStr = [[self urlStr]stringByReplacingOccurrencesOfString:strNum withString:strNext];
                self.urlStr = newStr;
//              NSLog(@"%@",[self urlStr]);
            }
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
    unsigned char cByte[1];
    BOOL isNil = NO;
    
    cByte[0] = 0;
    if(sCurrentData == 1){
        if(mData0 == nil)
            isNil = YES;
        sNumRead = (SInt32)mData0.length;
        if(self.iSize == 0)
            sCurrentDataOffset = nNum;
    }
    else{
        if(mData1 == nil)
            isNil = YES;
        sNumRead = (SInt32)mData1.length;
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
        if(isNil){
            sVal = 0;
        }
        else{
            if(sCurrentData == 1)
                [mData0 getBytes: &cByte range: NSMakeRange(sCurrentDataOffset,sizeof(unsigned char))];
            else
                [mData1 getBytes: &cByte range: NSMakeRange(sCurrentDataOffset,sizeof(unsigned char))];
            
            if(isByte)
                sVal = (Byte)cByte[0];
            else
                sVal = (SInt16)cByte[0];
        }
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
    else{
        sVal = 0;
//        NSLog(@"No data!");
    }
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
    UInt32 iCount,iFnum,iNumero;
    UInt32 numPackets = self.numPacketsToRead;
    SInt32 iInt,sSample,iNum,iPos,iPosImage,iPosSec,iPosSecImage;
    SInt32 iBufSize = 0;
    SInt16 nSin;
    SInt16 iMarg,iEnd;
    SInt16 sAnglePoint,sAnglRef;
    SInt16 sStreamPoint;
    SInt16 *nAdr;
    SInt16 sPos;
    SInt16 *output = inBuffer->mAudioData;
    SInt16 sRef;
    double dRise,dPh,dWAtt,dV,dRoll;
    double dSpL,dSpR,dSpImageL,dSpImageR,dPhaseL,dPhaseR,dPhaseImageL,dPhaseImageR;
    
    if(!isPlaying){
        return;
    }
    else if(self.numOffset == 44){
        
        iInt = 5;
        sSample = 1;
        if(sVersion == 1){
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
        dRise = (double)iSize / 8;
        
        sCurrentDataOffset = numOffset;
        
        sStream = nil;
        ResultLeft = nil;
        ResultRight = nil;

        ResultLeft = [[NSMutableData alloc]initWithLength:sizeof(SInt16) * iSize];
        ResultRight = [[NSMutableData alloc]initWithLength:sizeof(SInt16) * iSize];
        sStream = [[NSMutableData alloc]initWithLength:sizeof(SInt16) * iSize];
        
        if(sAngl == nil)
            sAngl = malloc(sizeof(SInt16) * iSize * 2);
        if(sAngr == nil)
            sAngr = malloc(sizeof(SInt16) * iSize * 2);
        
        /* Prepare Hanning window */
        if(dHan == nil)
            dHan = (malloc(sizeof(double) * iSize));
        for(iNum = 0;iNum < iSize;iNum ++){
            if(iNum < (int)dRise)
                dHan[iNum] = (1 - cos(M_PI * (double)iNum / dRise)) / (double)iOverlapFactor;
            else if(iSize - iNum <= (int)dRise)
                dHan[iNum] = (1 - cos(M_PI * ((double)iSize - (double)iNum) / dRise)) / (double)iOverlapFactor;
            else
                dHan[iNum] = 2 / (double)iOverlapFactor;
        }
        if(dAttRt == nil){
            dAttRt = (malloc(sizeof(double) * iHlf));
        }
        for(iNum = 0;iNum < iHlf;iNum ++){
            dAttRt[iNum] = 1;
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
            if(iOverlapFactor == 2)
                sAnglePoint = iSize;
            else
                sAnglePoint = (iOverlapFactor - 1) * iHlf;
            sStreamPoint = (iOverlapFactor - 1) * iProc;
            iEnd = iProcBytes;
        }
        else{
            if(iOverlapFactor == 2)
                sAnglePoint = ((iFnum - 1) % iOverlapFactor) * iSize;
            else
                sAnglePoint = ((iFnum - 1) % iOverlapFactor) * iHlf;
            sStreamPoint = ((iFnum - 1) % iOverlapFactor) * iProc;
            iEnd = iProcBytes;
        }
        for(iCount = 0;iCount < iEnd;iCount += 4){
            iNumero = iOff + iCount;
            SInt16 sLoc = [self inputData:iNumero asByte:TRUE];
            SInt16 sMark = sAnglePoint + iCount / 2 + 1;
            if(sVersion == 1)
                sLoc = [self convertDir:sLoc];
            if(sLoc > 253){
                sAngr[sMark] = sAngl[sMark] = sLoc;
            }
            else{
                if(iRoll == 18)
                    sAngr[sMark] = sDirArry[sLoc][iAzim][iElev];
                else{
                    dRoll = ((double)iRoll - 18) * M_PI / 36;
                    sAngr[sMark] = [self rollSector:sDirArry[sLoc][iAzim][iElev] byRoll:dRoll];
                }
                sAngl[sMark] = [self opposite:sAngr[sMark]];
            }
            
            sLoc = [self inputData:iNumero + 1 asByte:TRUE];
            sMark -= 1;
            if(sVersion == 1)
                sLoc = [self convertDir:sLoc];
            if(sLoc > 253){
                sAngr[sMark] = sAngl[sMark] = sLoc;
            }
            else{
                if(iRoll == 18)
                    sAngr[sMark] = sDirArry[sLoc][iAzim][iElev];
                else{
                    dRoll = ((double)iRoll - 18) * M_PI / 36;
                    sAngr[sMark] = [self rollSector:sDirArry[sLoc][iAzim][iElev] byRoll:dRoll];
                }
                sAngl[sMark] = [self opposite:sAngr[sMark]];
            }

            nSin = [self inputData:iNumero + 2 asByte:FALSE];
            nSin += [self inputData:iNumero + 3 asByte:FALSE] * 256;
            nAdr = &nSin;
            
            if(iEnd == iSize * 4){
                [sStream replaceBytesInRange:NSMakeRange(iCount / 2,2) withBytes:nAdr length:2];  // PCM data
            }
            else{
                [sStream replaceBytesInRange:NSMakeRange((sStreamPoint + iCount / 4) * 2,2) withBytes:nAdr length:2];        // PCM data
            }
        }
        
        iOff += iEnd;
        for(iNum = 0;iNum < iSize;iNum ++){
            if(numOffset == 44)
                sRef = iNum;
            else
                sRef = sStreamPoint + iProc + iNum;
            if(sRef >= iSize)
                sRef -= iSize;
            [sStream getBytes:&nSin range:NSMakeRange(sRef * 2,2)];
            realRight[iNum] = nSin;
            imageRight[iNum] = 0;
        }
        
        dWAtt = dAtt * 2;
        [trans fastFt:realRight:imageRight:NO];
        
        for(sAnglRef = 0;sAnglRef < iHlf;sAnglRef ++){
            sRef = iSize - sAnglRef;
            if(iOverlapFactor == 2){
                iNum = (iSize * (iFnum % iOverlapFactor)) + sAnglRef;
            }
            else{
                iNum = (iHlf * (iFnum % iOverlapFactor) + sAnglRef);
                if(iNum >= iHlf * iOverlapFactor)
                    iNum -= iHlf * iOverlapFactor;
            }
            SInt32 iFreq = (sAnglRef / iRatio);
            iNumero = 512 - iFreq;
            if(sAngl[iNum] < 0 || iFreq == 0 || sAngl[iNum] >= 254){
                dSpL = dSpR = realRight[sAnglRef];
                dSpImageL = dSpImageR = realRight[sRef];
                if(bCardioid == 2 && sAngl[iNum] > 254){
                    dSpL /= 4;
                    dSpR /= 4;
                    dSpImageL /= 4;
                    dSpImageR /= 4;
                }
                else if(bCardioid == 1 && sAngl[iNum] > 254){
                    dSpL /= 2;
                    dSpR /= 2;
                    dSpImageL /= 2;
                    dSpImageR /= 2;
                }
                dPhaseL = dPhaseR = imageRight[sAnglRef];
                dPhaseImageL = dPhaseImageR = imageRight[sRef];
            }
            else{
                //              Construct Temporal HRTF by using HRTF database (left channel)
                iPos = 512 * sAngl[iNum] + iFreq;
                iPosImage = 512 * sAngl[iNum] + iNumero;
                if(iPosImage >= iDBSize)
                    iPosImage -= iDBSize;
                else if(iPosImage < 0)
                    iPosImage += iDBSize;
                if(iPos >= iDBSize)
                    iPos -= iDBSize;
                else if(iPos < 0)
                    iPos += iDBSize;
                if(sVersion >= 3){
                    iPosSec = 512 * sAngl[iHlf + iNum];
                    iPosSecImage = iPosSec + iNumero;
                    iPosSec += iFreq;
                    if(iPosSecImage >= iDBSize)
                        iPosSecImage -= iDBSize;
                    else if(iPosSecImage < 0)
                        iPosSecImage += iDBSize;
                    if(iPosSec >= iDBSize)
                        iPosSec -= iDBSize;
                    else if(iPosSec < 0)
                        iPosSec += iDBSize;
                
                //              Superimpose Temporal HRTF on spectrum of reference signal (left channel)
                    dSpL = realRight[sAnglRef] * ((double)sHrtf[iPos] + (double)sHrtf[iPosSec]) / dWAtt;
                    dSpImageL = realRight[sRef] * ((double)sHrtf[iPosImage] + (double)sHrtf[iPosSecImage]) / dWAtt;
                    dPh = ((double)sPhase[iPos] + (double)sPhase[iPosSec]) / 20000.0;
                    if(abs(sPhase[iPos] - sPhase[iPosSec]) > 31415){
                        if(dPh < 0)
                            dPh += M_PI;
                        else
                            dPh -= M_PI;
                    }
                    dPhaseL = imageRight[sAnglRef] + dPh;
                    dPh = ((double)sPhase[iPosImage] + (double)sPhase[iPosSecImage]) / 20000.0;
                    if(abs(sPhase[iPosImage] - sPhase[iPosSecImage]) > 31415){
                        if(dPh < 0)
                            dPh += M_PI;
                        else
                            dPh -= M_PI;
                    }
                    dPhaseImageL = imageRight[sRef] + dPh;
                }
                else{
                    dSpL = realRight[sAnglRef] * (double)sHrtf[iPos] / dAtt;
                    dSpImageL = realRight[sRef] * (double)sHrtf[iPosImage] / dAtt;
                    dPhaseL = imageRight[sAnglRef] + (double)sPhase[iPos] / 10000.0;
                    dPhaseImageL = imageRight[sRef] + (double)sPhase[iPosImage] / 10000.0;
                }
                
                //              Construct Temporal HRTF by using HRTF database (right channel)
                iPos = 512 * sAngr[iNum] + iFreq;
                iPosImage = 512 * sAngr[iNum] + iNumero;
                if(iPosImage >= iDBSize)
                    iPosImage -= iDBSize;
                else if(iPosImage < 0)
                    iPosImage += iDBSize;
                if(iPos >= iDBSize)
                    iPos -= iDBSize;
                else if(iPos < 0)
                    iPos += iDBSize;
                if(sVersion >= 3){
                    iPosSec = 512 * sAngr[iHlf + iNum];
                    iPosSecImage = iPosSec + iNumero;
                    iPosSec += iFreq;
                    if(iPosSecImage >= iDBSize)
                        iPosSecImage -= iDBSize;
                    else if(iPosSecImage < 0)
                        iPosSecImage += iDBSize;
                    if(iPosSec >= iDBSize)
                        iPosSec -= iDBSize;
                    else if(iPosSec < 0)
                        iPosSec += iDBSize;
                
                //              Superimpose Temporal HRTF on spectrum of reference signal (right channel)
                    dSpR = realRight[sAnglRef] * ((double)sHrtf[iPos] + (double)sHrtf[iPosSec]) / dWAtt;
                    dSpImageR = realRight[sRef] * ((double)sHrtf[iPosImage] + (double)sHrtf[iPosSecImage]) / dWAtt;
                    dPh = ((double)sPhase[iPos] + (double)sPhase[iPosSec]) / 20000.0;
                    if(abs(sPhase[iPos] - sPhase[iPosSec]) > 31415){
                        if(dPh < 0)
                            dPh += M_PI;
                        else
                            dPh -= M_PI;
                    }
                    dPhaseR = imageRight[sAnglRef] + dPh;
                    dPh = ((double)sPhase[iPosImage] + (double)sPhase[iPosSecImage]) / 20000.0;
                    if(abs(sPhase[iPosImage] - sPhase[iPosSecImage]) > 31415){
                        if(dPh < 0)
                            dPh += M_PI;
                        else
                            dPh -= M_PI;
                    }
                    dPhaseImageR = imageRight[sRef] + dPh;
                    
                }
                else{
                    dSpR = realRight[sAnglRef] * (double)sHrtf[iPos] / dAtt;
                    dSpImageR = realRight[sRef] * (double)sHrtf[iPosImage] / dAtt;
                    dPhaseR = imageRight[sAnglRef] + (double)sPhase[iPos] / 10000.0;
                    dPhaseImageR = imageRight[sRef] + (double)sPhase[iPosImage] / 10000.0;
                }
                if(bCardioid == 2){
                    sPos = sAngl[iNum] * sizeof(double);
                    [sharpAtt getBytes: &dV range: NSMakeRange(sPos,sizeof(double))];
                    dAttRt[sAnglRef] += dV;
                    dAttRt[sAnglRef] /= 2;
                    dSpL *= dAttRt[sAnglRef];
                    dSpImageL *= dAttRt[sAnglRef];
                    dSpR *= dAttRt[sAnglRef];
                    dSpImageR *= dAttRt[sAnglRef];
                }
                else if(bCardioid == 1){
                    sPos = sAngl[iNum] * sizeof(double);
                    [softAtt getBytes: &dV range: NSMakeRange(sPos,sizeof(double))];
                    dAttRt[sAnglRef] += dV;
                    dAttRt[sAnglRef] /= 2;
                    dSpL *= dAttRt[sAnglRef];
                    dSpImageL *= dAttRt[sAnglRef];
                    dSpR *= dAttRt[sAnglRef];
                    dSpImageR *= dAttRt[sAnglRef];
                }
            }
            realLeft[sAnglRef] = dSpL * cos(dPhaseL);
            realRight[sAnglRef] = dSpR * cos(dPhaseR);
            imageLeft[sAnglRef] = dSpL * sin(dPhaseL);
            imageRight[sAnglRef] = dSpR * sin(dPhaseR);
            realLeft[sRef] = dSpImageL * cos(dPhaseImageL);
            realRight[sRef] = dSpImageR * cos(dPhaseImageR);
            imageLeft[sRef] = dSpImageL * sin(dPhaseImageL);
            imageRight[sRef] = dSpImageR * sin(dPhaseImageR);
        }
        
        dSpR = realRight[iHlf];
        dPhaseR = imageRight[iHlf];
        realLeft[iHlf] = realRight[iHlf] = dSpR * cos(dPhaseR);
        imageLeft[iHlf] = imageRight[iHlf] = dSpR * sin(dPhaseR);
        
        [trans fastFt:realLeft:imageLeft:YES];              // Inverse FFT (left channel)
        [trans fastFt:realRight:imageRight:YES];            // Inverse FFT (right channel)
        
        //      Overlap and add process
        for(iNum = 0;iNum < iSize;iNum ++){
            realLeft[iNum] *= dHan[iNum];
            realRight[iNum] *= dHan[iNum];
            iNumero = iNum * 2;
            
            if(numBytesWritten == 0){
                nSin = realLeft[iNum];
                nAdr = &nSin;
                [ResultLeft replaceBytesInRange:NSMakeRange(iNumero,2) withBytes:nAdr length:2];

                nSin = realRight[iNum];
                nAdr = &nSin;
                [ResultRight replaceBytesInRange:NSMakeRange(iNumero,2) withBytes:nAdr length:2];
            }
            else{
                [ResultLeft getBytes:&nSin range:NSMakeRange(iNumero,2)];
                iPos = (SInt32)nSin + (SInt32)realLeft[iNum];
                if(iPos > 32767){
                    iPos = 32767;
                }
                else if(iPos < -32768){
                    iPos = -32768;
                }
                nSin = (SInt16)iPos;
                nAdr = &nSin;
                [ResultLeft replaceBytesInRange:NSMakeRange(iNumero,2) withBytes:nAdr length:2];
                
                [ResultRight getBytes:&nSin range:NSMakeRange(iNumero,2)];
                iPos = (SInt32)nSin + (SInt32)realRight[iNum];
                if(iPos > 32767){
                    iPos = 32767;
                }
                else if(iPos < -32768){
                    iPos = -32768;
                }
                nSin = (SInt16)iPos;
                nAdr = &nSin;
                [ResultRight replaceBytesInRange:NSMakeRange(iNumero,2) withBytes:nAdr length:2];
            }
        }
        
        iMarg = 44;
        if(!isLoaded)
            iMarg += iSize * 4;
        nBytesReady = nBytesRead - iMarg;
        for(iCount = 0;iCount < iSize;iCount ++){
            iNumero = iCount * 2;
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
                [ResultLeft getBytes:&nSin range:NSMakeRange(iNumero,2)];
                *output = nSin;
                output++;
                [ResultRight getBytes:&nSin range:NSMakeRange(iNumero,2)];
                *output = nSin;
                output++;
                iBufSize += 4;
                numBytesWritten += 4;
                lBytesDone += 4;
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
                [ResultLeft getBytes:&nSin range:NSMakeRange((iCount + iProc) * 2,2)];
                nAdr = &nSin;
                [ResultLeft replaceBytesInRange:NSMakeRange(iNumero,2) withBytes:nAdr length:2];

                [ResultRight getBytes:&nSin range:NSMakeRange((iCount + iProc) * 2,2)];
                nAdr = &nSin;
                [ResultRight replaceBytesInRange:NSMakeRange(iNumero,2) withBytes:nAdr length:2];
            }
            else{
                nSin = 0;
                nAdr = &nSin;
                [ResultLeft replaceBytesInRange:NSMakeRange(iNumero,2) withBytes:nAdr length:2];
                [ResultRight replaceBytesInRange:NSMakeRange(iNumero,2) withBytes:nAdr length:2];
            }
        }
        if(isSequel && lBytesDone > 0 && !isProceed && isLoaded){
            isProceed = YES;
            
            [self play];
        }
        if(lBytesDone >= lChunkSize){
            if(isSequel){
                lBytesDone = 0;
                isProceed = NO;
            }
        }
        
        if(numBytesWritten / numIntvl != sSec){
            sSec = numBytesWritten / numIntvl;
            
            NSNotification* notification;
            notification = [NSNotification notificationWithName:@"getNewImage" object:self];
            NSNotificationCenter* center;
            center = [NSNotificationCenter defaultCenter];
            
            // Post notification
            [center postNotification:notification];
        }
        NSNotification* notification;
        notification = [NSNotification notificationWithName:@"reproductionProgress" object:self];
        NSNotificationCenter* center;
        center = [NSNotificationCenter defaultCenter];
        
        // Post notification
        [center postNotification:notification];
        
    }
    if(isPlaying){
        inBuffer->mAudioDataByteSize = iBufSize;
        err = AudioQueueEnqueueBuffer(inAQ,inBuffer,0,NULL);
        if(err){
            [self setIsPlaying:NO];
            [self stop:YES];
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

-(void) initCoord:(int)iSector{
    CC3Vector coord,reverse;
    double nUnitLong;
    double nUnitHori;
    double nHoriAngl;
    double nUnitLat = M_PI / 12;
    
    if(iSector >= 127)
        return;
    
    if(iSector == 0){
        coord.x = coord.z = 0;
        coord.y = 1;
    }
    else if(iSector < 9){
        nUnitLong = M_PI / 4.0;
        nUnitHori = cos(nUnitLat * 5);
        
        coord.y = sin(nUnitLat * 5);
        nHoriAngl = nUnitLong * ((double)iSector - 1) - M_PI;
        
        coord.x = nUnitHori * sin(nHoriAngl);
        coord.z = nUnitHori * cos(nHoriAngl);
    }
    else if(iSector < 25){
        nUnitLong = M_PI / 8;
        nUnitHori = cos(nUnitLat * 4);
        
        coord.y = sin(nUnitLat * 4);
        nHoriAngl = nUnitLong * ((double)iSector - 9) - M_PI;
        
        coord.x = nUnitHori * sin(nHoriAngl);
        coord.z = nUnitHori * cos(nHoriAngl);
    }
    else if(iSector < 49){
        nUnitLong = M_PI / 12;
        nUnitHori = cos(nUnitLat * 3);
        
        coord.y = sin(nUnitLat * 3);
        nHoriAngl = nUnitLong * ((double)iSector - 25) - M_PI;
        
        coord.x = nUnitHori * sin(nHoriAngl);
        coord.z = nUnitHori * cos(nHoriAngl);
    }
    else if(iSector < 79){
        nUnitLong = M_PI / 15;
        nUnitHori = cos(nUnitLat * 2);
        
        coord.y = sin(nUnitLat * 2);
        nHoriAngl = nUnitLong * ((double)iSector - 49) - M_PI;
        
        coord.x = nUnitHori * sin(nHoriAngl);
        coord.z = nUnitHori * cos(nHoriAngl);
    }
    else if(iSector < 111){
        nUnitLong = M_PI / 16;
        nUnitHori = cos(nUnitLat);
        
        coord.y = sin(nUnitLat);
        nHoriAngl = nUnitLong * ((double)iSector - 79) - M_PI;
        
        coord.x = nUnitHori * sin(nHoriAngl);
        coord.z = nUnitHori * cos(nHoriAngl);
    }
    else{
        nUnitLong = M_PI / 16;
        nUnitHori = 1.0;
        coord.y = 0;
        
        nHoriAngl = nUnitLong * ((double)iSector - 111) - M_PI;
        
        coord.x = nUnitHori * sin(nHoriAngl);
        coord.z = nUnitHori * cos(nHoriAngl);
    }
    vecAngl[iSector] = coord;
    reverse.x = -coord.x;
    reverse.y = -coord.y;
    reverse.z = -coord.z;
    vecAngl[253 - iSector] = reverse;
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

-(SInt16)rollSector:(SInt16)iSector byRoll:(double)nRoll{
    int iNewSect;
    CC3Vector vecNew;
    
    vecNew.x = -(cos(nRoll) * vecAngl[iSector].x - sin(nRoll) * vecAngl[iSector].y);
    vecNew.y = sin(nRoll) * vecAngl[iSector].x + cos(nRoll) * vecAngl[iSector].y;
    vecNew.z = -vecAngl[iSector].z;
    iNewSect = [self calcSector:vecNew];
    
    return(iNewSect);
}

-(SInt16) modifySector:(int)iSector withPan:(double) nPan withTilt:(double)nTilt{
    int iNewSect;
    CC3Vector vecUp,vecNew;
    CC3Vector vecRight;
    
    if(iSector > 253)
        return iSector;
    
    vecUp = CC3VectorMake(0,1,0);
    vecRight = CC3VectorMake(1,0,0);
    
    vecRight = [self vecRotate:vecRight aroundVec:vecUp byRad:nPan];
    vecNew = [self vecRotate:vecAngl[iSector] aroundVec:vecUp byRad:-nPan];
    vecNew = [self vecRotate:vecNew aroundVec:vecRight byRad:-nTilt];
    iNewSect = [self calcSector:vecNew];
    
    return(iNewSect);
}

-(int) calcSector:(CC3Vector)coor{
    int iSector;
    double nHoriAngl;
    
    if(coor.y >= sin(M_PI * 11 / 24))
        return 0;
    else if(coor.y <= -sin(M_PI * 11 / 24))
        return 253;
    else
        nHoriAngl = atan2(coor.x,coor.z);
    
    if(fabs(coor.y) >= sin(M_PI * 3 / 8)){
        if(nHoriAngl < 0)
            nHoriAngl += dWPi;
        iSector = (int)(1 + nHoriAngl / (M_PI / 4));
    }
    else if(coor.y <= -sin(M_PI * 3 / 8))
        iSector = (int)(248.0 - nHoriAngl / (M_PI / 4));
    else if(coor.y >= sin(M_PI * 7 / 24)){
        if(nHoriAngl < 0)
            nHoriAngl += dWPi;
        iSector = (int)(9.0 + nHoriAngl / (M_PI / 8));
    }
    else if(coor.y <= -sin(M_PI * 7 / 24))
        iSector = (int)(236.0 - nHoriAngl / (M_PI / 8));
    else if(coor.y >= sin(M_PI * 5 / 24)){
        if(nHoriAngl < 0)
            nHoriAngl += dWPi;
        iSector = (int)(25 + nHoriAngl / (M_PI / 12));
    }
    else if(coor.y <= -sin(M_PI * 5 / 24))
        iSector = (int)(216.0 - nHoriAngl / (M_PI / 12.0));
    else if(coor.y >= sin(M_PI / 8)){
        if(nHoriAngl < 0)
            nHoriAngl += dWPi;
        iSector = (int)(49.0 + nHoriAngl / (M_PI / 15.0));
    }
    else if(coor.y <= -sin(M_PI / 8))
        iSector = (int)(189.0 - nHoriAngl / (M_PI / 15.0));
    else if(coor.y >= sin(M_PI / 24)){
        if(nHoriAngl < 0)
            nHoriAngl += dWPi;
        iSector = (int)(79.0 + nHoriAngl / (M_PI / 16.0));
    }
    else if(coor.y <= -sin(M_PI / 24))
        iSector = (int)(158.0 - nHoriAngl / (M_PI / 16.0));
    else if(nHoriAngl < 0)
        iSector = (int)(127.0 - nHoriAngl / (M_PI / 16.0));
    else
        iSector = (int)(111.0 + nHoriAngl / (M_PI / 16.0));
    
    return iSector;
}

/****************************************************************
 * 				Flip direction (right to left)					*
 ****************************************************************/

-(SInt16) opposite:(SInt16)right{
    if(right == 0 || right >= 253)
        return(right);
    else if(right < 9){
        if(right == 1)
            return(right);
        else
            return(10 - right);
    }
    else if(right < 25){
        if(right == 9)
            return(right);
        else
            return(34 - right);
    }
    else if(right < 49){
        if(right == 25)
            return(right);
        else
            return(74 - right);
    }
    else if(right < 79){
        if(right == 49)
            return(right);
        else
            return(128 - right);
    }
    else if(right < 111){
        if(right == 79)
            return(right);
        else
            return(190 - right);
    }
    else if(right < 127){
        if(right == 111)
            return(right);
        else
            return(15 + right);
    }
    else if(right < 143){
        if(right == 142)
            return(right);
        else
            return(right - 15);
    }
    else if(right < 175){
        if(right == 174)
            return(right);
        else
            return(316 - right);
    }
    else if(right < 205){
        if(right == 204)
            return(right);
        else
            return(378 - right);
    }
    else if(right < 229){
        if(right == 228)
            return(right);
        else
            return(432 - right);
    }
    else if(right < 245){
        if(right == 244)
            return(right);
        else
            return(472 - right);
    }
    else{
        if(right == 252)
            return(right);
        else
            return(496 - right);
    }
}

-(void)finalize{
    free(sHrtf);
    free(sPhase);
    
    free(dHan);
    free(sAngl);
    free(sAngr);
    free(dAttRt);
    
    dHan = nil;
    sAngl = nil;
    sAngr = nil;
    dAttRt = nil;

    if(sopaQueueObject)
        AudioQueueDispose(sopaQueueObject,YES);
}

@end