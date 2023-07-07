//
//  ModelPartPropPanel.m
//  ModelViewer
//
//  Created by middleware on 1/29/17.
//  Copyright © 2020 middleware. All rights reserved.
//

#import "ModelPartPropPanel.h"
#import "NuoMesh.h"
#import "NuoBoardMesh.h"
#import "NuoColorPicker.h"
#import "NuoOpenEndSlider.h"

#import "ModelPanelUpdate.h"
#import "ModelOptionUpdate.h"




@implementation ModelPartPropPanel
{
    NSTextField* _nameLabel;
    NSTextField* _nameField;
    
    NSButton* _modelSmoothOption;
    NSButton* _modelCullOption;
    
    NSTextField* _opacityLabel;
    NSSlider* _opacitySlider;
    
    NSTextField* _smoothToleranceLabel;
    NSTextField* _smoothToleranceField;
    
    NSArray<NuoMesh*>* _selectedMeshes;
    
    NSTextField* _diffReflectanceLabel;
    NuoColorPicker* _diffRelectance;
    NSTextField* _specReflectanceLabel;
    NuoColorPicker* _specRelectance;
    
    NuoOpenEndSlider* _specularPowerSlider;
}



- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        [self setWantsLayer:YES];
        
        _nameLabel = [self createLabel:@"Name:" align:NSTextAlignmentRight editable:NO];
        _nameField = [self createLabel:@"" align:NSTextAlignmentLeft editable:NO];
        
        _modelSmoothOption = [self createCheckButton:@"Smooth Conservative"];
        [_modelSmoothOption setAction:@selector(modelPartsChanged:)];
        _modelCullOption = [self createCheckButton:@"Reverse Cull Mode"];
        [_modelCullOption setAction:@selector(modelPartsChanged:)];
        
        _opacityLabel = [self createLabel:@"Opacity:" align:NSTextAlignmentRight editable:NO];
        _opacitySlider = [self createSliderMax:1.0 min:0.0];
        [_opacitySlider setAction:@selector(modelPartsChanged:)];
        
        _smoothToleranceLabel = [self createLabel:@"Smooth:" align:NSTextAlignmentRight editable:NO];
        _smoothToleranceField = [self createLabel:@"Smooth:" align:NSTextAlignmentRight editable:YES];
        [_smoothToleranceField setTarget:self];
        [_smoothToleranceField setAction:@selector(modelPartsChanged:)];
        
        __weak ModelPartPropPanel* panel = self;
        _diffReflectanceLabel = [self createLabel:@"Diffuse Reflectance:" align:NSTextAlignmentRight editable:NO];
        _diffRelectance = [[NuoColorPicker alloc] init];
        _diffRelectance.colorChanged = ^()
        {
            [panel modelDiffuseChanged];
        };
        [self addSubview:_diffRelectance];
        
        _specReflectanceLabel = [self createLabel:@"Specular Reflectance:" align:NSTextAlignmentRight editable:NO];
        _specRelectance = [[NuoColorPicker alloc] init];
        _specRelectance.colorChanged = ^()
        {
            [panel modelSpecularChanged];
        };
        [self addSubview:_specRelectance];
        
        __weak ModelPartPropPanel* selfWeak = self;
        _specularPowerSlider = [[NuoOpenEndSlider alloc] initWithName:@"Specular Power:"];
        [_specularPowerSlider setValueChanged:^
            {
                [selfWeak specularPowerChanged];
            }];
        [self addSubview:_specularPowerSlider];
    }
    
    return self;
}



- (NSTextField*)createLabel:(NSString*)text align:(NSTextAlignment)align editable:(BOOL)editable
{
    NSTextField* label = [[NSTextField alloc] init];
    [label setEditable:editable];
    [label setSelectable:editable];
    
    if (editable)
    {
        [label setFocusRingType:NSFocusRingTypeNone];
        [label setBezelStyle:NSTextFieldSquareBezel];
        [label setControlSize:NSControlSizeMini];
        [label setFont:[NSFont fontWithName:label.font.fontName size:11.0]];
        
        // to show a gray border, one must neither set NO nor YES to the "border", just no touch!
    }
    else
    {
        [label setBordered:NO];
        [label setStringValue:text];
        [label setAlignment:align];
        [label setBackgroundColor:[NSColor colorWithWhite:0.0 alpha:0.0]];
    }
    
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
    return slider;
}


- (NSButton*)createCheckButton:(NSString*)text
{
    NSButton* button = [NSButton new];
    [button setButtonType:NSButtonTypeSwitch];
    [button setTitle:text];
    [button setTarget:self];
    [self addSubview:button];
    return button;
}


- (void)updateControlsLayout
{
    CGSize viewSize = [self bounds].size;
    
    float labelWidth = 60;
    float wideLabelWidth = 150;
    float labelSpace = 2;
    float entryHeight = 18;
    float lineSpace = 6;
    
    CGRect labelFrame;
    labelFrame.size = CGSizeMake(labelWidth, entryHeight);
    labelFrame.origin = CGPointMake(0, [self preferredHeight] - entryHeight - 12);
    [_nameLabel setFrame:labelFrame];
    
    CGRect fieldFrame;
    fieldFrame.size = CGSizeMake(viewSize.width - labelWidth - labelSpace * 2 - 10, entryHeight);
    fieldFrame.origin = CGPointMake(labelWidth + labelSpace, labelFrame.origin.y);
    [_nameField setFrame:fieldFrame];
    
    labelFrame.origin.y -= entryHeight + lineSpace;
    fieldFrame.origin.y -= entryHeight + lineSpace;
    
    [_opacityLabel setFrame:labelFrame];
    [_opacitySlider setFrame:fieldFrame];
    
    labelFrame.origin.y -= entryHeight + lineSpace + 1.0;
    fieldFrame.origin.y -= entryHeight + lineSpace + 1.0;
    
    CGRect editableFieldFrame = fieldFrame;
    editableFieldFrame.origin.x += 3;
    editableFieldFrame.origin.y += 1.0;
    editableFieldFrame.size.width -= 6;
    [_smoothToleranceLabel setFrame:labelFrame];
    [_smoothToleranceField setFrame:editableFieldFrame];
    
    labelFrame.origin.y -= entryHeight + lineSpace;
    
    CGRect checkButtonFrame = labelFrame;
    checkButtonFrame.origin.x = 10;
    checkButtonFrame.size.width = viewSize.width - 20;
    
    [_modelSmoothOption setFrame:checkButtonFrame];
    
    checkButtonFrame.origin.y -= entryHeight + lineSpace;

    [_modelCullOption setFrame:checkButtonFrame];
    
    labelFrame.origin.y = checkButtonFrame.origin.y - (entryHeight + lineSpace + 6.0);
    labelFrame.size.width = wideLabelWidth;
    [_diffReflectanceLabel setFrame:labelFrame];
    
    CGRect colorButtonFrame = labelFrame;
    colorButtonFrame.origin.x += labelFrame.size.width + 15.0;
    colorButtonFrame.size = CGSizeMake(18, 18);
    colorButtonFrame.origin.y -= (colorButtonFrame.size.height - labelFrame.size.height) / 2.0;
    [_diffRelectance setFrame:colorButtonFrame];
    
    labelFrame.origin.y -= (entryHeight + lineSpace);
    labelFrame.size.width = wideLabelWidth;
    [_specReflectanceLabel setFrame:labelFrame];
    
    colorButtonFrame.origin.y = labelFrame.origin.y - (colorButtonFrame.size.height - labelFrame.size.height) / 2.0;
    [_specRelectance setFrame:colorButtonFrame];
    
    float openEndSliderHeight = 45.0;
    labelFrame.origin.y -= (openEndSliderHeight + lineSpace + 2.0);
    labelFrame.size.width = viewSize.width;
    labelFrame.size.height = openEndSliderHeight;
    
    [_specularPowerSlider setFrame:labelFrame];
    [_specularPowerSlider updateLayout];
}



- (void)updateForMesh:(NSArray<NuoMesh*>*)meshes
{
    _selectedMeshes = meshes;
    [self updateForSelectedMesh];
    [self updateControlsLayout];
}


- (void)updateForSelectedMesh
{
    if (!_selectedMeshes)
        return;
    
    NSArray<NuoMesh*>* meshes = _selectedMeshes;
    
    if (meshes.count > 1)
    {
        [_modelCullOption setAllowsMixedState:YES];
        [_modelSmoothOption setAllowsMixedState:YES];
    }
    
    NSString* names = nil;
    NSControlStateValue smoothOption = NSControlStateValueOff;
    NSControlStateValue reverseCullOption = NSControlStateValueOff;

    NSString* smoothToleranceStr = @"0.0";
    CGFloat smoothTolerance = 0.0f;
    
    bool virtualSurface = (meshes.count == 1);
    for (NuoMesh* mesh in meshes)
    {
        if (![mesh isKindOfClass:NuoBoardMesh.class])
            virtualSurface = false;
        
        if (names)
        {
            names = [names stringByAppendingString:@", "];
            names = [names stringByAppendingString:mesh.modelName];
            if (mesh.smoothConservative != (smoothOption == NSControlStateValueOn))
                smoothOption = NSControlStateValueMixed;
            if (mesh.reverseCommonCullMode != (reverseCullOption == NSControlStateValueOn))
                reverseCullOption = NSControlStateValueMixed;
            if (mesh.smoothTolerance != smoothTolerance)
                smoothToleranceStr = @"<multiple values>";
        }
        else
        {
            names = mesh.modelName;
            smoothOption = mesh.smoothConservative ? NSControlStateValueOn : NSControlStateValueOff;
            reverseCullOption = mesh.reverseCommonCullMode ? NSControlStateValueOn : NSControlStateValueOff;
            smoothToleranceStr = [[NSString alloc] initWithFormat:@"%.4f", mesh.smoothTolerance];
            smoothTolerance = mesh.smoothTolerance;
        }
    }
    
    [_nameField setStringValue:names];
    [_smoothToleranceField setStringValue:smoothToleranceStr];
    [_modelSmoothOption setState:smoothOption];
    [_modelCullOption setState:reverseCullOption];
    
    [_opacityLabel setEnabled:meshes[0].hasUnifiedMaterial];
    [_opacitySlider setEnabled:meshes[0].hasUnifiedMaterial];
    
    if (meshes[0].hasUnifiedMaterial)
    {
        [_opacitySlider setFloatValue:meshes[0].unifiedOpacity];
    }
    
    if (virtualSurface)
    {
        NuoBoardMesh* boardMesh = ((NuoBoardMesh*)meshes[0]);
        
        _diffReflectanceLabel.hidden = NO;
        _diffRelectance.hidden = NO;
        _specReflectanceLabel.hidden = NO;
        _specRelectance.hidden = NO;
        _diffRelectance.color = [boardMesh diffuse];
        _specRelectance.color = [boardMesh specular];
        _specularPowerSlider.floatValue = [boardMesh specularPower];
    }
    else
    {
        _diffReflectanceLabel.hidden = YES;
        _diffRelectance.hidden = YES;
        _specReflectanceLabel.hidden = YES;
        _specRelectance.hidden = YES;
    }
    
    _diffRelectance.panelName = [NSString stringWithFormat:@"Diffuse - %@", meshes[0].modelName];
    _specRelectance.panelName = [NSString stringWithFormat:@"Specular - %@", meshes[0].modelName];
}



- (void)modelPartsChanged:(id)sender
{
    if (_selectedMeshes[0].hasUnifiedMaterial)
        _selectedMeshes[0].unifiedOpacity = [_opacitySlider floatValue];
    
    // no logic to reverse to the original mixed state,
    // enforce all-on
    //
    if (_modelCullOption.state == NSControlStateValueMixed)
    {
        _modelCullOption.state = NSControlStateValueOn;
        _modelCullOption.allowsMixedState = NO;
    }
    if (_modelSmoothOption.state == NSControlStateValueMixed)
    {
        _modelSmoothOption.state = NSControlStateValueOn;
        _modelSmoothOption.allowsMixedState = NO;
    }
    
    bool smoothConservative = [_modelSmoothOption state] == NSControlStateValueOn;
    bool reverseCullMode = [_modelCullOption state] == NSControlStateValueOn;
    
    float smoothTolerance = 0.0;
    NSScanner* scanner = [[NSScanner alloc] initWithString:_smoothToleranceField.stringValue];
    [scanner scanFloat:&smoothTolerance];
    bool validSmoothTolerance = [scanner isAtEnd];
    
    for (NuoMesh* mesh in _selectedMeshes)
    {
        mesh.reverseCommonCullMode = reverseCullMode;
        
        // change the smooth at the last because it may clone the vertex buffer
        //
        if (mesh.smoothConservative != smoothConservative)
            [mesh setSmoothConservative:smoothConservative];
        if (validSmoothTolerance && mesh.smoothTolerance != smoothTolerance)
            [mesh smoothWithTolerance:smoothTolerance];
    }

    [_optionUpdateDelegate modelOptionUpdate:0];
}


- (void)modelDiffuseChanged
{
    for (NuoMesh* mesh in _selectedMeshes)
    {
        if (![mesh isKindOfClass:NuoBoardMesh.class])
            continue;
        
        NuoBoardMesh* board = (NuoBoardMesh*)mesh;
        [mesh invalidCachedTransform];
        [board setDiffuse:_diffRelectance.color];
    }
    
    [_optionUpdateDelegate modelOptionUpdate:kUpdateOption_None];
}


- (void)modelSpecularChanged
{
    for (NuoMesh* mesh in _selectedMeshes)
    {
        if (![mesh isKindOfClass:NuoBoardMesh.class])
            continue;
        
        NuoBoardMesh* board = (NuoBoardMesh*)mesh;
        [mesh invalidCachedTransform];
        [board setSpecular:_specRelectance.color];
    }
    
    [_optionUpdateDelegate modelOptionUpdate:kUpdateOption_None];
}


- (void)specularPowerChanged
{
    for (NuoMesh* mesh in _selectedMeshes)
    {
        if (![mesh isKindOfClass:NuoBoardMesh.class])
            continue;
        
        NuoBoardMesh* board = (NuoBoardMesh*)mesh;
        [mesh invalidCachedTransform];
        [board setSpecularPower:_specularPowerSlider.floatValue];
    }
    
    [_optionUpdateDelegate modelOptionUpdate:kUpdateOption_DecreaseQuality];
}


- (void)setSpecularPower:(float)specularPower
{
    [_specularPowerSlider setFloatValue:specularPower];
}


- (void)showIfSelected
{
    if (_selectedMeshes)
        self.hidden = NO;
}


- (CGFloat)preferredHeight
{
    bool virtualSurface = true;
    for (NuoMesh* mesh in _selectedMeshes)
    {
        if (![mesh isKindOfClass:NuoBoardMesh.class])
        {
            virtualSurface = false;
            break;
        }
    }
    
    if (virtualSurface)
        return 245;
    else
        return 140;
}



@end
