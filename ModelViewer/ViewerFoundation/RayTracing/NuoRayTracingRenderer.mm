//
//  NuoRayTracingRenderer.m
//  ModelViewer
//
//  Created by middleware on 6/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoRayTracingRenderer.h"
#import "NuoRayAccelerateStructure.h"

#import "NuoTextureMesh.h"
#import "NuoTextureAverageMesh.h"

#import <MetalPerformanceShaders/MetalPerformanceShaders.h>



@implementation NuoRayTracingRenderer
{
    NuoRenderPassTarget* _rayTracingTarget;
    NuoRenderPassTarget* _rayTracingAccumulate;
    NuoTextureAverageMesh* _averageMesh;
    
    NuoTextureMesh* _rayTracingOverlay;
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
        
        _rayTracingTarget.computeTarget = YES;
        _rayTracingTarget.manageTargetTexture = YES;
        _rayTracingTarget.sharedTargetTexture = NO;
        _rayTracingTarget.name = @"Ray Tracing";
        
        _rayTracingAccumulate = [[NuoRenderPassTarget alloc] initWithCommandQueue:commandQueue
                                                                  withPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                  withSampleCount:1];
        
        _rayTracingAccumulate.computeTarget = NO;
        _rayTracingAccumulate.manageTargetTexture = YES;
        _rayTracingAccumulate.sharedTargetTexture = NO;
        _rayTracingAccumulate.name = @"Ray Tracing Accumulate";
        
        [self resetResources];
        
        _rayTracingOverlay = [[NuoTextureMesh alloc] initWithCommandQueue:commandQueue];
        _rayTracingOverlay.sampleCount = 1;
        [_rayTracingOverlay makePipelineAndSampler:MTLPixelFormatBGRA8Unorm withBlendMode:kBlend_Alpha];
    }
    
    return self;
}



- (void)resetResources
{
    _averageMesh = [[NuoTextureAverageMesh alloc] initWithCommandQueue:self.commandQueue];
    _averageMesh.sampleCount = 1;
    [_averageMesh makePipelineAndSampler];
}



- (void)setDrawableSize:(CGSize)drawableSize
{
    [super setDrawableSize:drawableSize];
    [_rayTracingTarget setDrawableSize:drawableSize];
    [_rayTracingAccumulate setDrawableSize:drawableSize];
}



- (BOOL)rayIntersect:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    if (!_rayStructure)
        return NO;
    
    [_rayStructure rayTrace:commandBuffer inFlight:inFlight];
    return [_rayStructure intersectionBuffer] != nil;
}




- (void)runRayTraceCompute:(id<MTLComputePipelineState>)pipeline
         withCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
             withParameter:(NSArray<id<MTLBuffer>>*)paramterBuffers
         withInFlightIndex:(unsigned int)inFlight
{
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    [computeEncoder setBuffer:[_rayStructure uniformBuffer:inFlight] offset:0 atIndex:0];
    [computeEncoder setBuffer:[_rayStructure intersectionBuffer] offset:0 atIndex:1];
    
    if (paramterBuffers)
    {
        for (uint i = 0; i < paramterBuffers.count; ++i)
            [computeEncoder setBuffer:paramterBuffers[i] offset:0 atIndex:2 + i];
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
    if ([self rayIntersect:commandBuffer withInFlightIndex:inFlight])
    {
        [self runRayTraceCompute:/* some shade pipeline */ nil withCommandBuffer:commandBuffer
                   withParameter:nil withInFlightIndex:inFlight];
    }
}



- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    // clear the ray tracing target
    //
    _rayTracingTarget.clearColor = MTLClearColorMake(0, 0, 0, 0);
    [_rayTracingTarget retainRenderPassEndcoder:commandBuffer];
    [_rayTracingTarget releaseRenderPassEndcoder];
    
    [self runRayTraceShade:commandBuffer withInFlightIndex:inFlight];
    
    [_averageMesh accumulateTexture:_rayTracingTarget.targetTexture
                           onTarget:_rayTracingAccumulate
                       withInFlight:inFlight withCommandBuffer:commandBuffer];
    
    id<MTLRenderCommandEncoder> renderPass = [self retainDefaultEncoder:commandBuffer];
    
    [super drawWithCommandBuffer:commandBuffer withInFlightIndex:inFlight];
    
    
    [_rayTracingOverlay setModelTexture:_rayTracingAccumulate.targetTexture];
    [_rayTracingOverlay drawMesh:renderPass indexBuffer:inFlight];
    
    [self releaseDefaultEncoder];
}



@end
