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


- (void)resetResources;

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

- (void)runRayTraceCompute:(id<MTLComputePipelineState>)pipeline
         withCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
             withParameter:(NSArray<id<MTLBuffer>>*)paramterBuffers
          withIntersection:(id<MTLBuffer>)intersection
         withInFlightIndex:(unsigned int)inFlight;


@end


