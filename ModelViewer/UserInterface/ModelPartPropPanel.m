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
}



- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        [self setWantsLayer:YES];
        
        _nameLabel = [self createLabel:@"Name:" align:NSTextAlignmentRight];
        _nameField = [self createLabel:@"" align:NSTextAlignmentLeft];
        
        _modelSmoothOption = [self createCheckButton:@"Smooth conservative"];
        
        [self addSubview:_nameLabel];
        [self addSubview:_nameField];
        [self addSubview:_modelSmoothOption];
    }
    
    return self;
}



- (NSTextField*)createLabel:(NSString*)text align:(NSTextAlignment)align
{
    NSTextField* label = [[NSTextField alloc] init];
    [label setEditable:NO];
    [label setSelectable:NO];
    [label setBordered:NO];
    [label setBackgroundColor:[NSColor colorWithWhite:0.0 alpha:0.0]];
    [label setStringValue:text];
    [label setAlignment:align];
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
    [self addSubview:button];
    return button;
}


- (void)updateControlsLayout
{
    CGSize viewSize = [self bounds].size;
    
    float labelWidth = 70;
    float labelSpace = 2;
    float entryHeight = 18;
    float lineSpace = 6;
    
    CGRect labelFrame;
    labelFrame.size = CGSizeMake(labelWidth, entryHeight);
    labelFrame.origin = CGPointMake(0, (entryHeight + lineSpace) * 3 + 5);
    [_nameLabel setFrame:labelFrame];
    
    CGRect fieldFrame;
    fieldFrame.size = CGSizeMake(viewSize.width - labelWidth - labelSpace * 2, entryHeight);
    fieldFrame.origin = CGPointMake(labelWidth + labelSpace, (entryHeight + lineSpace) * 3 + 5);
    [_nameField setFrame:fieldFrame];
    
    labelFrame.origin.y -= entryHeight + lineSpace;
    fieldFrame.origin.y -= entryHeight + lineSpace;
    
    CGRect checkButtonFrame = labelFrame;
    checkButtonFrame.origin.x = 10;
    checkButtonFrame.size.width = viewSize.width - 20;
    [_modelSmoothOption setFrame:checkButtonFrame];
}



- (void)updateForMesh:(NuoMesh*)mesh
{
    [_nameField setStringValue:mesh.modelName];
}



- (void)modelPartsChanged:(id)sender
{
    
}



@end
