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

@property (nonatomic, strong) NSButton* checkMaterial;
@property (nonatomic, strong) NSButton* checkTexture;
@property (nonatomic, strong) NSButton* checkTextureEmbedTrans;
@property (nonatomic, strong) NSButton* checkTextureBump;

@property (nonatomic, strong) NSButton* cull;
@property (nonatomic, strong) NSButton* combine;

@property (nonatomic, assign) NSSlider* fieldOfView;

@property (nonatomic, strong) NSButton* lightSettings;

@end



@implementation ModelOperationPanel


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
    }
    
    return self;
}


- (void)addCheckbox
{
    NSButton* checkMaterial = [NSButton new];
    [checkMaterial setButtonType:NSSwitchButton];
    [checkMaterial setTitle:@"Basic Material"];
    [checkMaterial setFrame:[self buttonLoactionAtRow:0 withLeading:0]];
    [checkMaterial setTarget:self];
    [checkMaterial setAction:@selector(basicMaterializedChanged:)];
    [self addSubview:checkMaterial];
    _checkMaterial = checkMaterial;
    
    NSButton* checkTexture = [NSButton new];
    [checkTexture setButtonType:NSSwitchButton];
    [checkTexture setTitle:@"Texture"];
    [checkTexture setFrame:[self buttonLoactionAtRow:1 withLeading:0]];
    [checkTexture setTarget:self];
    [checkTexture setAction:@selector(texturedChanged:)];
    [self addSubview:checkTexture];
    _checkTexture = checkTexture;
    
    NSButton* checkTextureEmbedTrans = [NSButton new];
    [checkTextureEmbedTrans setButtonType:NSSwitchButton];
    [checkTextureEmbedTrans setTitle:@"Texture Alpha as Transparency"];
    [checkTextureEmbedTrans setFrame:[self buttonLoactionAtRow:2 withLeading:0]];
    [checkTextureEmbedTrans setTarget:self];
    [checkTextureEmbedTrans setAction:@selector(textureEmbedTransChanged:)];
    [checkTextureEmbedTrans setEnabled:NO];
    [self addSubview:checkTextureEmbedTrans];
    _checkTextureEmbedTrans = checkTextureEmbedTrans;
    
    NSButton* checkTextureBump = [NSButton new];
    [checkTextureBump setButtonType:NSSwitchButton];
    [checkTextureBump setTitle:@"Texture Bump"];
    [checkTextureBump setFrame:[self buttonLoactionAtRow:3 withLeading:0]];
    [checkTextureBump setTarget:self];
    [checkTextureBump setAction:@selector(textureBumpChanged:)];
    [checkTextureBump setEnabled:NO];
    [self addSubview:checkTextureBump];
    _checkTextureBump = checkTextureBump;
    
    NSButton* cull = [NSButton new];
    [cull setButtonType:NSSwitchButton];
    [cull setTitle:@"Enable Culling"];
    [cull setFrame:[self buttonLoactionAtRow:4.2 withLeading:0]];
    [cull setTarget:self];
    [cull setAction:@selector(cullChanged:)];
    [cull setState:NSOnState];
    [self addSubview:cull];
    _cull = cull;
    
    NSButton* combine = [NSButton new];
    [combine setButtonType:NSSwitchButton];
    [combine setTitle:@"Combine Shapes by Material"];
    [combine setFrame:[self buttonLoactionAtRow:5.2 withLeading:0]];
    [combine setTarget:self];
    [combine setAction:@selector(combineChanged:)];
    [combine setState:NSOnState];
    [self addSubview:combine];
    _combine = combine;
    
    NSTextField* labelFOV = [NSTextField new];
    [labelFOV setEditable:NO];
    [labelFOV setSelectable:NO];
    [labelFOV setBordered:NO];
    [labelFOV setStringValue:@"Field of View:"];
    [labelFOV setFrame:[self buttonLoactionAtRow:6.4 withLeading:0]];
    [self addSubview:labelFOV];
    
    NSSlider* fieldOfView = [NSSlider new];
    [fieldOfView setFrame:[self buttonLoactionAtRow:7.2 withLeading:6]];
    [fieldOfView setMaxValue:_fieldOfViewRadian];
    [fieldOfView setMinValue:1e-6];
    [fieldOfView setFloatValue:_fieldOfViewRadian];
    [fieldOfView setTarget:self];
    [fieldOfView setAction:@selector(fieldOfViewChanged:)];
    [self addSubview:fieldOfView];
    _fieldOfView = fieldOfView;
    
    NSButton* lightSettings = [NSButton new];
    [lightSettings setButtonType:NSSwitchButton];
    [lightSettings setTitle:@"Light Settings"];
    [lightSettings setFrame:[self buttonLoactionAtRow:8.6 withLeading:0]];
    [lightSettings setTarget:self];
    [lightSettings setAction:@selector(lightSettingsChanged:)];
    [lightSettings setState:NSOffState];
    [self addSubview:lightSettings];
    _lightSettings = lightSettings;
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


- (void)lightSettingsChanged:(id)sender
{
    _showLightSettings = [_lightSettings state] == NSOnState;
    
    [_optionUpdateDelegate modelOptionUpdate:self];
}


- (void)updateControls
{
    [_checkTextureEmbedTrans setEnabled:[_checkTexture state]];
    [_checkTextureBump setEnabled:[_checkTexture state]];
}


- (NSRect)buttonLoactionAtRow:(float)row withLeading:(float)leading
{
    NSRect parentBounds = [self bounds];
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
