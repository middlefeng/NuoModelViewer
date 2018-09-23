//
//  ModelRayTracingBlendRenderer.m
//  ModelViewer
//
//  Created by middleware on 8/27/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "ModelRayTracingBlendRenderer.h"
#import "NuoIlluminationMesh.h"



@implementation ModelRayTracingBlendRenderer
{
    NuoIlluminationMesh* _mesh;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                     withSampleCount:(uint)sampleCount
{
    self = [super initWithCommandQueue:commandQueue
                       withPixelFormat:pixelFormat withSampleCount:1];
    
    if (self)
    {
        _mesh = [[NuoIlluminationMesh alloc] initWithCommandQueue:commandQueue];
        
        [_mesh setSampleCount:sampleCount];
        [_mesh makePipelineAndSampler:pixelFormat withBlendMode:kBlend_None];
    }
    
    return self;
}



- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    id<MTLRenderCommandEncoder> renderPass = [self retainDefaultEncoder:commandBuffer];
    [_mesh setModelTexture:self.sourceTexture];
    [_mesh setIlluminationMap:_illumination];
    [_mesh setShadowOverlayMap:_shadowOverlayMap];
    [_mesh drawMesh:renderPass indexBuffer:inFlight];
    [self releaseDefaultEncoder];
}

@end
