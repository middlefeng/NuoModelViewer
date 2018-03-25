//
//  ModelPartDimensionPanel.m
//  ModelViewer
//
//  Created by middleware on 2/1/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "ModelPartDimensionPanel.h"
#import "NuoMesh.h"
#import "NuoMeshBounds.h"



@implementation ModelPartDimensionPanel
{
    NSTextField* _dimensionLabel;
    NSTextField* _dimensionValue;
    NSTextField* _centerLabel;
    NSTextField* _centerValue;
    
    // need strong reference since this is a temporary selection set
    //
    NSArray<NuoMesh*>* _selectedMesh;
}



- (NSTextField*)createLabel:(NSString*)text align:(NSTextAlignment)alignment
{
    NSTextField* label = [[NSTextField alloc] init];
    [label setEditable:NO];
    [label setSelectable:NO];
    [label setBordered:NO];
    [label setStringValue:text];
    [label setAlignment:alignment];
    [label setBackgroundColor:[NSColor colorWithWhite:0.0 alpha:0.0]];
    [self addSubview:label];
    return label;
}



- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        [self setWantsLayer:YES];
        
        _dimensionLabel = [self createLabel:@"Dimension:" align:NSTextAlignmentRight];
        _centerLabel = [self createLabel:@"Center:" align:NSTextAlignmentRight];
        _dimensionValue = [self createLabel:@"" align:NSTextAlignmentLeft];
        _centerValue = [self createLabel:@"" align:NSTextAlignmentLeft];
    }
    
    return self;
}



- (void)updateControlsLayout
{
    CGSize viewSize = [self bounds].size;
    
    float margin = 12;
    float labelWidth = 70;
    float entryHeight = 18;
    float lineSpace = 6;
    
    CGRect labelFrame;
    labelFrame.size = CGSizeMake(labelWidth, entryHeight);
    labelFrame.origin = CGPointMake(margin, (entryHeight + lineSpace) + margin);
    
    CGRect fieldFrame;
    fieldFrame.size = CGSizeMake(viewSize.width - 2 - labelWidth, entryHeight);
    fieldFrame.origin = CGPointMake(margin + labelFrame.size.width + 2, labelFrame.origin.y);
    
    [_dimensionLabel setFrame:labelFrame];
    [_dimensionValue setFrame:fieldFrame];
    
    labelFrame.origin.y -= entryHeight + lineSpace;
    fieldFrame.origin.y -= entryHeight + lineSpace;
    
    [_centerLabel setFrame:labelFrame];
    [_centerValue setFrame:fieldFrame];
}



- (void)updateForMesh:(NSArray<NuoMesh*>*)mesh
{
    _selectedMesh = mesh;
    [self updateForSelectedMesh];
}



- (void)updateForSelectedMesh
{
    if (!_selectedMesh)
        return;
    
    NSArray<NuoMesh*>* mesh = _selectedMesh;
    
    NuoBounds bounds = *((NuoBounds*)[mesh[0].boundsLocal boundingBox]);
    for (size_t i = 1; i < mesh.count; ++i)
        bounds = bounds.Union(*((NuoBounds*)[mesh[i].boundsLocal boundingBox]));
    
    NSString* dimensionString = [[NSString alloc] initWithFormat:@"%0.1f, %0.1f, %0.1f",
                                        bounds._span.x, bounds._span.y, bounds._span.z];
    NSString* centerString = [[NSString alloc] initWithFormat:@"%0.1f, %0.1f, %0.1f",
                                        bounds._center.x, bounds._center.y, bounds._center.z];
    
    [_dimensionValue setStringValue:dimensionString];
    [_centerValue setStringValue:centerString];
}



- (void)showIfSelected
{
    if (_selectedMesh)
        self.hidden = NO;
}



@end
