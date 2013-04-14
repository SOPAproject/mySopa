//
//  scroller.m
//  mySopa
//
//  Created by Kaoru Ashihara on 13/04/03.
//  Copyright (c) 2013, AIST. All rights reserved.
//

#import "scroller.h"

@implementation scroller

/*
 - (id)initWithFrame:(CGRect)frame
 {
 self = [super initWithFrame:frame];
 if (self) {
 // Initialization code
 }
 return self;
 }   */

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	if (!self.dragging) {
		[self.nextResponder touchesBegan: touches withEvent:event];
	}
	[super touchesBegan: touches withEvent: event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	if (!self.dragging) {
		[self.nextResponder touchesEnded: touches withEvent:event];
	}
	[super touchesEnded: touches withEvent: event];
	
}

@end