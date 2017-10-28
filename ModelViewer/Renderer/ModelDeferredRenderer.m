//
//  ModelDeferredRenderer.m
//  ModelViewer
//
//  Created by Dong on 10/25/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "ModelDeferredRenderer.h"
#import "NuoBackdropMesh.h"



@implementation ModelDeferredRenderer


- (instancetype)initWithDevice:(id<MTLDevice>)device
            withSceneParameter:(id<NuoMeshSceneParametersProvider>)sceneParameter
{
    self = [super initWithDevice:device withSceneParameter:sceneParameter];
    return self;
}


- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    id<MTLRenderCommandEncoder> renderPass = [self currentRenderPass:commandBuffer];
    renderPass.label = @"Deferred Render Pass";
    
    if (_backdropMesh)
        [_backdropMesh drawMesh:renderPass indexBuffer:inFlight];
    
    [super drawWithCommandBuffer:commandBuffer withInFlightIndex:inFlight];
}


@end
