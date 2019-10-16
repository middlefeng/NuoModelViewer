//
//  NuoRayVisibility.m
//  ModelViewer
//
//  Created by Dong on 10/2/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "NuoRayVisibility.h"

#import "NuoRayBuffer.h"
#import "NuoComputeEncoder.h"
#import "NuoRayTracingRenderer.h"
#import "NuoRenderPassTarget.h"



@implementation NuoRayVisibility
{
    NuoRayBuffer* _spawnRays;
    id<MTLBuffer> _spawnIntersectionBuffer;
    id<MTLBuffer> _visibilities;
    
    __weak id<MTLCommandQueue> _commandQueue;
    
    NuoComputePipeline* _pipelineInit;
    NuoComputePipeline* _pipeline;
}



- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super init];
    if (self)
    {
        _commandQueue = commandQueue;
        _pipelineInit = [[NuoComputePipeline alloc] initWithDevice:_commandQueue.device withFunction:@"ray_visibility_init"];
        _pipeline = [[NuoComputePipeline alloc] initWithDevice:_commandQueue.device withFunction:@"ray_visibility"];
    }
    
    return self;
}



- (void)setDrawableSize:(CGSize)drawableSize
{
    assert(_rayStride > 0);
    
    _spawnRays = [[NuoRayBuffer alloc] initWithCommandQueue:_commandQueue];
    _spawnRays.dimension = drawableSize;
    
    const size_t intersectionSize = drawableSize.width * drawableSize.height * _rayStride;
    _spawnIntersectionBuffer = [_commandQueue.device newBufferWithLength:intersectionSize
                                                                 options:MTLResourceStorageModePrivate];
    
    const size_t visibilitiesSize = drawableSize.width * drawableSize.height * sizeof(vector_float3);
    _visibilities = [_commandQueue.device newBufferWithLength:visibilitiesSize
                                                      options:MTLResourceStorageModePrivate];
}


- (void)visibilityTestInit:(NuoCommandBuffer*)commandBuffer
{
    id<MTLBuffer> intersectBuffer = nil;
    
    if (_paths)
    {
        [_rayTracer rayIntersect:commandBuffer withRays:_paths withIntersection:_spawnIntersectionBuffer];
        intersectBuffer = _spawnIntersectionBuffer;
    }
    else
    {
        intersectBuffer = _rayTracer.intersectionBuffer;
    }
    
    [_rayTracer runRayTraceCompute:_pipelineInit
                 withCommandBuffer:commandBuffer
                       withTargets:NO withParameter:@[_tracingUniform, _spawnRays.buffer, _visibilities]
                    withExitantRay:_paths.buffer withIntersection:intersectBuffer];
}


- (void)visibilityTest:(NuoCommandBuffer*)commandBuffer
{
    [_rayTracer rayIntersect:commandBuffer withRays:_spawnRays withIntersection:_spawnIntersectionBuffer];
    
    [_rayTracer runRayTraceCompute:_pipeline
                 withCommandBuffer:commandBuffer
                     withTargets:NO withParameter:@[_tracingUniform, _visibilities]
                    withExitantRay:_spawnRays.buffer
                  withIntersection:_spawnIntersectionBuffer];
}


- (id<MTLBuffer>)visibilities
{
    return _visibilities;
}


- (NuoRayBuffer*)spawnRays
{
    return _spawnRays;
}



- (id<MTLBuffer>)spawnIntersection
{
    return _spawnIntersectionBuffer;
}



@end
