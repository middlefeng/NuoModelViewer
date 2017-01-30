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

#import "ModelPartsPanel.h"
#import "ModelPartPropPanel.h"




@implementation ModelComponentPanels
{
    ModelPartsPanel* _modelPartsPanel;
    ModelPartPropPanel* _modelPartPropPanel;
}


- (void)containerViewResized
{
    [_modelPartsPanel setFrame:[self modelPartsPanelLocation]];
    [_modelPartPropPanel setFrame:[self modelPartPropPanelLocation]];
    [_modelPartPropPanel updateControlsLayout];
}



- (NSRect)modelPartsPanelLocation
{
    NSRect viewRect = [_containerView frame];
    NSSize listSize = NSMakeSize(225, 315);
    NSSize listMargin = NSMakeSize(15, 25);
    
    NSRect listRect;
    listRect.origin = NSMakePoint(listMargin.width, viewRect.size.height - listSize.height - listMargin.height);
    listRect.size = listSize;
    
    return listRect;
}



- (NSRect)modelPartPropPanelLocation
{
    NSRect viewRect = [self modelPartsPanelLocation];
    viewRect.origin.y -= viewRect.size.height;
    viewRect.origin.y -= 20;
    
    return viewRect;
}


- (void)addPanels
{
    NSRect listRect = [self modelPartsPanelLocation];
    
    _modelPartsPanel = [ModelPartsPanel new];
    _modelPartsPanel.layer.backgroundColor = CGColorCreateGenericGray(0.0, 0.0);
    _modelPartsPanel.layer.borderWidth = 1.0;
    _modelPartsPanel.layer.borderColor = CGColorCreateGenericGray(0.6, 0.5);
    
    [_containerView addSubview:_modelPartsPanel];
    [_modelPartsPanel setFrame:listRect];
    [_modelPartsPanel setOptionUpdateDelegate:_modelOptionDelegate];
    
    _modelPartPropPanel =  [[ModelPartPropPanel alloc] init];
    _modelPartPropPanel.layer.opacity = 0.8f;
    _modelPartPropPanel.layer.backgroundColor = [NSColor colorWithWhite:1.0 alpha:1.0].CGColor;
    
    [_containerView addSubview:_modelPartPropPanel];
    [_modelPartPropPanel setHidden:NO];
    [_modelPartPropPanel setFrame:[self modelPartPropPanelLocation]];
}



- (void)setMesh:(NSArray<NuoMesh*>*)mesh
{
    [_modelPartsPanel setMesh:mesh];
}



- (void)setHidden:(BOOL)hidden
{
    [_modelPartsPanel setHidden:hidden];
    [_modelPartPropPanel setHidden:hidden];
}



@end
