//
//  NuoOpenEndSlider.m
//  ModelViewer
//
//  Created by Dong on 1/17/20.
//  Copyright © 2020 middleware. All rights reserved.
//

#import "NuoOpenEndSlider.h"
#import <AppKit/AppKit.h>



static float kSlideNameLabelHeight = 21.0;
static float kHorizontalMargin = 15.0;



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
        _sliderEnd = 200.0;
        
        [self initCommon];
    }
    
    return self;
}


- (void)initCommon
{
    _sliderNameLabel = [self createLabel:_sliderName withAligment:NSTextAlignmentLeft];
    _sliderEndField = [NSTextField new];
    _slider = [self createSliderMax:0 min:200];
    
    _sliderEndField.controlSize = NSControlSizeSmall;
    _sliderEndField.font = [NSFont fontWithName:_sliderEndField.font.fontName size:11.0];
    _sliderEndField.focusRingType = NSFocusRingTypeNone;
    _sliderEndField.bezelStyle = NSTextFieldSquareBezel;
    
    [self addSubview:_sliderEndField];
    
    [_sliderEndField setTarget:self];
    [_sliderEndField setAction:@selector(endValueChanged:)];
    [_slider setTarget:self];
    [_slider setAction:@selector(sliderValueChanged:)];
}


- (void)updateLayout
{
    CGRect frame = self.frame;
    CGSize frameSize = frame.size;
    
    float nameLabelOrigin = frameSize.height - kSlideNameLabelHeight - 3.0;
    
    CGRect nameLabelFrame = CGRectMake(kHorizontalMargin, nameLabelOrigin, frameSize.width, kSlideNameLabelHeight);
    CGRect sliderFrame = CGRectMake(kHorizontalMargin, nameLabelOrigin - kSlideNameLabelHeight,
                                    frameSize.width - kHorizontalMargin * 2.0 + 4.0,
                                    kSlideNameLabelHeight);
    
    CGRect endFieldFrame = nameLabelFrame;
    endFieldFrame.size.width = 60.0;
    endFieldFrame.origin.x = kHorizontalMargin + sliderFrame.size.width - endFieldFrame.size.width - 4.0;
    endFieldFrame.origin.y += 2.0;
    
    _sliderNameLabel.frame = nameLabelFrame;
    _slider.frame = sliderFrame;
    _slider.minValue = 0.0;
    _slider.maxValue = _sliderEnd;
    _slider.floatValue = _floatValue;
    
    _sliderEndField.frame = endFieldFrame;
    
    NSString* endValueString = [NSString stringWithFormat:@"%0.1ld", _sliderEnd];
    _sliderEndField.stringValue = endValueString;
}


- (void)endValueChanged:(id)sender
{
    NSNumberFormatter* formatter = [NSNumberFormatter new];
    long end = [formatter numberFromString:_sliderEndField.stringValue].longValue;
    
    _sliderEnd = end;
    [self updateLayout];
}


- (void)sliderValueChanged:(id)sender
{
    _floatValue = _slider.floatValue;
    
    if (_valueChanged)
        _valueChanged();
}


- (void)setFloatValue:(long)floatValue
{
    _floatValue = floatValue;
    
    float sectionValue;
    float endValue = 10000.0;
    
    while (endValue > 10.0)
    {
        sectionValue = _floatValue / endValue;
        if (sectionValue > 1.0)
        {
            sectionValue = floor(sectionValue);
            _sliderEnd = fmax(200, (sectionValue + 1.0) * endValue);
            break;
        }
        
        endValue /= 10.0;
    }
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
