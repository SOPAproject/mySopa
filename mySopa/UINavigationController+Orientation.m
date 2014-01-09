//
//  UINavigationController+Orientation.m
//  mySopa
//
//  Created by Kaoru Ashihara on 13/04/03.
//  Copyright (c) 2013, AIST. All rights reserved.
//

#import "UINavigationController+Orientation.h"

@implementation UINavigationController (Orientation)

- (BOOL)shouldAutorotate
{
    return [self.visibleViewController shouldAutorotate];
}

- (NSUInteger)supportedInterfaceOrientations
{
    if (![[self.viewControllers lastObject] isKindOfClass:NSClassFromString(@"ViewController")])
    {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
    else
    {
        return [self.topViewController supportedInterfaceOrientations];
    }
}

@end
