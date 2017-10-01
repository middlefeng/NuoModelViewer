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
        self.renderTarget = [[NuoScreenSpaceTarget alloc] init];
        self.renderTarget.device = device;
        ((NuoScreenSpaceTarget*)self.renderTarget).name = name;
    }
    
    return self;
}


- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    MTLRenderPassDescriptor *passDescriptor = [self.renderTarget currentRenderPassDescriptor];
    if (!passDescriptor)
        return;
    
    // get the target render pass and draw the scene
    //
    id<MTLRenderCommandEncoder> renderPass = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
    renderPass.label = @"Screen Render Pass";
    
    [self setSceneBuffersTo:renderPass withInFlightIndex:inFlight];
    
    for (NuoMesh* mesh in _meshes)
        [mesh drawScreenSpace:renderPass indexBuffer:inFlight];
    
    [renderPass endEncoding];
}


@end
