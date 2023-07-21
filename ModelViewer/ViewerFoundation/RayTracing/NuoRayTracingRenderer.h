//
//  NuoRayTracingRenderer.h
//  ModelViewer
//
//  Created by Dong on 6/11/18.
//  Updated by Dong on 7/19/23
//  Copyright © 2023 Dong Feng. All rights reserved.
//

#import "NuoRenderPipelinePass.h"
#import "NuoMesh.h"



@class NuoRayBuffer;
@class NuoComputePipeline;
@class NuoComputeEncoder;
@class NuoArgumentBuffer;
@class NuoRayAccelerateStructure;



@interface NuoRayTracingRenderer : NuoRenderPipelinePass

@property (nonatomic, assign) CGFloat fieldOfView;

@property (nonatomic, weak) NuoMesh* mesh;
@property (nonatomic, weak) NuoRayAccelerateStructure* rayStructure;

@property (nonatomic, readonly) id<MTLBuffer> intersectionBuffer;
@property (nonatomic, readonly) NSArray<id<MTLTexture>>* targetTextures;


/**
 *  pixelFormat - one channel per kind of objects (e.g. opaque, translucent ...)
 *  targetCount - one target which is accumulated by monte carlo method
 */
- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                     withTargetCount:(uint)targetCount;

- (void)resetResources;

/**
 *  overridden by subclass, with compute-shader running for ray tracing
 */
- (void)runRayTraceShade:(NuoCommandBuffer*)commandBuffer;


/**
 *  functions called from within "- (void)runRayTraceShade:..."
 */
- (BOOL)primaryRayIntersect:(NuoCommandBuffer*)commandBuffer;
- (BOOL)rayIntersect:(NuoCommandBuffer*)commandBuffer
            withRays:(NuoRayBuffer*)rayBuffer withIntersection:(id<MTLBuffer>)intersection;


- (void)primaryRayEmit:(NuoCommandBuffer*)commandBuffer;
- (void)updatePrimaryRayMask:(uint32)mask withCommandBuffer:(NuoCommandBuffer*)commandBuffer;

/**
 *  protocol with "pipeline" shader:
 *  parameter buffers:
 *      0. ray struct uniform (common for all renderers)
 *      1. targets in an encoded argument buffer
 *      2. extra parameter (sepcific to each renderer)
 *      ... model material textures
 *
 *  an "encoder" is needed as the second parameter, rather than a command buffer. this is to
 *  allow the argument buffer, as the third parameter, to be created in the same encoding
 *  process as that strated by the same encoder
 */
- (void)runRayTraceCompute:(NuoComputeEncoder*)encoder
               withTargets:(NuoArgumentBuffer*)targets
             withParameter:(NSArray<id<MTLBuffer>>*)paramterBuffers
            withExitantRay:(id<MTLBuffer>)exitantRay
          withIntersection:(id<MTLBuffer>)intersection;


- (void)runRayTraceCompute:(NuoComputePipeline*)pipeline
         withCommandBuffer:(NuoCommandBuffer*)commandBuffer
             withParameter:(NSArray<id<MTLBuffer>>*)paramterBuffers
            withExitantRay:(id<MTLBuffer>)exitantRay
          withIntersection:(id<MTLBuffer>)intersection;

- (void)runRayTraceCompute:(NuoComputePipeline*)pipeline
         withCommandBuffer:(NuoCommandBuffer*)commandBuffer
             withParameter:(NSArray<id<MTLBuffer>>*)paramterBuffers
          withIntersection:(id<MTLBuffer>)intersection;

- (void)runRayTraceCompute:(NuoComputePipeline*)pipeline
         withCommandBuffer:(NuoCommandBuffer*)commandBuffer
             withParameter:(NSArray<id<MTLBuffer>>*)paramterBuffers;


- (void)rayStructUpdated;


@end


