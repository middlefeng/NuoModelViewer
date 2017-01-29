//
//  ModelComponentPanels.m
//  ModelViewer
//
//  Created by middleware on 1/29/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "ModelComponentPanels.h"
#import "ModelPartsPanel.h"
#import "ModelOptionUpdate.h"
#import "NuoMesh.h"




@implementation ModelComponentPanels
{
    ModelPartsPanel* _modelPartsPanel;
}


- (void)containerViewResized
{
    [_modelPartsPanel setFrame:[self modelPartsPanelLocation]];
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



- (void)addPanels
{
    NSRect listRect = [self modelPartsPanelLocation];
    
    _modelPartsPanel = [ModelPartsPanel new];
    _modelPartsPanel.layer.backgroundColor = CGColorCreateGenericGray(0.0, 0.0);
    _modelPartsPanel.layer.borderWidth = 1.0;
    _modelPartsPanel.layer.borderColor = CGColorCreateGenericGray(0.6, 0.5);
    
    [_containerView addSubview:_modelPartsPanel];
    [_modelPartsPanel setFrame:listRect];
    [_modelPartsPanel setHidden:YES];
    [_modelPartsPanel setOptionUpdateDelegate:_modelOptionDelegate];
}



- (void)setMesh:(NSArray<NuoMesh*>*)mesh
{
    [_modelPartsPanel setMesh:mesh];
}



- (void)setHidden:(BOOL)hidden
{
    [_modelPartsPanel setHidden:hidden];
}



@end
