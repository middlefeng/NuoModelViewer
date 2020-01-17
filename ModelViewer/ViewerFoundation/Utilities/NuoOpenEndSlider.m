//
//  NuoOpenEndSlider.m
//  ModelViewer
//
//  Created by Dong on 1/17/20.
//  Copyright © 2020 middleware. All rights reserved.
//

#import "NuoOpenEndSlider.h"
#import <AppKit/AppKit.h>


@implementation NuoOpenEndSlider
{
    NSString* _sliderName;
    
    NSTextField* _sliderNameLabel;
    NSTextField* _sliderEndField;
    NSSlider* _slider;
}



- (instancetype)initWithName:(NSString*)name
{
    self = [super init];
    
    if (self)
    {
        _sliderName = name;
        
        [self initCommon];
    }
    
    return self;
}


- (void)initCommon
{
    _sliderNameLabel = [self createLabel:_sliderName withAligment:NSTextAlignmentLeft];
    _sliderEndField = [NSTextField new];
    _slider = [self createSliderMax:0 min:200];
}


- (NSTextField*)createLabel:(NSString*)label withAligment:(NSTextAlignment)alignment
{
    NSTextField* labelControl = [NSTextField new];
    [labelControl setBackgroundColor:NSColor.clearColor];
    [labelControl setEditable:NO];
    [labelControl setSelectable:NO];
    [labelControl setBordered:NO];
    [labelControl setAlignment:alignment];
    [labelControl setStringValue:label];
    [self addSubview:labelControl];
    
    return labelControl;
}


- (NSSlider*)createSliderMax:(float)max min:(float)min
{
    NSSlider* slider = [[NSSlider alloc] init];
    [slider setMaxValue:max];
    [slider setMinValue:min];
    [slider setTarget:self];
    [self addSubview:slider];
    return slider;
}


@end
