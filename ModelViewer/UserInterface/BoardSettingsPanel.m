//
//  BoardSettingsPanel.m
//  ModelViewer
//
//  Created by middleware on 6/8/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "BoardSettingsPanel.h"



static const float kMarginTop = 20;
static const float kMarginLeft = 20;
static const float kHorizontalSpacing = 12;
static const float kVerticalSpacing = 8;
static const float kLabelWidth = 60;
static const float kLabelHeight = 18;
static const float kFieldWidth = 120;
static const float kFieldHeight = 20;



@implementation BoardSettingsPanel
{
    NSTextField* _labelName;
    NSTextField* _labelWidth;
    NSTextField* _labelHeight;
    
    NSTextField* _name;
    NSTextField* _width;
    NSTextField* _height;
}



- (void)initControls
{
    [super initControls];
    
    _labelName = [self createLabel:@"Name:"];
    _labelWidth = [self createLabel:@"Width:"];
    _labelHeight = [self createLabel:@"Height:"];
    
    _name = [self createField];
    _width = [self createField];
    _height = [self createField];
    
    [_name setStringValue:@"Virtual"];
    
    [self setFrame:CGRectMake(0, 0, 240, 180) display:YES];
}


- (void)layoutControls
{
    [super layoutControls];
    
    NSRect bounds = self.rootView.bounds;
    
    CGFloat verticalPosShift = kLabelHeight + kVerticalSpacing;
    CGFloat verticalPos = bounds.size.height - kMarginTop - kLabelHeight;
    
    NSRect labelNameFrame;
    labelNameFrame.origin.x = kMarginLeft;
    labelNameFrame.origin.y = verticalPos;
    labelNameFrame.size = CGSizeMake(kLabelWidth, kLabelHeight);
    
    _labelName.frame = labelNameFrame;
    
    verticalPos -= verticalPosShift;
    
    NSRect labelWidthFrame;
    labelWidthFrame.origin.x = kMarginLeft;
    labelWidthFrame.origin.y = verticalPos;
    labelWidthFrame.size = CGSizeMake(kLabelWidth, kLabelHeight);
    
    _labelWidth.frame = labelWidthFrame;
    
    verticalPos -= verticalPosShift;
    
    NSRect labelHeightFrame;
    labelHeightFrame.origin.x = kMarginLeft;
    labelHeightFrame.origin.y = verticalPos;
    labelHeightFrame.size = CGSizeMake(kLabelWidth, kLabelHeight);
    
    _labelHeight.frame = labelHeightFrame;
    
    NSRect nameFrame;
    nameFrame.origin.x = labelNameFrame.origin.x + labelNameFrame.size.width + kHorizontalSpacing;
    nameFrame.origin.y = labelNameFrame.origin.y;
    nameFrame.size = CGSizeMake(kFieldWidth, kFieldHeight);
    
    _name.frame = nameFrame;
    
    NSRect widthFrame;
    widthFrame.origin.x = labelWidthFrame.origin.x + labelWidthFrame.size.width + kHorizontalSpacing;
    widthFrame.origin.y = labelWidthFrame.origin.y;
    widthFrame.size = CGSizeMake(kFieldWidth, kFieldHeight);
    
    _width.frame = widthFrame;
    
    NSRect heightFrame;
    heightFrame.origin.x = widthFrame.origin.x;
    heightFrame.origin.y = labelHeightFrame.origin.y;
    heightFrame.size = CGSizeMake(kFieldWidth, kFieldHeight);
    
    _height.frame = heightFrame;
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
    [self.rootView addSubview:label];
    return label;
}



- (NSTextField*)createField
{
    NSTextField* field = [[NSTextField alloc] init];
    [field setEditable:YES];
    [field setSelectable:YES];
    [field setFocusRingType:NSFocusRingTypeNone];
    [field setBezelStyle:NSTextFieldSquareBezel];
    [self.rootView addSubview:field];
    return field;
}


- (CGSize)boardSize
{
    NSString* width = [_width stringValue];
    NSString* height = [_height stringValue];
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    
    CGSize result;
    result.width = [formatter numberFromString:width].floatValue;
    result.height = [formatter numberFromString:height].floatValue;
    
    return result;
}


- (NSString*)boardName
{
    return _name.stringValue;
}


@end
