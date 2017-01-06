//
//  ModelOperationPanel.m
//  ModelViewer
//
//  Created by middleware on 1/5/17
//  Copyright © 2016 middleware. All rights reserved.
//

#import "LightOperationPanel.h"
#import "ModelOptionUpdate.h"





@implementation LightOperationPanel
{
    NSTextField* _lightDensityLabel;
    NSSlider* _lightDensitySlider;
    
    NSTextField* _lightSpacularLabel;
    NSSlider* _lightSpacularSlider;
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
        [_lightDensityLabel setAlignment:NSTextAlignmentRight];
        [self addSubview:_lightDensityLabel];
        
        _lightDensitySlider = [[NSSlider alloc] init];
        [_lightDensitySlider setMaxValue:3.0f];
        [_lightDensitySlider setMinValue:0.0f];
        [_lightDensitySlider setFloatValue:1.0f];
        [_lightDensitySlider setTarget:self];
        [_lightDensitySlider setAction:@selector(lightDensityChange:)];
        [self addSubview:_lightDensitySlider];
        
        _lightSpacularLabel = [[NSTextField alloc] init];
        [_lightSpacularLabel setEditable:NO];
        [_lightSpacularLabel setSelectable:NO];
        [_lightSpacularLabel setBordered:NO];
        [_lightSpacularLabel setBackgroundColor:[NSColor colorWithWhite:0.0 alpha:0.0]];
        [_lightSpacularLabel setStringValue:@"Spacular:"];
        [_lightSpacularLabel setAlignment:NSTextAlignmentRight];
        [self addSubview:_lightSpacularLabel];
        
        _lightSpacularSlider = [[NSSlider alloc] init];
        [_lightSpacularSlider setMaxValue:3.0f];
        [_lightSpacularSlider setMinValue:0.0f];
        [_lightSpacularSlider setFloatValue:1.0f];
        [_lightSpacularSlider setTarget:self];
        [_lightSpacularSlider setAction:@selector(lightSpacularChange:)];
        [self addSubview:_lightSpacularSlider];
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
    
    float labelWidth = 60;
    float labelSpace = 2;
    float entryHeight = 18;
    float lineSpace = 6;
    
    CGRect labelFrame;
    labelFrame.size = CGSizeMake(labelWidth, entryHeight);
    labelFrame.origin = CGPointMake(0, entryHeight + lineSpace + 5);
    
    [_lightDensityLabel setFrame:labelFrame];
    
    CGRect sliderFrame;
    sliderFrame.size = CGSizeMake(viewSize.width - labelWidth - labelSpace, entryHeight);
    sliderFrame.origin = CGPointMake(labelWidth + labelSpace, entryHeight + lineSpace + 5);
    [_lightDensitySlider setFrame:sliderFrame];
    
    labelFrame.origin.y -= entryHeight + lineSpace;
    sliderFrame.origin.y -= entryHeight + lineSpace;
    
    [_lightSpacularLabel setFrame:labelFrame];
    [_lightSpacularSlider setFrame:sliderFrame];
}



- (float)lightDensity
{
    return [_lightDensitySlider floatValue];
}


- (void)setLightDensity:(float)lightDensity
{
    [_lightDensitySlider setFloatValue:lightDensity];
}


- (void)lightDensityChange:(id)sender
{
    [_optionUpdateDelegate lightOptionUpdate:self];
}


- (float)lightSpacular
{
    return [_lightSpacularSlider floatValue];
}


- (void)setLightSpacular:(float)lightSpacular
{
    [_lightSpacularSlider setFloatValue:lightSpacular];
}


- (void)lightSpacularChange:(id)sender
{
    [_optionUpdateDelegate lightOptionUpdate:self];
}


@end
