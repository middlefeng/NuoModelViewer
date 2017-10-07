//
//  ModelOperationAmbientPopover.m
//  ModelViewer
//
//  Created by Dong on 10/5/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "ModelOperationAmbientPopover.h"
#import "ModelOperationPanel.h"



@interface ModelOperationAmbientPopover ()

@property (nonatomic, weak) id<ModelOptionUpdate> updateDelegate;
@property (nonatomic, weak) NSPopover* popover;
@property (nonatomic, weak) ModelOperationPanel* sourcePanel;

@end




@implementation ModelOperationAmbientPopover



- (instancetype)initWithPopover:(NSPopover*)popover
                withSourcePanel:(ModelOperationPanel*)sourcePanel
                   withDelegate:(id<ModelOptionUpdate>)delegate
{
    self = [super init];
    if (self)
    {
        _popover = popover;
        _sourcePanel = sourcePanel;
        _updateDelegate = delegate;
    }
    return self;
}


- (void)loadView
{
    self.view = [NSView new];
    self.view.frame = CGRectMake(0, 0, _popover.contentSize.width, _popover.contentSize.height);
    
    CGFloat rowHeight = 25;
    CGFloat rowCoord = rowHeight * 3 + 10;
    
    CGSize viewSize = self.view.bounds.size;
    CGRect labelFrame = CGRectMake(15, 0, 60, rowHeight);
    CGRect sliderFrame;
    labelFrame.origin.y = rowCoord;
    
    NSTextField* labelBias = [NSTextField new];
    [labelBias setEditable:NO];
    [labelBias setSelectable:NO];
    [labelBias setBordered:NO];
    [labelBias setBackgroundColor:[NSColor colorWithWhite:0.0 alpha:0.0]];
    [labelBias setStringValue:@"Bias:"];
    [labelBias setAlignment:NSTextAlignmentRight];
    [labelBias setFrame:labelFrame];
    [self.view addSubview:labelBias];
    
    sliderFrame = labelFrame;
    sliderFrame.origin.x += labelFrame.size.width + 3;
    sliderFrame.origin.y += 2;
    sliderFrame.size.width = viewSize.width - sliderFrame.origin.x - 20;
    NSSlider* sliderBias = [NSSlider new];
    [sliderBias setMaxValue:1.0];
    [sliderBias setMinValue:0.0];
    [sliderBias setTarget:self];
    [sliderBias setFrame:sliderFrame];
    [self.view addSubview:sliderBias];
    //[slider setAction:@selector(lightShadowSettingsChange:)];
    
    labelFrame.origin.y -= rowHeight;
    
    NSTextField* labelIntensity = [NSTextField new];
    [labelIntensity setEditable:NO];
    [labelIntensity setSelectable:NO];
    [labelIntensity setBordered:NO];
    [labelIntensity setBackgroundColor:[NSColor colorWithWhite:0.0 alpha:0.0]];
    [labelIntensity setStringValue:@"Intensity:"];
    [labelIntensity setAlignment:NSTextAlignmentRight];
    [labelIntensity setFrame:labelFrame];
    [self.view addSubview:labelIntensity];
    
    sliderFrame = labelFrame;
    sliderFrame.origin.x += labelFrame.size.width + 3;
    sliderFrame.origin.y += 2;
    sliderFrame.size.width = viewSize.width - sliderFrame.origin.x - 20;
    NSSlider* sliderIntensity = [NSSlider new];
    [sliderIntensity setMaxValue:1.0];
    [sliderIntensity setMinValue:0.0];
    [sliderIntensity setTarget:self];
    [sliderIntensity setFrame:sliderFrame];
    [self.view addSubview:sliderIntensity];
    
    labelFrame.origin.y -= rowHeight;
    
    NSTextField* labelRange = [NSTextField new];
    [labelRange setEditable:NO];
    [labelRange setSelectable:NO];
    [labelRange setBordered:NO];
    [labelRange setBackgroundColor:[NSColor colorWithWhite:0.0 alpha:0.0]];
    [labelRange setStringValue:@"Range:"];
    [labelRange setAlignment:NSTextAlignmentRight];
    [labelRange setFrame:labelFrame];
    [self.view addSubview:labelRange];
    
    sliderFrame = labelFrame;
    sliderFrame.origin.x += labelFrame.size.width + 3;
    sliderFrame.origin.y += 2;
    sliderFrame.size.width = viewSize.width - sliderFrame.origin.x - 20;
    NSSlider* sliderRange = [NSSlider new];
    [sliderRange setMaxValue:1.0];
    [sliderRange setMinValue:0.0];
    [sliderRange setTarget:self];
    [sliderRange setFrame:sliderFrame];
    [self.view addSubview:sliderRange];
    
    labelFrame.origin.y -= rowHeight;
    
    NSTextField* labelScale = [NSTextField new];
    [labelScale setEditable:NO];
    [labelScale setSelectable:NO];
    [labelScale setBordered:NO];
    [labelScale setBackgroundColor:[NSColor colorWithWhite:0.0 alpha:0.0]];
    [labelScale setStringValue:@"Scale:"];
    [labelScale setAlignment:NSTextAlignmentRight];
    [labelScale setFrame:labelFrame];
    [self.view addSubview:labelScale];
    
    sliderFrame = labelFrame;
    sliderFrame.origin.x += labelFrame.size.width + 3;
    sliderFrame.origin.y += 2;
    sliderFrame.size.width = viewSize.width - sliderFrame.origin.x - 20;
    NSSlider* sliderScale = [NSSlider new];
    [sliderScale setMaxValue:1.0];
    [sliderScale setMinValue:0.0];
    [sliderScale setTarget:self];
    [sliderScale setFrame:sliderFrame];
    [self.view addSubview:sliderScale];
}


@end
