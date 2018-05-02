//
//  ModelSelectionRenderer.m
//  ModelViewer
//
//  Created by Dong on 3/27/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "ModelSelectionRenderer.h"
#import "NuoMesh.h"



@implementation ModelSelectionRenderer


- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    id<MTLRenderCommandEncoder> renderPass = [self retainDefaultEncoder:commandBuffer];
    
    renderPass.label = @"Selection";
    
    [super drawWithCommandBuffer:commandBuffer withInFlightIndex:inFlight];
    [self setSceneBuffersTo:renderPass withInFlightIndex:inFlight];
    
    for (NuoMesh* selectedMesh in _selectedMeshParts)
        [selectedMesh drawMesh:renderPass indexBuffer:inFlight];
    
    [self releaseDefaultEncoder];
}


@end
