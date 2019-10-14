//
//  ModelComponentPanels.m
//  ModelViewer
//
//  Created by middleware on 1/29/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "ModelComponentPanels.h"
#import "ModelOptionUpdate.h"
#import "NuoMesh.h"
#import "ModelPanelUpdate.h"

#import "ModelPartsPanel.h"
#import "ModelPartPropPanel.h"
#import "ModelPartDimensionPanel.h"




@interface ModelComponentPanels() < ModelPanelUpdate >

@end




@implementation ModelComponentPanels
{
    ModelPartsPanel* _modelPartsPanel;
    ModelPartPropPanel* _modelPartPropPanel;
    ModelPartDimensionPanel* _modelPartDimensionPanel;
}


- (void)containerViewResized
{
    [_modelPartsPanel setFrame:[self modelPartsPanelLocation]];
    [_modelPartPropPanel setFrame:[self modelPartPropPanelLocation]];
    [_modelPartDimensionPanel setFrame:[self modelPartDimensionPanelLocation]];
    [_modelPartPropPanel updateControlsLayout];
    [_modelPartDimensionPanel updateControlsLayout];
}



- (NSRect)modelPartsPanelLocation
{
    NSRect viewRect = [_containerView frame];
    NSSize listSize = NSMakeSize(225, 338);
    NSSize listMargin = NSMakeSize(15, 25);
    
    NSRect listRect;
    listRect.origin = NSMakePoint(listMargin.width, viewRect.size.height - listSize.height - listMargin.height);
    listRect.size = listSize;
    
    return listRect;
}



- (NSRect)modelPartPropPanelLocation
{
    NSRect viewRect = [self modelPartsPanelLocation];
    viewRect.size.height = [_modelPartPropPanel preferredHeight];
    viewRect.origin.y -= viewRect.size.height;
    viewRect.origin.y -= 20;
    
    return viewRect;
}


- (NSRect)modelPartDimensionPanelLocation
{
    NSRect viewRect = [self modelPartPropPanelLocation];
    viewRect.size.height = 65;
    viewRect.origin.y -= viewRect.size.height;
    viewRect.origin.y -= 20;
    
    return viewRect;
}


- (void)relayoutViews
{
    [_modelPartPropPanel setFrame:[self modelPartPropPanelLocation]];
    [_modelPartDimensionPanel setFrame:[self modelPartDimensionPanelLocation]];
}


- (void)addPanels
{
    NSRect listRect = [self modelPartsPanelLocation];
    
    CGColorRef background = CGColorCreateGenericGray(0.0, 0.0);
    CGColorRef border = CGColorCreateGenericGray(0.6, 0.5);
    
    _modelPartsPanel = [ModelPartsPanel new];
    _modelPartsPanel.layer.backgroundColor = background;
    _modelPartsPanel.layer.borderWidth = 1.0;
    _modelPartsPanel.layer.borderColor = border;
    
    CGColorRelease(background);
    CGColorRelease(border);
    
    [_containerView addSubview:_modelPartsPanel];
    [_modelPartsPanel setFrame:listRect];
    [_modelPartsPanel setOptionUpdateDelegate:_modelOptionDelegate];
    [_modelPartsPanel setPanelUpdateDelegate:self];
    
    _modelPartPropPanel =  [[ModelPartPropPanel alloc] init];
    _modelPartPropPanel.panelBackground = [NSColor colorNamed:@"Panel_Background"];
    _modelPartPropPanel.layer.opacity = 0.8f;
    
    [_containerView addSubview:_modelPartPropPanel];
    [_modelPartPropPanel setHidden:YES];
    [_modelPartPropPanel setOptionUpdateDelegate:_modelOptionDelegate];
    
    _modelPartDimensionPanel = [[ModelPartDimensionPanel alloc] init];
    _modelPartDimensionPanel.layer.opacity = 0.8f;
    _modelPartDimensionPanel.panelBackground = [NSColor colorNamed:@"Panel_Background"];
    
    [_containerView addSubview:_modelPartDimensionPanel];
    [_modelPartDimensionPanel setHidden:YES];
    
    [self relayoutViews];
}



- (void)setMesh:(NSArray<NuoMesh*>*)mesh
{
    [_modelPartsPanel setMesh:mesh];
    [_modelPartPropPanel setHidden:YES];
    
    [_modelPartDimensionPanel updateForMesh:nil];
    [_modelPartDimensionPanel setHidden:YES];
}



- (void)setHidden:(BOOL)hidden
{
    [_modelPartsPanel setHidden:hidden];
    
    if (hidden)
    {
        [_modelPartPropPanel setHidden:YES];
        [_modelPartDimensionPanel setHidden:YES];
    }
    else
    {
        [_modelPartPropPanel showIfSelected];
        [_modelPartDimensionPanel showIfSelected];
    }
}



- (void)updatePanels
{
    [_modelPartsPanel updateParsPanelWithReload:NO];
    [_modelPartPropPanel updateForSelectedMesh];
    [_modelPartDimensionPanel updateForSelectedMesh];
}




- (void)modelPartSelectionChanged:(NSArray<NuoMesh*>*)selection
{
    if (selection.count == 0)
    {
        [_modelPartPropPanel setHidden:YES];
        [_modelPartDimensionPanel setHidden:YES];
        [_modelPartPropPanel updateForMesh:nil];
        [_modelPartDimensionPanel updateForMesh:nil];
    }
    else
    {
        [_modelPartPropPanel setHidden:NO];
        [_modelPartDimensionPanel setHidden:NO];
        [_modelPartPropPanel updateForMesh:selection];
        [_modelPartDimensionPanel updateForMesh:selection];
    }
    
    [self relayoutViews];
}



@end
