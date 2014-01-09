//
//  OpenGLView.h
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

#import <UIKit/UIKit.h>
#import "sopaObject.h"
#import "scroller.h"
#import <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#import <CoreMotion/CoreMotion.h>

@interface OpenGLView : UIView{
    CAEAGLLayer* _eaglLayer;
    EAGLContext* _context;
    sopaObject *player;
    scroller *scrollView;
    
    GLuint _colorRenderBuffer;    
    GLuint _depthRenderBuffer;    
    GLuint _floorTexture;
    GLuint _positionSlot;
    GLuint _colorSlot;
    GLuint _projectionUniform;
    GLuint _modelViewUniform;
    GLuint _texCoordSlot;
    GLuint _textureUniform;
    CMMotionManager *_manager;
}

@property (strong)NSString *urlStr;
@property (strong)NSURLConnection *imageConn;
@property BOOL is3d;
@property BOOL isRotated;
@property BOOL isManagerOn;
@property BOOL isLoaded;
@property UIImage *myImage;
@property UIDeviceOrientation myOrientation;
@property UInt32 nBytesRead;
@property UInt32 nBytesWritten;
@property SInt16 sFontSize;
@property long expectedLength;
@property double dRoll;

-(void)setupDatabase;
-(void)makeWorld;
-(void)activateManager;
-(BOOL)finalizeView;

@end
