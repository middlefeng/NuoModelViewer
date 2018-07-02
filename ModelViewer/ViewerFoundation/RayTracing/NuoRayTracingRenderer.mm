//
//  NuoRayTracingRenderer.m
//  ModelViewer
//
//  Created by middleware on 6/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoRayTracingRenderer.h"
#import "NuoRayAccelerateStructure.h"

#import "NuoTextureAverageMesh.h"
#import "NuoRenderPassAttachment.h"

#import <MetalPerformanceShaders/MetalPerformanceShaders.h>



@implementation NuoRayTracingRenderer
{
    NuoRenderPassTarget* _rayTracingTarget;
    NuoRenderPassTarget* _rayTracingAccumulate;
    NuoTextureAccumulator* _accumulator;
}



- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                     withSampleCount:(uint)sampleCount
{
    self = [super initWithCommandQueue:commandQueue
                       withPixelFormat:pixelFormat withSampleCount:1];
    
    if (self)
    {
        _rayTracingTarget = [[NuoRenderPassTarget alloc] initWithCommandQueue:commandQueue
                                                              withPixelFormat:MTLPixelFormatRGBA32Float
                                                              withSampleCount:1];
        
        _rayTracingTarget.manageTargetTexture = YES;
        _rayTracingTarget.sharedTargetTexture = NO;
        _rayTracingTarget.colorAttachments[0].needWrite = YES;
        _rayTracingTarget.name = @"Ray Tracing";
        
        _rayTracingAccumulate = [[NuoRenderPassTarget alloc] initWithCommandQueue:commandQueue
                                                                  withPixelFormat:MTLPixelFormatRGBA32Float
                                                                  withSampleCount:1];
        
        _rayTracingAccumulate.manageTargetTexture = YES;
        _rayTracingAccumulate.sharedTargetTexture = NO;
        _rayTracingAccumulate.colorAttachments[0].needWrite = YES;
        _rayTracingAccumulate.name = @"Ray Tracing Accumulate";
        
        [self resetResources];
    }
    
    return self;
}



- (void)resetResources
{
    _accumulator = [[NuoTextureAccumulator alloc] initWithCommandQueue:self.commandQueue];
    [_accumulator makePipelineAndSampler];
}



- (void)setDrawableSize:(CGSize)drawableSize
{
    [super setDrawableSize:drawableSize];
    [_rayTracingTarget setDrawableSize:drawableSize];
    [_rayTracingAccumulate setDrawableSize:drawableSize];
    
    const uint w = (uint)drawableSize.width;
    const uint h = (uint)drawableSize.height;
    const uint intersectionSize = kRayIntersectionStride * w * h;
    _primaryIntersectionBuffer = [self.commandQueue.device newBufferWithLength:intersectionSize
                                                                       options:MTLResourceStorageModePrivate];
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
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
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
    
    [computeEncoder setTexture:_rayTracingTarget.targetTexture atIndex:0];
    [computeEncoder setComputePipelineState:pipeline];
    
    CGSize drawableSize = [_rayTracingTarget drawableSize];
    const float w = drawableSize.width;
    const float h = drawableSize.height;
    MTLSize threads = MTLSizeMake(8, 8, 1);
    MTLSize threadgroups = MTLSizeMake((w + threads.width  - 1) / threads.width,
                                       (h + threads.height - 1) / threads.height, 1);
    [computeEncoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threads];
    
    [computeEncoder endEncoding];
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
    _rayTracingTarget.clearColor = MTLClearColorMake(0, 0, 0, 0);
    [_rayTracingTarget retainRenderPassEndcoder:commandBuffer];
    [_rayTracingTarget releaseRenderPassEndcoder];
    
    [self runRayTraceShade:commandBuffer withInFlightIndex:inFlight];
    
    [_accumulator accumulateTexture:_rayTracingTarget.targetTexture
                          onTexture:_rayTracingAccumulate.targetTexture
                       withInFlight:inFlight withCommandBuffer:commandBuffer];
}



- (id<MTLTexture>)targetTexture
{
    return [_rayTracingAccumulate targetTexture];
}



@end
