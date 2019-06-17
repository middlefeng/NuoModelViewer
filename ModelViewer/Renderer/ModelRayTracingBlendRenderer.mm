//
//  ModelRayTracingBlendRenderer.m
//  ModelViewer
//
//  Created by middleware on 8/27/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "ModelRayTracingBlendRenderer.h"



@implementation ModelRayTracingBlendRenderer
{
    NuoIlluminationMesh* _mesh;
    
    id<MTLTexture> _lightingWithoutBlock;
    id<MTLTexture> _lightingWithBlock;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                     withSampleCount:(uint)sampleCount
{
    self = [super init];
    
    if (self)
    {
        _mesh = [[NuoIlluminationMesh alloc] initWithCommandQueue:commandQueue];
        
        [_mesh setSampleCount:sampleCount];
        [_mesh makePipelineAndSampler:pixelFormat withBlendMode:kBlend_Alpha];
    }
    
    return self;
}


- (void)setGlobalIllumination:(const NuoGlobalIlluminationUniforms&)globalIllumination
{
    [_mesh setParameters:globalIllumination];
}



- (void)drawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer
{
    NuoRenderPassEncoder* renderPass = [self retainDefaultEncoder:commandBuffer];
    [_mesh setModelTexture:_immediateResult];
    [_mesh setIlluminationMap:_illumination];
    [_mesh setShadowOverlayMap:_shadowOverlayMap];
    [_mesh setTranslucentCoverMap:_translucentMap];
    [_mesh drawMesh:renderPass];
    [self releaseDefaultEncoder];
}

@end
