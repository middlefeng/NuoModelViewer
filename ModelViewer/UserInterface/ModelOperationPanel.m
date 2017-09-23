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


@interface ModelOperationPanel() < NSTableViewDataSource, NSTableViewDelegate >


@property (nonatomic, strong) NSButton* checkModelParts;

@property (nonatomic, strong) NSButton* checkMaterial;
@property (nonatomic, strong) NSButton* checkTexture;
@property (nonatomic, strong) NSButton* checkTextureEmbedTrans;
@property (nonatomic, strong) NSButton* checkTextureBump;

@property (nonatomic, strong) NSButton* cull;
@property (nonatomic, strong) NSButton* combine;

@property (nonatomic, assign) NSSlider* fieldOfView;

@property (nonatomic, strong) NSSlider* ambientDensitySlider;
@property (nonatomic, strong) NSButton* lightSettings;
@property (nonatomic, strong) NSButton* checkBrdfMode;
@property (nonatomic, strong) NSPopUpButton* checkDissectMode;
@property (nonatomic, strong) NSPopUpButton* checkTransMode;

@property (nonatomic, strong) NSSlider* animationSlider;

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
        
        _cullEnabled = YES;
        
        _fieldOfViewRadian = (2 * M_PI) / 8;
        _showLightSettings = NO;
        _ambientDensity = 0.28;
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
    docViewFrame.size.height += 175.0;
    
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
    
    rowCoord += 1.2;
    
    NSButton* checkMaterial = [NSButton new];
    [checkMaterial setButtonType:NSSwitchButton];
    [checkMaterial setTitle:@"Basic Material"];
    [checkMaterial setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView]];
    [checkMaterial setTarget:self];
    [checkMaterial setAction:@selector(basicMaterializedChanged:)];
    [scrollDocumentView addSubview:checkMaterial];
    _checkMaterial = checkMaterial;
    
    rowCoord += 1;
    
    NSButton* checkTexture = [NSButton new];
    [checkTexture setButtonType:NSSwitchButton];
    [checkTexture setTitle:@"Texture"];
    [checkTexture setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView]];
    [checkTexture setTarget:self];
    [checkTexture setAction:@selector(texturedChanged:)];
    [scrollDocumentView addSubview:checkTexture];
    _checkTexture = checkTexture;
    
    rowCoord += 1;
    
    NSButton* checkTextureEmbedTrans = [NSButton new];
    [checkTextureEmbedTrans setButtonType:NSSwitchButton];
    [checkTextureEmbedTrans setTitle:@"Texture Alpha as Transparency"];
    [checkTextureEmbedTrans setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView]];
    [checkTextureEmbedTrans setTarget:self];
    [checkTextureEmbedTrans setAction:@selector(textureEmbedTransChanged:)];
    [scrollDocumentView addSubview:checkTextureEmbedTrans];
    _checkTextureEmbedTrans = checkTextureEmbedTrans;
    
    rowCoord += 1;
    
    NSButton* checkTextureBump = [NSButton new];
    [checkTextureBump setButtonType:NSSwitchButton];
    [checkTextureBump setTitle:@"Texture Bump"];
    [checkTextureBump setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView]];
    [checkTextureBump setTarget:self];
    [checkTextureBump setAction:@selector(textureBumpChanged:)];
    [scrollDocumentView addSubview:checkTextureBump];
    _checkTextureBump = checkTextureBump;
    
    rowCoord += 1.2;
    
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
    
    rowCoord += 0.8;
    
    NSSlider* fieldOfView = [NSSlider new];
    [fieldOfView setFrame:[self buttonLoactionAtRow:rowCoord withLeading:6 inView:scrollDocumentView]];
    [fieldOfView setMaxValue:_fieldOfViewRadian];
    [fieldOfView setMinValue:1e-6];
    [fieldOfView setTarget:self];
    [fieldOfView setAction:@selector(fieldOfViewChanged:)];
    [scrollDocumentView addSubview:fieldOfView];
    _fieldOfView = fieldOfView;
    
    rowCoord += 1.0;
    
    NSTextField* labelambientDensity = [NSTextField new];
    [labelambientDensity setEditable:NO];
    [labelambientDensity setSelectable:NO];
    [labelambientDensity setBordered:NO];
    [labelambientDensity setStringValue:@"Ambient Density:"];
    [labelambientDensity setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView]];
    [scrollDocumentView addSubview:labelambientDensity];
    
    rowCoord += 0.9;
    
    NSSlider* ambientDensity = [NSSlider new];
    [ambientDensity setFrame:[self buttonLoactionAtRow:rowCoord withLeading:6 inView:scrollDocumentView]];
    [ambientDensity setMaxValue:2.0];
    [ambientDensity setMinValue:0];
    [ambientDensity setTarget:self];
    [ambientDensity setAction:@selector(ambientDensityChanged:)];
    [scrollDocumentView addSubview:ambientDensity];
    _ambientDensitySlider = ambientDensity;
    
    rowCoord += 1.0;
    
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
    
    rowCoord += 0.5;
    
    NSImageView* imageView = [NSImageView new];
    imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    imageView.image = [NSImage imageNamed:@"ArrowDown"];
    imageView.hidden = NO;
    NSRect imageViewFrame = [self buttonLoactionAtRow:rowCoord withLeading:0 inView:scrollDocumentView];
    imageViewFrame.size.height = 6;
    imageView.frame = imageViewFrame;
    imageView.alphaValue = 0.6;
    [scrollDocumentView addSubview:imageView];
    
    rowCoord += 1.5;
    
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
    
    rowCoord += 1.5;
    
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
    
    [self updateControls];
}


-(void)showModelPartsChanged:(id)sender
{
    _showModelParts = [_checkModelParts state] == NSOnState;
    [self updateControls];
    
    [_optionUpdateDelegate modelOptionUpdate:self];
}



- (void)basicMaterializedChanged:(id)sender
{
    _meshOptions.basicMaterialized = [_checkMaterial state] == NSOnState;
    [self updateControls];
    
    [_optionUpdateDelegate modelUpdate:self];
}


- (void)texturedChanged:(id)sender
{
    _meshOptions.textured = [_checkTexture state] == NSOnState;
    [self updateControls];
    
    [_optionUpdateDelegate modelUpdate:self];
}


- (void)textureEmbedTransChanged:(id)sender
{
    _meshOptions.textureEmbeddingMaterialTransparency = [_checkTextureEmbedTrans state] == NSOnState;
    
    [_optionUpdateDelegate modelUpdate:self];
}


- (void)textureBumpChanged:(id)sender
{
    _meshOptions.texturedBump = [_checkTextureBump state] == NSOnState;
    
    [_optionUpdateDelegate modelUpdate:self];
}


- (void)cullChanged:(id)sender
{
    _cullEnabled = [_cull state] == NSOnState;
    
    [_optionUpdateDelegate modelOptionUpdate:self];
}


- (void)combineChanged:(id)sender
{
    _meshOptions.combineShapes = [_combine state] == NSOnState;
    
    [_optionUpdateDelegate modelUpdate:self];
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
    
    [_optionUpdateDelegate modelUpdate:self];
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


- (void)loadAnimation:(id)sender
{
    [_optionUpdateDelegate animationLoad];
}
                                                 
                                                 
- (void)animationUpdate:(id)sender
{
    _animationProgress = _animationSlider.floatValue;
    
    [_optionUpdateDelegate modelOptionUpdate:self];
}
                                                 


- (void)updateControls
{
    [_checkTextureEmbedTrans setEnabled:[_checkTexture state]];
    [_checkTextureBump setEnabled:[_checkTexture state]];
    
    [_checkMaterial setState:_meshOptions.basicMaterialized ? NSOnState : NSOffState];
    [_checkTexture setState:_meshOptions.textured ? NSOnState : NSOffState];
    [_checkTextureEmbedTrans setState:_meshOptions.textureEmbeddingMaterialTransparency ? NSOnState : NSOffState];
    [_checkTextureBump setState:_meshOptions.texturedBump ? NSOnState : NSOffState];
    [_cull setState:_cullEnabled ? NSOnState : NSOffState];
    [_combine setState:_meshOptions.combineShapes ? NSOnState : NSOffState];
    [_fieldOfView setFloatValue:_fieldOfViewRadian];
    [_ambientDensitySlider setFloatValue:_ambientDensity];
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


#pragma mark - Table Data Source


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


@end
