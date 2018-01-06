//
//  LightShadowPopoverController.m
//  ModelViewer
//
//  Created by Dong on 9/19/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "LightShadowPopoverController.h"
#import "LightOperationPanel.h"

@interface LightShadowPopoverController ()

@property (nonatomic, weak) NSPopover* popover;
@property (nonatomic, weak) LightOperationPanel* sourcePanel;

@end

@implementation LightShadowPopoverController
{
    NSSlider* _occulderSlider;
}

- (instancetype)initWithPopover:(NSPopover*)popover
                withSourcePanel:(LightOperationPanel*)sourcePanel
{
    self = [super init];
    if (self)
    {
        _popover = popover;
        _sourcePanel = sourcePanel;
    }
    return self;
}


- (void)loadView
{
    self.view = [NSView new];
    self.view.frame = CGRectMake(0, 0, _popover.contentSize.width, _popover.contentSize.height);
    
    NSTextField* label = [self createLabel:@"Occluder Search Radius:"];
    _occulderSlider = [self createSliderMax:20.0 min:2.0];
    _occulderSlider.floatValue = _occluderSearchRadius;
    
    CGSize viewSize = self.view.bounds.size;
    const CGFloat kLineHeight = 18;
    const CGFloat kLineSpace = 8;
    CGFloat baseVertical = viewSize.height - kLineHeight - 12;
    
    CGRect labelFrame = CGRectMake(0, 0, 158, kLineHeight);
    labelFrame.origin.y = baseVertical;
    label.frame = labelFrame;
    
    static float kFieldSpace = 8;
    
    CGRect sliderFrame = labelFrame;
    sliderFrame.origin.x += label.frame.size.width + kFieldSpace;
    sliderFrame.size.width = viewSize.width - label.frame.size.width - kFieldSpace * 2;
    _occulderSlider.frame = sliderFrame;
    
    // sample count
    
    baseVertical -= (kLineHeight + kLineSpace);
    
    NSTextField* labelDensity = [self createLabel:@"Occluder Samples:"];
    labelFrame.origin.y = baseVertical;
    labelDensity.frame = labelFrame;
    
    NSPopUpButton* samplePopup = [NSPopUpButton new];
    [samplePopup addItemWithTitle:@"36"];
    [samplePopup addItemWithTitle:@"16"];
    [samplePopup setFont:[NSFont fontWithName:samplePopup.font.fontName size:11]];
    [samplePopup setControlSize:NSControlSizeSmall];
    
    CGRect samplePopupFrame = labelFrame;
    samplePopupFrame.size.height = 30.0;
    samplePopupFrame.size.width = 80;
    samplePopupFrame.origin.x += labelFrame.size.width + kFieldSpace;
    samplePopupFrame.origin.y -= (samplePopupFrame.size.height - labelFrame.size.height) / 2.0 + 2.0;
    samplePopup.frame = samplePopupFrame;
    
    [self.view addSubview:samplePopup];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
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
    [self.view addSubview:label];
    return label;
}


- (NSSlider*)createSliderMax:(float)max min:(float)min
{
    NSSlider* slider = [[NSSlider alloc] init];
    [slider setMaxValue:max];
    [slider setMinValue:min];
    [slider setTarget:self];
    [self.view addSubview:slider];
    [slider setAction:@selector(lightShadowSettingsChange:)];
    return slider;
}


- (void)lightShadowSettingsChange:(id)sender
{
    [_sourcePanel setShadowOccluderRadius:_occulderSlider.floatValue];
    [_sourcePanel lightSettingsChange:self];
}


@end
