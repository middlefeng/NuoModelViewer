//
//  ModelDeferredRenderer.m
//  ModelViewer
//
//  Created by Dong on 10/25/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "ModelDeferredRenderer.h"



@implementation ModelDeferredRenderer


- (instancetype)initWithDevice:(id<MTLDevice>)device
            withSceneParameter:(id<NuoMeshSceneParametersProvider>)sceneParameter
{
    self = [super initWithDevice:device withSceneParameter:sceneParameter];
    return self;
}


- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    MTLRenderPassDescriptor *passDescriptor = [self.renderTarget currentRenderPassDescriptor];
    id<MTLRenderCommandEncoder> renderPass = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
    renderPass.label = @"Deferred Render Pass";
    
    [self drawWithRenderPass:renderPass withInFlightIndex:inFlight];
    
    [renderPass endEncoding];
}


@end
