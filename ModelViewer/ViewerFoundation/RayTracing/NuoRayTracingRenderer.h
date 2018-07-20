//
//  NuoRayTracingRenderer.h
//  ModelViewer
//
//  Created by middleware on 6/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoRenderPipelinePass.h"
#import "NuoMesh.h"



@class NuoRayAccelerateStructure;



@interface NuoRayTracingRenderer : NuoRenderPipelinePass

@property (nonatomic, assign) CGFloat fieldOfView;

@property (nonatomic, weak) NuoMesh* mesh;
@property (nonatomic, weak) NuoRayAccelerateStructure* rayStructure;

@property (nonatomic, readonly) id<MTLBuffer> primaryIntersectionBuffer;
@property (nonatomic, readonly) NSArray<id<MTLTexture>>* targetTextures;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
               withAccumulatedResult:(BOOL)accumulateResult
                     withTargetCount:(uint)targetCount;

- (void)resetResources:(id<MTLCommandBuffer>)commandBuffer;

/**
 *  overridden by subclass, with compute-shader running for ray tracing
 */
- (void)runRayTraceShade:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight;


/**
 *  functions called from within "- (void)runRayTraceShade:..."
 */
- (BOOL)rayIntersect:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight;
- (BOOL)rayIntersect:(id<MTLCommandBuffer>)commandBuffer
            withRays:(id<MTLBuffer>)rayBuffer withIntersection:(id<MTLBuffer>)intersection;


- (void)rayEmit:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight;
- (void)updatePrimaryRayMask:(uint32)mask withCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                withInFlight:(uint)inFlight;

- (void)runRayTraceCompute:(id<MTLComputePipelineState>)pipeline
         withCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
             withParameter:(NSArray<id<MTLBuffer>>*)paramterBuffers
          withIntersection:(id<MTLBuffer>)intersection
         withInFlightIndex:(unsigned int)inFlight;


@end


