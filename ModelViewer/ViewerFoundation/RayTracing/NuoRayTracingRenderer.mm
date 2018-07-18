//
//  NuoRayTracingRenderer.m
//  ModelViewer
//
//  Created by middleware on 6/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoRayTracingRenderer.h"
#import "NuoRayAccelerateStructure.h"

#import "NuoComputeEncoder.h"
#import "NuoTextureAverageMesh.h"
#import "NuoRenderPassAttachment.h"

#import <MetalPerformanceShaders/MetalPerformanceShaders.h>



@implementation NuoRayTracingRenderer
{
    NSArray<NuoRenderPassTarget*>* _rayTracingTargets;
    NSArray<NuoRenderPassTarget*>* _rayTracingAccumulates;
    NSArray<NuoTextureAccumulator*>* _accumulators;
    
    CGSize _drawableSize;
}



- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                     withSampleCount:(uint)sampleCount
{
    assert(false);
}



- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
               withAccumulatedResult:(BOOL)accumulateResult
                     withTargetCount:(uint)targetCount
{
    self = [super initWithCommandQueue:commandQueue
                       withPixelFormat:MTLPixelFormatInvalid withSampleCount:1];
    
    if (self && accumulateResult)
    {
        NuoRenderPassTarget* rayTracingTargets[targetCount];
        NuoRenderPassTarget* rayTracingAccumulates[targetCount];
        
        for (uint i = 0; i < targetCount; ++i)
        {
            rayTracingTargets[i] = [[NuoRenderPassTarget alloc] initWithCommandQueue:commandQueue
                                                                     withPixelFormat:MTLPixelFormatR32Float
                                                                     withSampleCount:1];
        
            rayTracingTargets[i].manageTargetTexture = YES;
            rayTracingTargets[i].sharedTargetTexture = NO;
            rayTracingTargets[i].colorAttachments[0].needWrite = YES;
            rayTracingTargets[i].name = @"Ray Tracing";
        
            rayTracingAccumulates[i] = [[NuoRenderPassTarget alloc] initWithCommandQueue:commandQueue
                                                                         withPixelFormat:MTLPixelFormatR32Float
                                                                         withSampleCount:1];
            
            rayTracingAccumulates[i].manageTargetTexture = YES;
            rayTracingAccumulates[i].sharedTargetTexture = NO;
            rayTracingAccumulates[i].colorAttachments[0].needWrite = YES;
            rayTracingAccumulates[i].name = @"Ray Tracing Accumulate";
        }
        
        _rayTracingTargets = [[NSArray alloc] initWithObjects:rayTracingTargets count:targetCount];
        _rayTracingAccumulates = [[NSArray alloc] initWithObjects:rayTracingAccumulates count:targetCount];
        
        [self resetResources:nil];
    }
    
    return self;
}



- (void)resetResources:(id<MTLCommandBuffer>)commandBuffer
{
    NuoTextureAccumulator* accumulators[_rayTracingTargets.count];
    
    for (uint i = 0; i < _rayTracingTargets.count; ++i)
    {
        accumulators[i] = [[NuoTextureAccumulator alloc] initWithCommandQueue:self.commandQueue];
        [accumulators[i] makePipelineAndSampler];
        
        if (commandBuffer && _rayTracingAccumulates[i].targetTexture)
        {
            [_rayTracingAccumulates[i] retainRenderPassEndcoder:commandBuffer];
            [_rayTracingAccumulates[i] releaseRenderPassEndcoder];
        }
    }
    
    _accumulators = [[NSArray alloc] initWithObjects:accumulators count:_rayTracingTargets.count];
}



- (void)setDrawableSize:(CGSize)drawableSize
{
    [super setDrawableSize:drawableSize];
    
    for (uint i = 0; i < _rayTracingTargets.count; ++i)
    {
        [_rayTracingTargets[i] setDrawableSize:drawableSize];
        [_rayTracingAccumulates[i] setDrawableSize:drawableSize];
    }
    
    const uint w = (uint)drawableSize.width;
    const uint h = (uint)drawableSize.height;
    const uint intersectionSize = kRayIntersectionStride * w * h;
    _primaryIntersectionBuffer = [self.commandQueue.device newBufferWithLength:intersectionSize
                                                                       options:MTLResourceStorageModePrivate];
    
    _drawableSize = drawableSize;
}



- (BOOL)rayIntersect:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    if (!_rayStructure)
        return NO;
    
    [_rayStructure rayTrace:commandBuffer inFlight:inFlight withIntersection:_primaryIntersectionBuffer];
    return YES;
}


- (BOOL)rayIntersect:(id<MTLCommandBuffer>)commandBuffer
            withRays:(id<MTLBuffer>)rayBuffer withIntersection:(id<MTLBuffer>)intersection
{
    if (!_rayStructure)
        return NO;
    
    [_rayStructure rayTrace:commandBuffer withRays:rayBuffer withIntersection:intersection];
    return YES;
}


- (void)runRayTraceCompute:(id<MTLComputePipelineState>)pipeline
         withCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
             withParameter:(NSArray<id<MTLBuffer>>*)paramterBuffers
          withIntersection:(id<MTLBuffer>)intersection
         withInFlightIndex:(unsigned int)inFlight
{
    NuoComputeEncoder* computeEncoder = [[NuoComputeEncoder alloc] initWithCommandBuffer:commandBuffer
                                                                            withPipeline:pipeline
                                                                                withName:@"Ray Trace"];
    
    [computeEncoder setBuffer:[_rayStructure uniformBuffer:inFlight] offset:0 atIndex:0];
    [computeEncoder setBuffer:[_rayStructure primaryRayBuffer] offset:0 atIndex:1];
    [computeEncoder setBuffer:[_rayStructure indexBuffer] offset:0 atIndex:2];
    [computeEncoder setBuffer:[_rayStructure normalBuffer] offset:0 atIndex:3];
    [computeEncoder setBuffer:intersection offset:0 atIndex:4];
    
    if (paramterBuffers)
    {
        for (uint i = 0; i < paramterBuffers.count; ++i)
            [computeEncoder setBuffer:paramterBuffers[i] offset:0 atIndex:5 + i];
    }
    
    for (uint i = 0; i < _rayTracingTargets.count; ++i)
        [computeEncoder setTexture:_rayTracingTargets[i].targetTexture atIndex:i];
    
    [computeEncoder setDataSize:_drawableSize];
    [computeEncoder dispatch];
}



- (void)runRayTraceShade:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    /* default behavior is not very useful, meant to be override */
    
    /*************************************************************/
    /*************************************************************/
    if ([self rayIntersect:commandBuffer withInFlightIndex:inFlight])
    {
        [self runRayTraceCompute:/* some shade pipeline */ nil withCommandBuffer:commandBuffer
                   withParameter:nil withIntersection:nil withInFlightIndex:inFlight];
    }
    /*************************************************************/
    /*************************************************************/
}



- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    // clear the ray tracing target
    //
    for (NuoRenderPassTarget* tracingTarget in _rayTracingTargets)
    {
        tracingTarget.clearColor = MTLClearColorMake(0, 0, 0, 1.0);
        [tracingTarget retainRenderPassEndcoder:commandBuffer];
        [tracingTarget releaseRenderPassEndcoder];
    }
    
    [self runRayTraceShade:commandBuffer withInFlightIndex:inFlight];
    
    for (uint i = 0; i < _rayTracingTargets.count; ++i)
    {
        [_accumulators[i] accumulateTexture:_rayTracingTargets[i].targetTexture
                                  onTexture:_rayTracingAccumulates[i].targetTexture
                               withInFlight:inFlight withCommandBuffer:commandBuffer];
    }
}



- (NSArray<id<MTLTexture>>*)targetTextures
{
    id<MTLTexture> textures[_rayTracingAccumulates.count];
    for (uint i = 0; i < _rayTracingAccumulates.count; ++i)
        textures[i] = _rayTracingAccumulates[i].targetTexture;
    
    return [[NSArray alloc] initWithObjects:textures count:_rayTracingAccumulates.count];
}



@end
