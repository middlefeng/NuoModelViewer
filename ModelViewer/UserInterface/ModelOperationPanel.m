//
//  ModelOperationPanel.m
//  ModelViewer
//
//  Created by middleware on 9/15/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "ModelOperationPanel.h"




@interface ModelOperationPanel()

@property (nonatomic, strong) NSButton* checkMaterial;
@property (nonatomic, strong) NSButton* checkTexture;
@property (nonatomic, strong) NSButton* checkTextureEmbedTrans;

@property (nonatomic, strong) NSButton* cull;
@property (nonatomic, strong) NSButton* combine;

@end



@implementation ModelOperationPanel


- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _cullEnabled = YES;
        _combineShapes = YES;
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
    
    NSButton* cull = [NSButton new];
    [cull setButtonType:NSSwitchButton];
    [cull setTitle:@"Enable Culling"];
    [cull setFrame:[self buttonLoactionAtRow:3.2 withLeading:0]];
    [cull setTarget:self];
    [cull setAction:@selector(cullChanged:)];
    [cull setState:NSOnState];
    [self addSubview:cull];
    _cull = cull;
    
    NSButton* combine = [NSButton new];
    [combine setButtonType:NSSwitchButton];
    [combine setTitle:@"Combine Shapes by Material"];
    [combine setFrame:[self buttonLoactionAtRow:4.2 withLeading:0]];
    [combine setTarget:self];
    [combine setAction:@selector(combineChanged:)];
    [combine setState:NSOnState];
    [self addSubview:combine];
    _combine = combine;
}


- (void)basicMaterializedChanged:(id)sender
{
    _basicMaterialized = [_checkMaterial state] == NSOnState;
    [self updateControls];
    
    [_optionUpdateDelegate modelOptionUpdate:self];
}


- (void)texturedChanged:(id)sender
{
    _textured = [_checkTexture state] == NSOnState;
    [self updateControls];
    
    [_optionUpdateDelegate modelOptionUpdate:self];
}


- (void)textureEmbedTransChanged:(id)sender
{
    _textureEmbeddingMaterialTransparency = [_checkTextureEmbedTrans state] == NSOnState;
    
    [_optionUpdateDelegate modelOptionUpdate:self];
}


- (void)cullChanged:(id)sender
{
    _cullEnabled = [_cull state] == NSOnState;
    
    [_optionUpdateDelegate modelOptionUpdate:self];
}


- (void)combineChanged:(id)sender
{
    _combineShapes = [_combine state] == NSOnState;
    
    [_optionUpdateDelegate modelOptionUpdate:self];
}


- (void)updateControls
{
    [_checkTextureEmbedTrans setEnabled:[_checkTexture state]];
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
                               parentWidth - overhead * 2.0 - leading, buttonHeight);
    return result;
}


@end
