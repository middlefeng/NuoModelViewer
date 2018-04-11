//
//  ModelPartPropPanel.m
//  ModelViewer
//
//  Created by middleware on 1/29/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "ModelPartPropPanel.h"
#import "NuoMesh.h"

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
}



- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        [self setWantsLayer:YES];
        
        _nameLabel = [self createLabel:@"Name:" align:NSTextAlignmentRight editable:NO];
        _nameField = [self createLabel:@"" align:NSTextAlignmentLeft editable:NO];
        
        _modelSmoothOption = [self createCheckButton:@"Smooth conservative"];
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
    [button setButtonType:NSSwitchButton];
    [button setTitle:text];
    [button setTarget:self];
    [self addSubview:button];
    return button;
}


- (void)updateControlsLayout
{
    CGSize viewSize = [self bounds].size;
    
    float labelWidth = 60;
    float labelSpace = 2;
    float entryHeight = 18;
    float lineSpace = 6;
    
    CGRect labelFrame;
    labelFrame.size = CGSizeMake(labelWidth, entryHeight);
    labelFrame.origin = CGPointMake(0, (entryHeight + lineSpace) * 4 + 15);
    [_nameLabel setFrame:labelFrame];
    
    CGRect fieldFrame;
    fieldFrame.size = CGSizeMake(viewSize.width - labelWidth - labelSpace * 2 - 10, entryHeight);
    fieldFrame.origin = CGPointMake(labelWidth + labelSpace, (entryHeight + lineSpace) * 4 + 15);
    [_nameField setFrame:fieldFrame];
    
    labelFrame.origin.y -= entryHeight + lineSpace;
    fieldFrame.origin.y -= entryHeight + lineSpace;
    
    [_opacityLabel setFrame:labelFrame];
    [_opacitySlider setFrame:fieldFrame];
    
    labelFrame.origin.y -= entryHeight + lineSpace + 1.0;
    fieldFrame.origin.y -= entryHeight + lineSpace + 1.0;
    
    CGRect editableFieldFrame = fieldFrame;
    editableFieldFrame.origin.x += 3;
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
}



- (void)updateForMesh:(NSArray<NuoMesh*>*)meshes
{
    _selectedMeshes = meshes;
    [self updateForSelectedMesh];
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
    
    NSString* names = @"";
#if METAL_2
    NSControlStateValue smoothOption = NSOffState;
    NSControlStateValue reverseCullOption = NSOffState;
#else
    NSInteger smoothOption = NSOffState;
    NSInteger reverseCullOption = NSOffState;
#endif
    NSString* smoothToleranceStr = @"0.0";
    CGFloat smoothTolerance = 0.0f;
    
    for (NuoMesh* mesh in meshes)
    {
        if (names)
        {
            names = [names stringByAppendingString:@", "];
            names = [names stringByAppendingString:mesh.modelName];
            if (mesh.smoothConservative != (smoothOption == NSOnState))
                smoothOption = NSMixedState;
            if (mesh.reverseCommonCullMode != (reverseCullOption == NSOnState))
                reverseCullOption = NSMixedState;
            if (mesh.smoothTolerance != smoothTolerance)
                smoothToleranceStr = @"<multiple values>";
        }
        else
        {
            names = mesh.modelName;
            smoothOption = mesh.smoothConservative ? NSOnState : NSOffState;
            reverseCullOption = mesh.reverseCommonCullMode ? NSOnState : NSOffState;
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
}



- (void)modelPartsChanged:(id)sender
{
    if (_selectedMeshes[0].hasUnifiedMaterial)
        _selectedMeshes[0].unifiedOpacity = [_opacitySlider floatValue];
    
    // no logic to reverse to the original mixed state,
    // enforce all-on
    //
    if (_modelCullOption.state == NSMixedState)
    {
        _modelCullOption.state = NSOnState;
        _modelCullOption.allowsMixedState = NO;
    }
    if (_modelSmoothOption.state == NSMixedState)
    {
        _modelSmoothOption.state = NSOnState;
        _modelSmoothOption.allowsMixedState = NO;
    }
    
    bool smoothConservative = [_modelSmoothOption state] == NSOnState;
    bool reverseCullMode = [_modelCullOption state] == NSOnState;
    
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

    [_optionUpdateDelegate modelOptionUpdate:nil];
}


- (void)showIfSelected
{
    if (_selectedMeshes)
        self.hidden = NO;
}



@end
