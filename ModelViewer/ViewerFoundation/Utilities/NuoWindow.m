//
//  NuoWindow.m
//  ModelViewer
//
//  Created by middleware on 9/7/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoWindow.h"


@implementation NuoWindow


- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        [self setMovable:YES];
        [self setShowsResizeIndicator:YES];
        [self setStyleMask:NSWindowStyleMaskTitled   |
                           NSWindowStyleMaskClosable |
                           NSWindowStyleMaskMiniaturizable |
                           NSWindowStyleMaskResizable];
    }
    
    return self;
}


@end
