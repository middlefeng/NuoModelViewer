//
//  ModelOperationPanel.m
//  ModelViewer
//
//  Created by middleware on 1/5/17
//  Copyright © 2016 middleware. All rights reserved.
//

#import "LightOperationPanel.h"
#import "LightShadowPopoverController.h"

#import "ModelOptionUpdate.h"
#import "NuoLightSource.h"

#import "NuoPopoverSheet.h"


@interface LightOperationPanel () < NuoPopoverSheetDelegate >

@end



@implementation LightOperationPanel
{
    NSTextField* _lightDensityLabel;
    NSSlider* _lightDensitySlider;
    
    NSTextField* _lightSpecularLabel;
    NSSlider* _lightSpecularSlider;
    
    NSTextField* _shadowSoftenLabel;
    NSSlider* _shadowSoftenSlider;
    NuoPopoverSheet* _shadowSoftenPopover;
    
    NSTextField* _shadowBiasLabel;
    NSSlider* _shadowBiasSlider;
}


- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    
    if (self)
    {
        [self setWantsLayer:YES];
        
        _lightDensityLabel = [self createLabel:@"Density:"];
        _lightDensitySlider = [self createSliderMax:3.0 min:0.0];
        
        _lightSpecularLabel = [self createLabel:@"Spacular:"];
        _lightSpecularSlider = [self createSliderMax:3.0 min:0.0];

        _shadowSoftenLabel = [self createLabel:@"Penumbra:"];
        _shadowSoftenSlider = [self createSliderMax:5.0 min:0.0];
        
        _shadowSoftenPopover = [[NuoPopoverSheet alloc] initWithParent:self];
        _shadowSoftenPopover.sheetDelegate = self;
        
        _shadowBiasLabel = [self createLabel:@"Bias:"];
        _shadowBiasSlider = [self createSliderMax:0.01 min:0.0];
    }
    
    return self;
}


- (NSTextField*)createLabel:(NSString*)text
{
    NSTextField* label = [[NSTextField alloc] init];
    [label setEditable:NO];
    [label setSelectable:NO];
    [label setBordered:NO];
    [label setBackgroundColor:[NSColor colorWithWhite:0.0 alpha:0.0]];
    [label setStringValue:text];
    [label setAlignment:NSTextAlignmentRight];
    [self addSubview:label];
    return label;
}


- (NSSlider*)createSliderMax:(float)max min:(float)min
{
    NSSlider* slider = [[NSSlider alloc] init];
    [slider setMaxValue:max];
    [slider setMinValue:min];
    [slider setTarget:self];
    [self addSubview:slider];
    [slider setAction:@selector(lightSettingsChange:)];
    return slider;
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
    
    float labelWidth = 75;
    float labelSpace = 2;
    float entryHeight = 18;
    float lineSpace = 6;
    
    CGRect labelFrame;
    labelFrame.size = CGSizeMake(labelWidth, entryHeight);
    labelFrame.origin = CGPointMake(0, (entryHeight + lineSpace) * 3 + 5);
    
    [_lightDensityLabel setFrame:labelFrame];
    
    CGRect sliderFrame;
    sliderFrame.size = CGSizeMake(viewSize.width - labelWidth - labelSpace, entryHeight);
    sliderFrame.origin = CGPointMake(labelWidth + labelSpace, (entryHeight + lineSpace) * 3 + 5);
    [_lightDensitySlider setFrame:sliderFrame];
    
    labelFrame.origin.y -= entryHeight + lineSpace;
    sliderFrame.origin.y -= entryHeight + lineSpace;
    
    [_lightSpecularLabel setFrame:labelFrame];
    [_lightSpecularSlider setFrame:sliderFrame];
    
    labelFrame.origin.y -= entryHeight + lineSpace;
    sliderFrame.origin.y -= entryHeight + lineSpace;
    
    CGRect softenSliderFrame = sliderFrame;
    softenSliderFrame.size.width -= 32;
    [_shadowSoftenLabel setFrame:labelFrame];
    [_shadowSoftenSlider setFrame:softenSliderFrame];
    
    CGRect popButtonFrame = sliderFrame;
    popButtonFrame.size = CGSizeMake(30, 30);
    popButtonFrame.origin.x = viewSize.width - popButtonFrame.size.width;
    popButtonFrame.origin.y -= (popButtonFrame.size.height - sliderFrame.size.height) / 2.0;
    [_shadowSoftenPopover setFrame:popButtonFrame];
    
    labelFrame.origin.y -= entryHeight + lineSpace;
    sliderFrame.origin.y -= entryHeight + lineSpace;
    
    [_shadowBiasLabel setFrame:labelFrame];
    [_shadowBiasSlider setFrame:sliderFrame];
}



- (float)lightDensity
{
    return [_lightDensitySlider floatValue];
}


- (void)setLightDensity:(float)lightDensity
{
    [_lightDensitySlider setFloatValue:lightDensity];
}


- (float)lightSpecular
{
    return [_lightSpecularSlider floatValue];
}


- (void)setLightSpecular:(float)lightSpacular
{
    [_lightSpecularSlider setFloatValue:lightSpacular];
}

- (void)setShadowEnabled:(BOOL)shadowEnabled
{
    _shadowEnabled = shadowEnabled;
    [_shadowSoftenLabel setHidden:!shadowEnabled];
    [_shadowSoftenSlider setHidden:!shadowEnabled];
    [_shadowSoftenPopover setHidden:!shadowEnabled];
    [_shadowBiasLabel setHidden:!shadowEnabled];
    [_shadowBiasSlider setHidden:!shadowEnabled];
}


- (float)shadowSoften
{
    return [_shadowSoftenSlider floatValue];
}



- (void)setShadowSoften:(float)shadowSoften
{
    [_shadowSoftenSlider setFloatValue:shadowSoften];
}



- (float)shadowBias
{
    return [_shadowBiasSlider floatValue];
}



- (void)setShadowBias:(float)shadowBias
{
    [_shadowBiasSlider setFloatValue:shadowBias];
}



- (void)lightSettingsChange:(id)sender
{
    [_optionUpdateDelegate modelOptionUpdate:kUpdateOption_DecreaseQuality];
}



- (void)updateControls:(NuoLightSource*)lightSource
{
    [self setLightDensity:lightSource.lightingDensity];
    [self setLightSpecular:lightSource.lightingSpecular];
    [self setShadowEnabled:lightSource.enableShadow];
    
    if (lightSource.enableShadow)
    {
        [self setShadowSoften:lightSource.shadowSoften];
        [self setShadowOccluderRadius:lightSource.shadowOccluderRadius];
        [self setShadowBias:lightSource.shadowBias];
    }
}


#pragma mark -- NuoPopoverSheetDelegate --

- (CGSize)popoverSheetcontentSize:(NuoPopoverSheet *)sheet
{
    return CGSizeMake(300, 50);
}

- (NSViewController *)popoverSheetcontentViewController:(NuoPopoverSheet *)sheet
{
    LightShadowPopoverController* controller = [[LightShadowPopoverController alloc] initWithPopover:_shadowSoftenPopover.popover
                                                                                     withSourcePanel:self];
    controller.occluderSearchRadius = _shadowOccluderRadius;
    return controller;
}


@end
