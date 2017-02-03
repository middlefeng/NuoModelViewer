//
//  ModelOperationPanel.m
//  ModelViewer
//
//  Created by middleware on 9/15/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "ModelOperationPanel.h"
#import "NuoMeshOptions.h"



@interface ModelOperationPanel()


@property (nonatomic, strong) NSScrollView* rootScroll;

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

@end



@implementation ModelOperationPanel
{
    IBOutlet NSScrollView* _animationScroll;
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
    NSView* scrollDocumentView = [[NSView alloc] init];
    
    _rootScroll = [[NSScrollView alloc] init];
    _rootScroll.documentView = scrollDocumentView;
    _rootScroll.hasVerticalScroller = YES;
    
    CGSize viewSize = [self bounds].size;
    CGRect rootViewFrame;
    rootViewFrame.origin.x = 0.0;
    rootViewFrame.origin.y = 0.0;
    rootViewFrame.size.width = viewSize.width;
    rootViewFrame.size.height = viewSize.height;
    
    CGRect docViewFrame = CGRectMake(0, 0, 0, 0);
    docViewFrame.size = rootViewFrame.size;
    docViewFrame.size.height += 200.0;
    
    _rootScroll.frame = rootViewFrame;
    scrollDocumentView.frame = docViewFrame;
    
    float rowCoord = 0.0;
    
    NSButton* checkModelParts = [NSButton new];
    [checkModelParts setButtonType:NSSwitchButton];
    [checkModelParts setTitle:@"Show Model Parts"];
    [checkModelParts setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0]];
    [checkModelParts setTarget:self];
    [checkModelParts setAction:@selector(showModelPartsChanged:)];
    [scrollDocumentView addSubview:checkModelParts];
    _checkModelParts = checkModelParts;
    
    rowCoord += 1.2;
    
    NSButton* checkMaterial = [NSButton new];
    [checkMaterial setButtonType:NSSwitchButton];
    [checkMaterial setTitle:@"Basic Material"];
    [checkMaterial setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0]];
    [checkMaterial setTarget:self];
    [checkMaterial setAction:@selector(basicMaterializedChanged:)];
    [scrollDocumentView addSubview:checkMaterial];
    _checkMaterial = checkMaterial;
    
    rowCoord += 1;
    
    NSButton* checkTexture = [NSButton new];
    [checkTexture setButtonType:NSSwitchButton];
    [checkTexture setTitle:@"Texture"];
    [checkTexture setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0]];
    [checkTexture setTarget:self];
    [checkTexture setAction:@selector(texturedChanged:)];
    [scrollDocumentView addSubview:checkTexture];
    _checkTexture = checkTexture;
    
    rowCoord += 1;
    
    NSButton* checkTextureEmbedTrans = [NSButton new];
    [checkTextureEmbedTrans setButtonType:NSSwitchButton];
    [checkTextureEmbedTrans setTitle:@"Texture Alpha as Transparency"];
    [checkTextureEmbedTrans setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0]];
    [checkTextureEmbedTrans setTarget:self];
    [checkTextureEmbedTrans setAction:@selector(textureEmbedTransChanged:)];
    [scrollDocumentView addSubview:checkTextureEmbedTrans];
    _checkTextureEmbedTrans = checkTextureEmbedTrans;
    
    rowCoord += 1;
    
    NSButton* checkTextureBump = [NSButton new];
    [checkTextureBump setButtonType:NSSwitchButton];
    [checkTextureBump setTitle:@"Texture Bump"];
    [checkTextureBump setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0]];
    [checkTextureBump setTarget:self];
    [checkTextureBump setAction:@selector(textureBumpChanged:)];
    [scrollDocumentView addSubview:checkTextureBump];
    _checkTextureBump = checkTextureBump;
    
    rowCoord += 1.2;
    
    NSButton* cull = [NSButton new];
    [cull setButtonType:NSSwitchButton];
    [cull setTitle:@"Enable Culling"];
    [cull setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0]];
    [cull setTarget:self];
    [cull setAction:@selector(cullChanged:)];
    [scrollDocumentView addSubview:cull];
    _cull = cull;
    
    rowCoord += 1;
    
    NSButton* combine = [NSButton new];
    [combine setButtonType:NSSwitchButton];
    [combine setTitle:@"Combine Shapes by Material"];
    [combine setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0]];
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
    [labelFOV setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0]];
    [scrollDocumentView addSubview:labelFOV];
    
    rowCoord += 0.8;
    
    NSSlider* fieldOfView = [NSSlider new];
    [fieldOfView setFrame:[self buttonLoactionAtRow:rowCoord withLeading:6]];
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
    [labelambientDensity setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0]];
    [scrollDocumentView addSubview:labelambientDensity];
    
    rowCoord += 0.9;
    
    NSSlider* ambientDensity = [NSSlider new];
    [ambientDensity setFrame:[self buttonLoactionAtRow:rowCoord withLeading:6]];
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
    [lightSettings setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0]];
    [lightSettings setTarget:self];
    [lightSettings setAction:@selector(lightSettingsChanged:)];
    [scrollDocumentView addSubview:lightSettings];
    _lightSettings = lightSettings;
    
    rowCoord += 1.8;
    
    NSTextField* labelAnimation = [NSTextField new];
    [labelAnimation setEditable:NO];
    [labelAnimation setSelectable:NO];
    [labelAnimation setBordered:NO];
    [labelAnimation setStringValue:@"Animations:"];
    [labelAnimation setFrame:[self buttonLoactionAtRow:rowCoord withLeading:0]];
    [scrollDocumentView addSubview:labelAnimation];
    
    [[NSBundle mainBundle] loadNibNamed:@"ModelPartsAnimations" owner:self topLevelObjects:nil];
    
    rowCoord += 1.2;
    
    NSRect animationRect = [self buttonLoactionAtRow:rowCoord withLeading:0];
    animationRect.size.height = 90;
    animationRect.origin.y -= 70;
    NSView* animationRoot = [[NSView alloc] init];
    [animationRoot setWantsLayer:YES];
    animationRoot.layer = [CALayer new];
    animationRoot.frame = animationRect;
    animationRoot.layer.borderWidth = 1.0;
    animationRoot.layer.borderColor = CGColorCreateGenericGray(0.6, 0.5);
    [_animationScroll setFrame:animationRoot.bounds];
    [animationRoot addSubview:_animationScroll];
    [scrollDocumentView addSubview:animationRoot];
    
    [self addSubview:_rootScroll];
    [_rootScroll.contentView scrollToPoint:CGPointMake(0, docViewFrame.size.height)];
    
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


- (NSRect)buttonLoactionAtRow:(float)row withLeading:(float)leading
{
    NSRect parentBounds = [_rootScroll.documentView bounds];
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


@end
