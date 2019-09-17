//
//  ModelRayTracingBlendRenderer.m
//  ModelViewer
//
//  Created by middleware on 8/27/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "ModelRayTracingBlendRenderer.h"

#import "NuoComputeEncoder.h"
#import "NuoCommandBuffer.h"
#import "ModelRayTracingRenderer.h"
#import "NuoRenderPassAttachment.h"

#import "NuoInspectableMaster.h"



@implementation ModelRayTracingBlendRenderer
{
    NuoIlluminationMesh* _mesh;
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
        [_mesh makePipelineAndSampler:pixelFormat withBlendMode:kBlend_Alpha
                           withHybrid:NO];
    }
    
    return self;
}


- (void)drawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer
{
    NuoRenderPassEncoder* renderPass = [self retainDefaultEncoder:commandBuffer];
    [_mesh setIlluminations:_illuminations];
    [_mesh setTranslucentCoverMap:_translucentMap];
    [_mesh drawMesh:renderPass];
    [self releaseDefaultEncoder];
}

@end
