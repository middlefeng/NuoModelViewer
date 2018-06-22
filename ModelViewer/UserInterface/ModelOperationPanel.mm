//
//  ModelOperationPanel.m
//  ModelViewer
//
//  Created by middleware on 9/15/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "ModelOperationPanel.h"
#import "NuoMeshOptions.h"
#import "NuoMeshAnimation.h"

#import "NuoPopoverSheet.h"
#import "ModelOperationTexturePopover.h"
#import "ModelOperationAmbientPopover.h"


@interface ModelOperationPanel() < NSTableViewDataSource, NSTableViewDelegate, NuoPopoverSheetDelegate >


@property (nonatomic, strong) NSButton* checkModelParts;
@property (nonatomic, strong) NSButton* checkFrameRate;

@property (nonatomic, strong) NSButton* checkMaterial;
@property (nonatomic, strong) NSButton* checkTexture;
@property (nonatomic, strong) NuoPopoverSheet* checkTexturePopover;

@property (nonatomic, strong) NSButton* cull;
@property (nonatomic, strong) NSButton* combine;

@property (nonatomic, assign) NSSlider* fieldOfView;

@property (nonatomic, strong) NSSlider* ambientDensitySlider;
@property (nonatomic, strong) NuoPopoverSheet* ambientPopover;

@property (nonatomic, strong) NSButton* lightSettings;
@property (nonatomic, strong) NSButton* checkBrdfMode;
@property (nonatomic, strong) NSPopUpButton* checkDissectMode;
@property (nonatomic, strong) NSPopUpButton* checkTransMode;

@property (nonatomic, strong) NSSlider* animationSlider;

@property (nonatomic, strong) NSButton* motionBlurRecord;
@property (nonatomic, strong) NSButton* motionBlurPause;

@property (nonatomic, strong) NSButton* rayTracingRecord;
@property (nonatomic, strong) NSButton* rayTracingPause;

@property (nonatomic, strong) NSPopUpButton* deviceList;

@end



@implementation ModelOperationPanel
{
    IBOutlet NSScrollView* _animationScroll;
    IBOutlet NSTableView* _animationTable;
    __weak NSArray<NuoMeshAnimation*>* _animations;
}


- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _meshOptions = [NuoMeshOption new];
        _meshOptions.combineShapes = YES;
        _meshOptions.texturedBump = YES;
        
        _deferredRenderParameters.ambientOcclusionParams.bias = 0.4;
        _deferredRenderParameters.ambientOcclusionParams.intensity = 3.0;
        _deferredRenderParameters.ambientOcclusionParams.sampleRadius = 0.8;
        _deferredRenderParameters.ambientOcclusionParams.scale = 1.0;

        const NuoVectorFloat4 clearColor(0.0, 0.0, 0.0, 0.0);
        _deferredRenderParameters.clearColor = clearColor._vector;
        
        _cullEnabled = YES;
        
        _fieldOfViewRadian = (2 * M_PI) / 8;
        _showLightSettings = NO;
        _ambientDensity = 0.28;
        
        _motionBlurRecordStatus = kRecord_Stop;
        _rayTracingRecordStatus = kRecord_Stop;
    }
    
    return self;
}


- (void)addSubviews
{
    // scroll view and its document view initialization
    //
    
    NSView* scrollDocumentView = [[NSView alloc] init];
    NSScrollView* rootScroll = [[NSScrollView alloc] init];
    rootScroll.documentView = scrollDocumentView;
    rootScroll.hasVerticalScroller = YES;
    
    CGSize viewSize = [self bounds].size;
    CGRect rootViewFrame;
    rootViewFrame.origin.x = 0.0;
    rootViewFrame.origin.y = 0.0;
    rootViewFrame.size.width = viewSize.width;
    rootViewFrame.size.height = viewSize.height;
    
    CGRect docViewFrame = CGRectMake(0, 0, 0, 0);
    docViewFrame.size = rootViewFrame.size;
    docViewFrame.size.height += 290.0;
    
    rootScroll.frame = rootViewFrame;
    scrollDocumentView.frame = docViewFrame;
    
    // rows of labels and checkboxs/sliders
    //
    
    float rowCoord = 0.0;
    
    NSButton* checkModelParts = [NSButton new];
    [checkModelParts setButtonType:NSSwitchButton];
    [checkModelParts setTitle:@"Show Model Parts"];
    [checkModelParts setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView]];
    [checkModelParts setTarget:self];
    [checkModelParts setAction:@selector(showModelPartsChanged:)];
    [scrollDocumentView addSubview:checkModelParts];
    _checkModelParts = checkModelParts;
    
    rowCoord += 1.0;
    
    NSButton* checkFrameRate = [NSButton new];
    [checkFrameRate setButtonType:NSSwitchButton];
    [checkFrameRate setTitle:@"Show Frame Rate"];
    [checkFrameRate setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView]];
    [checkFrameRate setTarget:self];
    [checkFrameRate setAction:@selector(showModelFrameRateChanged:)];
    [scrollDocumentView addSubview:checkFrameRate];
    _checkFrameRate = checkFrameRate;
    
    rowCoord += 1.2;
    
    NSButton* checkMaterial = [NSButton new];
    [checkMaterial setButtonType:NSSwitchButton];
    [checkMaterial setTitle:@"Basic Material"];
    [checkMaterial setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView]];
    [checkMaterial setTarget:self];
    [checkMaterial setAction:@selector(basicMaterializedChanged:)];
    [scrollDocumentView addSubview:checkMaterial];
    _checkMaterial = checkMaterial;
    
    rowCoord += 1.0;
    
    NSButton* checkTexture = [NSButton new];
    [checkTexture setButtonType:NSSwitchButton];
    [checkTexture setTitle:@"Model Textures"];
    [checkTexture setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView]];
    [checkTexture setTarget:self];
    [checkTexture setAction:@selector(texturedChanged:)];
    [scrollDocumentView addSubview:checkTexture];
    _checkTexture = checkTexture;
    
    NuoPopoverSheet* checkTexturePopover = [[NuoPopoverSheet alloc] initWithParent:scrollDocumentView];
    CGSize popoverButtonSize = CGSizeMake(30, 30);
    CGRect popoverFrame = [self buttonLoactionAtRow:rowCoord withLeading:108 inView:scrollDocumentView];
    popoverFrame.origin.y -= (popoverButtonSize.height - popoverFrame.size.height) / 2.0;
    popoverFrame.size = popoverButtonSize;
    [checkTexturePopover setFrame:popoverFrame];
    checkTexturePopover.sheetDelegate = self;
    _checkTexturePopover = checkTexturePopover;
    
    rowCoord += 1.0;
    
    NSButton* cull = [NSButton new];
    [cull setButtonType:NSSwitchButton];
    [cull setTitle:@"Enable Culling"];
    [cull setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0
                                      inView:scrollDocumentView]];
    [cull setTarget:self];
    [cull setAction:@selector(cullChanged:)];
    [scrollDocumentView addSubview:cull];
    _cull = cull;
    
    rowCoord += 1;
    
    NSButton* combine = [NSButton new];
    [combine setButtonType:NSSwitchButton];
    [combine setTitle:@"Combine Shapes by Material"];
    [combine setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView]];
    [combine setTarget:self];
    [combine setAction:@selector(combineChanged:)];
    [scrollDocumentView addSubview:combine];
    _combine = combine;
    
    rowCoord += 1.2;
    
    NSTextField* labelFOV = [NSTextField new];
    [labelFOV setEditable:NO];
    [labelFOV setSelectable:NO];
    [labelFOV setBordered:NO];
    [labelFOV setStringValue:@"Field of View:"];
    [labelFOV setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView]];
    [scrollDocumentView addSubview:labelFOV];
    
    rowCoord += 0.7;
    
    NSSlider* fieldOfView = [NSSlider new];
    [fieldOfView setFrame:[self buttonLoactionAtRow:rowCoord withLeading:6 inView:scrollDocumentView]];
    [fieldOfView setMaxValue:_fieldOfViewRadian];
    [fieldOfView setMinValue:1e-6];
    [fieldOfView setTarget:self];
    [fieldOfView setAction:@selector(fieldOfViewChanged:)];
    [scrollDocumentView addSubview:fieldOfView];
    _fieldOfView = fieldOfView;
    
    rowCoord += 0.8;
    
    NSTextField* labelambientDensity = [NSTextField new];
    [labelambientDensity setEditable:NO];
    [labelambientDensity setSelectable:NO];
    [labelambientDensity setBordered:NO];
    [labelambientDensity setStringValue:@"Ambient Density:"];
    [labelambientDensity setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView]];
    [scrollDocumentView addSubview:labelambientDensity];
    
    rowCoord += 0.8;
    
    NSSlider* ambientDensity = [NSSlider new];
    CGRect ambientDensityFrame = [self buttonLoactionAtRow:rowCoord withLeading:6 inView:scrollDocumentView];
    ambientDensityFrame.size.width -= 27;
    [ambientDensity setFrame:ambientDensityFrame];
    [ambientDensity setMaxValue:2.0];
    [ambientDensity setMinValue:0];
    [ambientDensity setTarget:self];
    [ambientDensity setAction:@selector(ambientDensityChanged:)];
    [scrollDocumentView addSubview:ambientDensity];
    _ambientDensitySlider = ambientDensity;
    
    popoverFrame = ambientDensity.frame;
    popoverFrame.size = CGSizeMake(30, 30);
    popoverFrame.origin.x = ambientDensity.frame.origin.x + ambientDensity.frame.size.width + 2;
    popoverFrame.origin.y -= ((popoverFrame.size.height - labelambientDensity.frame.size.height) / 2.0);
    NuoPopoverSheet* ambientPopover = [[NuoPopoverSheet alloc] initWithParent:scrollDocumentView];
    ambientPopover.sheetDelegate = self;
    [ambientPopover setFrame:popoverFrame];
    
    rowCoord += 1.2;
    
    NSButton* lightSettings = [NSButton new];
    [lightSettings setButtonType:NSSwitchButton];
    [lightSettings setTitle:@"Light Settings"];
    [lightSettings setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView]];
    [lightSettings setTarget:self];
    [lightSettings setAction:@selector(lightSettingsChanged:)];
    [scrollDocumentView addSubview:lightSettings];
    _lightSettings = lightSettings;
    
    rowCoord += 1.0;
    
    NSButton* brdfMode = [NSButton new];
    [brdfMode setButtonType:NSSwitchButton];
    [brdfMode setTitle:@"Physically Based Reflection"];
    [brdfMode setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView]];
    [brdfMode setTarget:self];
    [brdfMode setAction:@selector(brdfModeChanged:)];
    [scrollDocumentView addSubview:brdfMode];
    _checkBrdfMode = brdfMode;
    
    rowCoord += 1.4;
    
    static const float kLabelHead = 105;
    
    NSRect dissectModelFrame = [self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView];
    NSRect dissectModelLabelFrame = dissectModelFrame;
    dissectModelFrame.size.height = 20.0;
    dissectModelFrame.origin.x += kLabelHead;
    dissectModelFrame.size.width -= kLabelHead;
    dissectModelLabelFrame.size.width = 90;
    dissectModelLabelFrame.origin.y += 2;
    
    NSPopUpButton* dissectMode = [NSPopUpButton new];
    NSTextField* dissectModelLabel = [NSTextField new];
    [dissectModelLabel setEditable:NO];
    [dissectModelLabel setSelectable:NO];
    [dissectModelLabel setBordered:NO];
    [dissectModelLabel setAlignment:NSTextAlignmentRight];
    [dissectModelLabel setStringValue:@"Render Mode:"];
    [dissectModelLabel setFrame:dissectModelLabelFrame];
    [scrollDocumentView addSubview:dissectModelLabel];
    
    [dissectMode setFrame:dissectModelFrame];
    [dissectMode setTarget:self];
    [dissectMode setFont:[NSFont fontWithName:dissectMode.font.fontName size:11]];
    [dissectMode setControlSize:NSControlSizeSmall];
    
    [dissectMode addItemWithTitle:@"Model"];
    [dissectMode addItemWithTitle:@"Occluder"];
    [dissectMode addItemWithTitle:@"Penumbra"];
    [dissectMode setAction:@selector(dissectModeChanged:)];
    [scrollDocumentView addSubview:dissectMode];
    _checkDissectMode = dissectMode;
    
    rowCoord += 1.0;
    
    NSRect transferModelFrame = [self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView];
    NSRect transferModelLabelFrame = transferModelFrame;
    transferModelFrame.size.height = 20.0;
    transferModelFrame.origin.x += kLabelHead;
    transferModelFrame.size.width -= kLabelHead;
    transferModelLabelFrame.size.width = 90;
    transferModelLabelFrame.origin.y += 2;
    
    NSPopUpButton* transMode = [NSPopUpButton new];
    NSTextField* transferModeLabel = [NSTextField new];
    [transferModeLabel setEditable:NO];
    [transferModeLabel setSelectable:NO];
    [transferModeLabel setBordered:NO];
    [transferModeLabel setAlignment:NSTextAlignmentRight];
    [transferModeLabel setStringValue:@"Transfer Mode:"];
    [transferModeLabel setFrame:transferModelLabelFrame];
    [scrollDocumentView addSubview:transferModeLabel];
    
    [transMode setFrame:transferModelFrame];
    [transMode setTarget:self];
    [transMode setFont:[NSFont fontWithName:dissectMode.font.fontName size:11]];
    [transMode setControlSize:NSControlSizeSmall];
    
    [transMode addItemWithTitle:@"Object"];
    [transMode addItemWithTitle:@"Scene"];
    [transMode setAction:@selector(transModeChanged:)];
    [scrollDocumentView addSubview:transMode];
    _checkTransMode = transMode;
    
    rowCoord += 0.6;
    
    NSImageView* imageView = [NSImageView new];
    imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    imageView.image = [NSImage imageNamed:@"ArrowDown"];
    imageView.hidden = NO;
    NSRect imageViewFrame = [self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView];
    imageViewFrame.size.height = 6;
    imageView.frame = imageViewFrame;
    imageView.alphaValue = 0.6;
    [scrollDocumentView addSubview:imageView];
    
    rowCoord += 1.4;
    
    // animation list/slider
    //
    
    NSTextField* labelAnimation = [NSTextField new];
    [labelAnimation setEditable:NO];
    [labelAnimation setSelectable:NO];
    [labelAnimation setBordered:NO];
    [labelAnimation setStringValue:@"Animations:"];
    [labelAnimation setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView]];
    [scrollDocumentView addSubview:labelAnimation];
    
    NSRect animationLoadRect = [self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView];
    animationLoadRect.origin.x += 131;
    animationLoadRect.origin.y -= 4;
    animationLoadRect.size.width -= 131;
    animationLoadRect.size.height = 27;
    NSButton* animationLoad = [[NSButton alloc] init];
    [animationLoad setTitle:@"Load ..."];
    [animationLoad setFrame:animationLoadRect];
    [animationLoad setBezelStyle:NSRoundedBezelStyle];
    [animationLoad setControlSize:NSControlSizeSmall];
    [animationLoad setTarget:self];
    [animationLoad setAction:@selector(loadAnimation:)];
    [scrollDocumentView addSubview:animationLoad];
    
    [[NSBundle mainBundle] loadNibNamed:@"ModelPartsAnimations" owner:self topLevelObjects:nil];
    
    rowCoord += 1.2;
    
    CGColorRef border = CGColorCreateGenericGray(0.6, 0.5);
    
    NSRect animationRect = [self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView];
    animationRect.size.height = 90;
    animationRect.origin.y -= 70;
    NSView* animationRoot = [[NSView alloc] init];
    [animationRoot setWantsLayer:YES];
    animationRoot.layer = [CALayer new];
    animationRoot.frame = animationRect;
    animationRoot.layer.borderWidth = 1.0;
    animationRoot.layer.borderColor = border;
    [_animationScroll setFrame:animationRoot.bounds];
    [_animationTable setDataSource:self];
    [_animationTable setDelegate:self];
    [animationRoot addSubview:_animationScroll];
    [scrollDocumentView addSubview:animationRoot];
    
    CGColorRelease(border);
    
    [self addSubview:rootScroll];
    [rootScroll.contentView scrollToPoint:CGPointMake(0, docViewFrame.size.height)];
    
    NSSlider* animationProgressSlider = [[NSSlider alloc] init];
    [animationProgressSlider setMaxValue:1.0];
    [animationProgressSlider setMinValue:0.0];
    [animationProgressSlider setDoubleValue:0.0];
    [animationProgressSlider setTarget:self];
    [animationProgressSlider setAction:@selector(animationUpdate:)];
    
    NSRect animationProgressRect = animationRect;
    animationProgressRect.size.height = 18;
    animationProgressRect.origin.y -= 10.0 + animationProgressRect.size.height;
    [animationProgressSlider setFrame:animationProgressRect];
    [scrollDocumentView addSubview:animationProgressSlider];
    _animationSlider = animationProgressSlider;
    
    rowCoord += 5.4;
    
    // motion blur recording
    
    NSTextField* labelMotionBlurLabel = [NSTextField new];
    [labelMotionBlurLabel setEditable:NO];
    [labelMotionBlurLabel setSelectable:NO];
    [labelMotionBlurLabel setBordered:NO];
    [labelMotionBlurLabel setStringValue:@"Motion Blur:"];
    [labelMotionBlurLabel setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView]];
    [scrollDocumentView addSubview:labelMotionBlurLabel];
    
    NSRect recordRect = [self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView];
    recordRect.origin.x += 120;
    recordRect.origin.y -=10;
    recordRect.size.width = 40;
    recordRect.size.height = 35;
    
    NSButton* recordButton = [[NSButton alloc] init];
    [recordButton setTitle:@""];
    [recordButton setFrame:recordRect];
    [recordButton setBezelStyle:NSRoundedBezelStyle];
    [recordButton setButtonType:NSToggleButton];
    [recordButton setControlSize:NSControlSizeSmall];
    [recordButton setTarget:self];
    [recordButton setAction:@selector(motionBlurUpdate:)];
    [recordButton setImage:[NSImage imageNamed:@"MotionBlurRecord"]];
    [recordButton setAlternateImage:[NSImage imageNamed:@"MotionBlurStop"]];
    [recordButton setState:NSOffState];
    [recordButton setAllowsMixedState:NO];
    [scrollDocumentView addSubview:recordButton];
    _motionBlurRecord = recordButton;
    
    recordRect.origin.x += 35;
    
    NSButton* pauseButton = [[NSButton alloc] init];
    [pauseButton setTitle:@""];
    [pauseButton setFrame:recordRect];
    [pauseButton setBezelStyle:NSRoundedBezelStyle];
    [pauseButton setButtonType:NSToggleButton];
    [pauseButton setControlSize:NSControlSizeSmall];
    [pauseButton setTarget:self];
    [pauseButton setAction:@selector(motionBlurUpdate:)];
    [pauseButton setImage:[NSImage imageNamed:@"MotionBlurPause"]];
    [pauseButton setAlternateImage:[NSImage imageNamed:@"MotionBlurPaused"]];
    [recordButton setState:NSOffState];
    [scrollDocumentView addSubview:pauseButton];
    _motionBlurPause = pauseButton;
    
    // motion blur recording
    
    rowCoord += 1.0;
    
    NSTextField* labelRayTracingLabel = [NSTextField new];
    [labelRayTracingLabel setEditable:NO];
    [labelRayTracingLabel setSelectable:NO];
    [labelRayTracingLabel setBordered:NO];
    [labelRayTracingLabel setStringValue:@"Ray Tracing:"];
    [labelRayTracingLabel setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView]];
    [scrollDocumentView addSubview:labelRayTracingLabel];
    
    NSRect recordRectRayTracing = [self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView];
    recordRectRayTracing.origin.x += 120;
    recordRectRayTracing.origin.y -=10;
    recordRectRayTracing.size.width = 40;
    recordRectRayTracing.size.height = 35;
    
    NSButton* recordButtonRayTracing = [[NSButton alloc] init];
    [recordButtonRayTracing setTitle:@""];
    [recordButtonRayTracing setFrame:recordRectRayTracing];
    [recordButtonRayTracing setBezelStyle:NSRoundedBezelStyle];
    [recordButtonRayTracing setButtonType:NSToggleButton];
    [recordButtonRayTracing setControlSize:NSControlSizeSmall];
    [recordButtonRayTracing setTarget:self];
    [recordButtonRayTracing setAction:@selector(rayTracingUpdate:)];
    [recordButtonRayTracing setImage:[NSImage imageNamed:@"MotionBlurRecord"]];
    [recordButtonRayTracing setAlternateImage:[NSImage imageNamed:@"MotionBlurStop"]];
    [recordButtonRayTracing setState:NSOffState];
    [recordButtonRayTracing setAllowsMixedState:NO];
    [scrollDocumentView addSubview:recordButtonRayTracing];
    _rayTracingRecord = recordButtonRayTracing;
    
    recordRectRayTracing.origin.x += 35;
    
    NSButton* pauseButtonRayTracing = [[NSButton alloc] init];
    [pauseButtonRayTracing setTitle:@""];
    [pauseButtonRayTracing setFrame:recordRectRayTracing];
    [pauseButtonRayTracing setBezelStyle:NSRoundedBezelStyle];
    [pauseButtonRayTracing setButtonType:NSToggleButton];
    [pauseButtonRayTracing setControlSize:NSControlSizeSmall];
    [pauseButtonRayTracing setTarget:self];
    [pauseButtonRayTracing setAction:@selector(rayTracingUpdate:)];
    [pauseButtonRayTracing setImage:[NSImage imageNamed:@"MotionBlurPause"]];
    [pauseButtonRayTracing setAlternateImage:[NSImage imageNamed:@"MotionBlurPaused"]];
    [pauseButtonRayTracing setState:NSOffState];
    [scrollDocumentView addSubview:pauseButtonRayTracing];
    _rayTracingPause = pauseButtonRayTracing;
    
    // device select
    
    rowCoord += 1.8;
    
    NSTextField* labelDevices = [NSTextField new];
    NSRect labelDevicesRect = [self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView];
    
    [labelDevices setEditable:NO];
    [labelDevices setSelectable:NO];
    [labelDevices setBordered:NO];
    [labelDevices setStringValue:@"Devices (Need Restart):"];
    [labelDevices setFrame:labelDevicesRect];
    [scrollDocumentView addSubview:labelDevices];
    
    rowCoord += 1.0;
    NSRect deviceListRect = [self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView];;
    deviceListRect.size.height = 20.0;
    deviceListRect.origin.x -= 2.0;
    
    NSPopUpButton* deviceList = [NSPopUpButton new];
    [deviceList setFrame:deviceListRect];
    [deviceList setTarget:self];
    [deviceList setFont:[NSFont fontWithName:dissectMode.font.fontName size:11]];
    [deviceList setControlSize:NSControlSizeSmall];
    
    for (NSString* name in _deviceNames)
    {
        [deviceList addItemWithTitle:name];
        
        NSMenuItem* item = [deviceList lastItem];
        if (![name isEqualToString:_deviceSelected])
        {
            NSAttributedString* string =
                [[NSAttributedString alloc] initWithString:name
                                                attributes:
                                                    @{
                                                        NSForegroundColorAttributeName :
                                                        [NSColor grayColor]
                                                    }];
            item.attributedTitle = string;
        }
    }
    
    [deviceList selectItemWithTitle:_deviceSelected];
    [deviceList setAction:@selector(deviceChanged:)];
    [scrollDocumentView addSubview:deviceList];
    
    _deviceList = deviceList;
    
    [self updateControls];
}


- (void)showModelPartsChanged:(id)sender
{
    _showModelParts = [_checkModelParts state] == NSOnState;
    [self updateControls];
    
    [_optionUpdateDelegate modelOptionUpdate:self];
}



- (void)showModelFrameRateChanged:(id)sender
{
    _showFrameRate = [_checkFrameRate state] == NSOnState;
    
    [_optionUpdateDelegate modelOptionUpdate:self];
}



- (void)basicMaterializedChanged:(id)sender
{
    _meshOptions.basicMaterialized = [_checkMaterial state] == NSOnState;
    [self updateControls];
    
    [_optionUpdateDelegate modelUpdate:_meshOptions];
}


- (void)texturedChanged:(id)sender
{
    _meshOptions.textured = [_checkTexture state] == NSOnState;
    [self updateControls];
    
    [_optionUpdateDelegate modelUpdate:_meshOptions];
}


- (void)cullChanged:(id)sender
{
    _cullEnabled = [_cull state] == NSOnState;
    
    [_optionUpdateDelegate modelOptionUpdate:self];
}


- (void)combineChanged:(id)sender
{
    _meshOptions.combineShapes = [_combine state] == NSOnState;
    
    [_optionUpdateDelegate modelUpdate:_meshOptions];
}


- (void)fieldOfViewChanged:(id)sender
{
    _fieldOfViewRadian = [_fieldOfView floatValue];
    
    [_optionUpdateDelegate modelOptionUpdate:self];
}


- (void)ambientDensityChanged:(id)sender
{
    _ambientDensity = [_ambientDensitySlider floatValue];
    
    [_optionUpdateDelegate modelOptionUpdate:self];
}


- (void)lightSettingsChanged:(id)sender
{
    _showLightSettings = [_lightSettings state] == NSOnState;
    
    [_optionUpdateDelegate modelOptionUpdate:self];
}

- (void)brdfModeChanged:(id)sender
{
    _meshOptions.physicallyReflection = [_checkBrdfMode state] == NSOnState;
    
    [_optionUpdateDelegate modelUpdate:_meshOptions];
}


- (void)dissectModeChanged:(id)sender
{
    NSInteger index = [_checkDissectMode indexOfSelectedItem];
    switch(index)
    {
        case 0:
            _meshMode = kMeshMode_Normal;
            break;
        case 1:
            _meshMode = kMeshMode_ShadowOccluder;
            break;
        case 2:
            _meshMode = kMeshMode_ShadowPenumbraFactor;
            break;
    }
    
    [_optionUpdateDelegate modelOptionUpdate:self];
}


- (void)transModeChanged:(id)sender
{
    NSInteger index = [_checkTransMode indexOfSelectedItem];
    switch (index)
    {
        case 0:
            _transformMode = kTransformMode_Model;
            break;
        case 1:
            _transformMode = kTransformMode_View;
            break;
            
        default:
            break;
    }
    
    [_optionUpdateDelegate modelOptionUpdate:self];
}


- (void)deviceChanged:(id)sender
{
    _deviceSelected = _deviceList.selectedItem.title;

    [_optionUpdateDelegate modelOptionUpdate:self];
}


- (void)loadAnimation:(id)sender
{
    [_optionUpdateDelegate animationLoad];
}
                                                 
                                                 
- (void)animationUpdate:(id)sender
{
    _animationProgress = _animationSlider.floatValue;
    
    [_optionUpdateDelegate modelOptionUpdate:self];
}


- (void)motionBlurUpdate:(id)sender
{
    [self updateControls];
    
    if (_motionBlurRecord.state == NSOnState && _motionBlurPause.state == NSOffState)
        _motionBlurRecordStatus = kRecord_Start;
    else if (_motionBlurRecord.state == NSOnState)
        _motionBlurRecordStatus = kRecord_Pause;
    else
        _motionBlurRecordStatus = kRecord_Stop;
    
    [_optionUpdateDelegate modelOptionUpdate:self];
}



- (void)rayTracingUpdate:(id)sender
{
    [self updateControls];
    
    if (_rayTracingRecord.state == NSOnState && _rayTracingPause.state == NSOffState)
        _rayTracingRecordStatus = kRecord_Start;
    else if (_rayTracingRecord.state == NSOnState)
        _rayTracingRecordStatus = kRecord_Pause;
    else
        _rayTracingRecordStatus = kRecord_Stop;
    
    [_optionUpdateDelegate modelOptionUpdate:self];
}
                                                 


- (void)updateControls
{
    [_checkTexturePopover setEnabled:[_checkTexture state]];
    
    [_checkMaterial setState:_meshOptions.basicMaterialized ? NSOnState : NSOffState];
    [_checkTexture setState:_meshOptions.textured ? NSOnState : NSOffState];
    [_cull setState:_cullEnabled ? NSOnState : NSOffState];
    [_combine setState:_meshOptions.combineShapes ? NSOnState : NSOffState];
    [_fieldOfView setFloatValue:_fieldOfViewRadian];
    [_ambientDensitySlider setFloatValue:_ambientDensity];
    
    if ([_motionBlurRecord state] == NSOnState)
    {
        [_motionBlurPause setEnabled:YES];
    }
    else
    {
        [_motionBlurPause setEnabled:NO];
        [_motionBlurPause setState:NSOffState];
    }
    
    if ([_rayTracingRecord state] == NSOnState)
    {
        [_rayTracingPause setEnabled:YES];
    }
    else
    {
        [_rayTracingPause setEnabled:NO];
        [_rayTracingPause setState:NSOffState];
    }
}


- (NSRect)buttonLoactionAtRow:(float)row withLeading:(float)leading inView:(NSView*)view
{
    NSRect parentBounds = [view bounds];
    float parentHeight = parentBounds.size.height;
    float parentWidth = parentBounds.size.width;
    
    float buttonHeight = 18;
    float overhead = 12;
    float spacing = 6;
    
    float originalY = parentHeight - overhead - row * spacing - (row + 1) * buttonHeight;
    
    NSRect result = NSMakeRect(overhead + leading, originalY,
                               parentWidth - overhead * 2.0 - leading * 2.0, buttonHeight);
    return result;
}


#pragma mark -- Table Data Source --


- (void)setModelPartAnimations:(NSArray<NuoMeshAnimation*>*)animations
{
    _animations = animations;
    [_animationTable reloadData];
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _animations.count;
}



- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    NSView* result = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    if ([tableColumn.identifier isEqualToString:@"name"])
    {
        NSTableCellView* cell = (NSTableCellView*)result;
        NSTextField* textField = cell.textField;
        textField.stringValue = _animations[row].animationName;
    }
    else
    {
        NSTableCellView* cell = (NSTableCellView*)result;
        NSTextField* textField = cell.textField;
        textField.stringValue = @"";
    }
    
    return result;
}


#pragma mark -- Popover Delegate --


- (CGSize)popoverSheetcontentSize:(NuoPopoverSheet *)sheet
{
    if (sheet == _checkTexturePopover)
        return CGSizeMake(250, 60);
    else
        return CGSizeMake(250, 125);
}

- (NSViewController *)popoverSheetcontentViewController:(NuoPopoverSheet *)sheet
{
    if (sheet == _checkTexturePopover)
    {
        ModelOperationTexturePopover* popover = [[ModelOperationTexturePopover alloc] initWithPopover:sheet.popover
                                                                                      withSourcePanel:self
                                                                                         withDelegate:_optionUpdateDelegate];
        return popover;
    }
    else
    {
        ModelOperationAmbientPopover* popover = [[ModelOperationAmbientPopover alloc] initWithPopover:sheet.popover
                                                                                      withSourcePanel:self
                                                                                         withDelegate:_optionUpdateDelegate];
        return popover;
    }
}


@end
