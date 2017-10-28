//
//  NuoScreenSpaceRenderer.m
//  ModelViewer
//
//  Created by Dong on 9/28/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoScreenSpaceRenderer.h"
#import "NuoScreenSpaceTarget.h"
#import "NuoMesh.h"


@implementation NuoScreenSpaceRenderer


- (instancetype)initWithDevice:(id<MTLDevice>)device withName:(NSString*)name
{
    self = [super initWithDevice:device];
    
    if (self)
    {
        self.renderTarget = [[NuoScreenSpaceTarget alloc] initWithSampleCount:kSampleCount];
        self.renderTarget.device = device;
        ((NuoScreenSpaceTarget*)self.renderTarget).name = name;
    }
    
    return self;
}


- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    // get the target render pass and draw the scene
    //
    id<MTLRenderCommandEncoder> renderPass = [self currentRenderPass:commandBuffer];
    if (!renderPass)
        return;
    
    renderPass.label = @"Screen Render Pass";
    
    [self setSceneBuffersTo:renderPass withInFlightIndex:inFlight];
    
    for (NuoMesh* mesh in _meshes)
        [mesh drawScreenSpace:renderPass indexBuffer:inFlight];
}


- (id<MTLTexture>)positionBuffer
{
    return ((NuoScreenSpaceTarget*)self.renderTarget).positionBuffer;
}


- (id<MTLTexture>)normalBuffer
{
    return ((NuoScreenSpaceTarget*)self.renderTarget).normalBuffer;
}


- (id<MTLTexture>)ambientBuffer
{
    return ((NuoScreenSpaceTarget*)self.renderTarget).ambientBuffer;
}


- (id<MTLTexture>)shdowOverlayBuffer
{
    return ((NuoScreenSpaceTarget*)self.renderTarget).shadowOverlayBuffer;
}


@end
