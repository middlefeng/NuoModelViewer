//
//  ModelOperationPanel.m
//  ModelViewer
//
//  Created by middleware on 9/15/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "LightOperationPanel.h"
#import "ModelOptionUpdate.h"





@implementation LightOperationPanel
{
    NSTextField* _lightDensityLabel;
    NSSlider* _lightDensitySlider;
}


- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    
    if (self)
    {
        [self setWantsLayer:YES];
        
        _lightDensityLabel = [[NSTextField alloc] init];
        [_lightDensityLabel setEditable:NO];
        [_lightDensityLabel setSelectable:NO];
        [_lightDensityLabel setBordered:NO];
        [_lightDensityLabel setBackgroundColor:[NSColor colorWithWhite:0.0 alpha:0.0]];
        [_lightDensityLabel setStringValue:@"Density:"];
        [self addSubview:_lightDensityLabel];
        
        _lightDensitySlider = [[NSSlider alloc] init];
        [_lightDensitySlider setMaxValue:3.0f];
        [_lightDensitySlider setMinValue:0.0f];
        [_lightDensitySlider setFloatValue:1.0f];
        [_lightDensitySlider setTarget:self];
        [_lightDensitySlider setAction:@selector(lightDensityChange:)];
        [self addSubview:_lightDensitySlider];
    }
    
    return self;
}


- (CALayer*)makeBackingLayer
{
    return [CALayer new];
}


- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
    [self updateControlsLayout];
}


- (void)updateControlsLayout
{
    CGSize viewSize = [self bounds].size;
    
    float labelWidth = 55;
    float labelSpace = 0;
    float entryHeight = 18;
    
    CGRect labelFrame;
    labelFrame.size = CGSizeMake(labelWidth, entryHeight);
    labelFrame.origin = CGPointMake(0, 0);
    
    [_lightDensityLabel setFrame:labelFrame];
    
    CGRect sliderFrame;
    sliderFrame.size = CGSizeMake(viewSize.width - labelWidth - labelSpace, entryHeight);
    sliderFrame.origin = CGPointMake(labelWidth + labelSpace, 0);
    [_lightDensitySlider setFrame:sliderFrame];
}



- (float)lightDensity
{
    return [_lightDensitySlider floatValue];
}


- (void)lightDensityChange:(id)sender
{
    [_optionUpdateDelegate lightOptionUpdate:self];
}


@end
