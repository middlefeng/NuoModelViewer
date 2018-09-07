//
//  NuoInspectWindow.m
//  ModelViewer
//
//  Created by middleware on 9/7/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoInspectWindow.h"
#import "NuoMetalView.h"



@interface NuoInspectWindow() < NSWindowDelegate >

@end



@implementation NuoInspectWindow
{
    NuoMetalView* _inspectView;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    self = [super init];
    
    if (self)
    {
        CGRect rect = self.contentView.bounds;
        
        _inspectView = [[NuoMetalView alloc] initWithFrame:rect device:device];
        
        [self.contentView addSubview:_inspectView];
        [self setDelegate:self];
    }
    
    return self;
}


- (void)windowDidResize:(NSNotification *)notification
{
    CGRect frame = self.contentView.bounds;
    
    _inspectView.frame = frame;
}


@end
