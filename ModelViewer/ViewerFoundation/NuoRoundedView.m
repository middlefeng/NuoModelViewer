//
//  NuoRoundedView.m
//  ModelViewer
//
//  Created by middleware on 9/14/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "NuoRoundedView.h"





@implementation NuoRoundedView


- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        [self setWantsLayer:YES];
        
        [self.layer setCornerRadius:4.0];
        [self.layer setMasksToBounds:YES];
        [self.layer setBorderWidth:0.5];
        [self.layer setBorderColor:[NSColor colorWithWhite:0.2 alpha:0.5].CGColor];
    }
    
    return self;
}


- (void)layout
{
    [super layout];
    [self.layer setBackgroundColor:_panelBackground.CGColor];
}


- (void)setPanelBackground:(NSColor*)panelBackground
{
    _panelBackground = panelBackground;
    [self.layer setBackgroundColor:_panelBackground.CGColor];
}


- (CALayer*)makeBackingLayer
{
    return [CALayer new];
}




@end
