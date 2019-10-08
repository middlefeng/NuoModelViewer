//
//  NuoColorPicker.m
//  ModelViewer
//
//  Created by Dong on 10/8/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "NuoColorPicker.h"


@implementation NuoColorPicker

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.bezelStyle = NSBezelStyleRoundRect;
        self.title = @"";
        [self setTarget:self];
        [self setAction:@selector(colorPicker:)];
    }
    
    return self;
}


- (void)colorPicker:(id)sender
{
    NSColorPanel* panel = [NSColorPanel sharedColorPanel];
    
    [panel display];
    [panel orderFrontRegardless];
}


@end
