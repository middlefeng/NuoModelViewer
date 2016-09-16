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
@property (nonatomic, strong) NSButton* ignoreTextureAlpha;
@property (nonatomic, strong) NSButton* checkTextureAlpha;
@property (nonatomic, strong) NSButton* checkTextureAlphaSide;

@end



@implementation ModelOperationPanel


- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _textureAlphaType = kNuoModelTextureAlpha_Ignored;
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
    
    NSButton* ignoreTextureAlpha = [NSButton new];
    [ignoreTextureAlpha setTag:kNuoModelTextureAlpha_Ignored];
    [ignoreTextureAlpha setButtonType:NSRadioButton];
    [ignoreTextureAlpha setControlSize:NSControlSizeSmall];
    [ignoreTextureAlpha setTitle:@"Alpha Ignored"];
    [ignoreTextureAlpha setFrame:[self buttonLoactionAtRow:2 withLeading:30]];
    [ignoreTextureAlpha setTarget:self];
    [ignoreTextureAlpha setAction:@selector(textureAlphaTypeChanged:)];
    [ignoreTextureAlpha setEnabled:NO];
    [self addSubview:ignoreTextureAlpha];
    _ignoreTextureAlpha = ignoreTextureAlpha;
    
    NSButton* checkTextureAlpha = [NSButton new];
    [checkTextureAlpha setTag:kNuoModelTextureAlpha_Embedded];
    [checkTextureAlpha setButtonType:NSRadioButton];
    [checkTextureAlpha setControlSize:NSControlSizeSmall];
    [checkTextureAlpha setTitle:@"Alpha Embedded"];
    [checkTextureAlpha setFrame:[self buttonLoactionAtRow:3 withLeading:30]];
    [checkTextureAlpha setTarget:self];
    [checkTextureAlpha setAction:@selector(textureAlphaTypeChanged:)];
    [checkTextureAlpha setEnabled:NO];
    [self addSubview:checkTextureAlpha];
    _checkTextureAlpha = checkTextureAlpha;
    
    NSButton* checkTextureAlphaSide = [NSButton new];
    [checkTextureAlphaSide setTag:kNuoModelTextureAlpha_Sided];
    [checkTextureAlphaSide setButtonType:NSRadioButton];
    [checkTextureAlphaSide setControlSize:NSControlSizeSmall];
    [checkTextureAlphaSide setTitle:@"Alpha in Side File"];
    [checkTextureAlphaSide setFrame:[self buttonLoactionAtRow:4 withLeading:30]];
    [checkTextureAlphaSide setTarget:self];
    [checkTextureAlphaSide setAction:@selector(textureAlphaTypeChanged:)];
    [checkTextureAlphaSide setEnabled:NO];
    [self addSubview:checkTextureAlphaSide];
    _checkTextureAlphaSide = checkTextureAlphaSide;
}


- (void)basicMaterializedChanged:(id)sender
{
    _basicMaterialized = [_checkMaterial state] == NSOnState;
    
    [_optionUpdateDelegate modelOptionUpdate:self];
}


- (void)texturedChanged:(id)sender
{
    _textured = [_checkTexture state] == NSOnState;
    [self updateControls];
    
    [_optionUpdateDelegate modelOptionUpdate:self];
}


- (void)textureAlphaTypeChanged:(id)sender
{
    NSButton* alphaType = (NSButton*)sender;
    _textureAlphaType = (enum NuoModelTextureAlphaType)[alphaType tag];
    
    [_optionUpdateDelegate modelOptionUpdate:self];
}


- (void)updateControls
{
    [_checkTextureAlphaSide setEnabled:[_checkTexture state]];
    [_checkTextureAlpha setEnabled:[_checkTexture state]];
    [_ignoreTextureAlpha setEnabled:[_checkTexture state]];
    
    switch (_textureAlphaType)
    {
        case kNuoModelTextureAlpha_Ignored:
            [_ignoreTextureAlpha setState:NSOnState];
            break;
        case kNuoModelTextureAlpha_Embedded:
            [_checkTextureAlpha setState:NSOnState];
            break;
        case kNuoModelTextureAlpha_Sided:
            [_checkTextureAlphaSide setState:NSOnState];
            
        default:
            break;
    }
}


- (NSRect)buttonLoactionAtRow:(uint)row withLeading:(float)leading
{
    NSRect parentBounds = [self bounds];
    float parentHeight = parentBounds.size.height;
    float parentWidth = parentBounds.size.width;
    
    float buttonHeight = 18;
    float overhead = 8;
    float spacing = 6;
    
    float originalY = parentHeight - overhead - row * spacing - (row + 1) * buttonHeight;
    
    NSRect result = NSMakeRect(overhead + leading, originalY,
                               parentWidth - overhead * 2.0 - leading, buttonHeight);
    return result;
}


@end
