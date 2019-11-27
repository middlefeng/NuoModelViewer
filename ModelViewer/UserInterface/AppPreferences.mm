//
//  AppPreferences.m
//  ModelViewer
//
//  Created by Dong on 11/27/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "AppPreferences.h"



@implementation AppPreferences


- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.title = @"Preferences";
        
        [self setShowsResizeIndicator:NO];
        [self setStyleMask:NSWindowStyleMaskTitled   |
                           NSWindowStyleMaskClosable];
        
        [self setReleasedWhenClosed: NO];
        [self setContentSize:CGSizeMake(200, 150)];
    }
    
    return self;
}


- (void)locateRelativeTo:(NSWindow*)window
{
    CGRect frame = window.frame;
    frame.origin.x += 100;
    frame.origin.y += window.frame.size.height - self.frame.size.height - 100;
    
    [self setFrameOrigin:frame.origin];
    
}



@end
