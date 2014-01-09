//
//  sopaObject.h
//  mySopa
//
/*
 Copyright (c) 2013, AIST
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 */
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "fft.h"
#import "CC3GLMatrix.h"

@interface sopaObject : NSObject <UIAlertViewDelegate>{
    AudioQueueRef sopaQueueObject;
}

@property UInt32 ExtBufSize;
@property UInt32 numBytesWritten;
@property UInt32 numOffset;
@property UInt32 nBytesRead;
@property UInt32 nBytesReady;
@property BOOL nTrial;
@property BOOL isLoaded;
@property BOOL isPrepared;
@property BOOL isPlaying;
@property BOOL isCanceled;
@property BOOL isFromDir;
@property SInt16 iSize;
@property SInt16 iOverlapFactor;
@property SInt16 iStage;
@property UInt16 iDirNum;
@property (strong)NSURLConnection *myConn;
@property (strong)NSURLConnection *databaseConn;
@property (strong)NSString *urlStr;
@property UInt32 numSampleRate;
@property UInt32 numPacketsToRead;
@property long long expectedLength;
@property NSMutableData *dirID;
@property NSMutableData *dilID;

-(void)play;
-(void)loadDatabase;
-(void)loadDatabaseFromDir;
-(void)cancelLoading;
-(void)prepareSopaQueue;
-(void)stop:(BOOL)shouldStopImmediate;

-(SInt16)inputData:(UInt32)nNum asByte:(BOOL)isByte;
-(SInt16)convertDir:(SInt16)dir;

-(void)_processor:(AudioQueueRef)inAQ queueBuffer:(AudioQueueBufferRef)inBuffer;

@end
