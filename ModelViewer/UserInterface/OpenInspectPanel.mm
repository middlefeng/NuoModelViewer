//
//  OpenInspectPanel.m
//  ModelViewer
//
//  Created by middleware on 9/8/18.
//  Copyright © 2018 middleware. All rights reserved.
//



#import "OpenInspectPanel.h"
#import "NuoInspectableMaster.h"



static const float kMarginTop = 15;
static const float kMarginLeft = 12;
static const float kLabelWidth = 120;
static const float kLabelHeight = 18;
static const float kPopupHeight = 24;



@implementation OpenInspectPanel
{
    NSTextField* _label;
    NSPopUpButton* _inspectList;
}


- (void)initControls
{
    [super initControls];
    
    _label = [self createLabel:@"Inspect Point:"];
    
    _inspectList = [NSPopUpButton new];
    [self.contentView addSubview:_inspectList];
    
    NSDictionary<NSString*, NuoInspectable*>* inspectables = [NuoInspectableMaster inspectableList];
    NSArray<NSString*>* inspectKeys = [inspectables allKeys];
    inspectKeys = [inspectKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    for (NSString* inspectable in inspectKeys)
        [_inspectList addItemWithTitle:inspectables[inspectable].displayTitle];
    
    [_inspectList setFont:[NSFont fontWithName:_inspectList.font.fontName size:11]];
    [_inspectList setControlSize:NSControlSizeSmall];
    
    [self setFrame:CGRectMake(0, 0, 200, 140) display:YES];
}


- (void)layoutControls
{
    [super layoutControls];
    
    NSRect bounds = self.rootView.bounds;
    
    NSRect labelFrame;
    labelFrame.origin.x = kMarginLeft + 4.0;
    labelFrame.origin.y = bounds.size.height - kMarginTop - kLabelHeight;
    labelFrame.size = CGSizeMake(kLabelWidth, kLabelHeight);
    
    _label.frame = labelFrame;
    
    CGRect popupFrame = labelFrame;
    popupFrame.origin.x = kMarginLeft;
    popupFrame.origin.y -= 30;
    popupFrame.size.width = bounds.size.width - kMarginLeft * 2.0;
    popupFrame.size.height = kPopupHeight;
    
    _inspectList.frame = popupFrame;
}


- (NSTextField*)createLabel:(NSString*)text
{
    NSTextField* label = [[NSTextField alloc] init];
    [label setEditable:NO];
    [label setSelectable:NO];
    [label setBordered:NO];
    [label setBackgroundColor:[NSColor colorWithWhite:0.0 alpha:0.0]];
    [label setStringValue:text];
    [label setAlignment:NSTextAlignmentLeft];
    [self.rootView addSubview:label];
    return label;
}


- (NSString*)inspectSelected
{
    NSDictionary* inspectables = [NuoInspectableMaster inspectableList];
    NSArray<NSString*>* inspectKeys = [inspectables allKeys];
    inspectKeys = [inspectKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    const NSInteger selected = [_inspectList indexOfSelectedItem];
    return inspectKeys[selected];
}


@end
