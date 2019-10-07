//
//  NuoRayVisibility.h
//  ModelViewer
//
//  Created by Dong on 10/2/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>


@class NuoRayBuffer;
@class NuoCommandBuffer;
@class NuoRenderPassTarget;
@class NuoRayTracingRenderer;


@interface NuoRayVisibility : NSObject


@property (nonatomic, weak) NuoRayBuffer* paths;
@property (nonatomic, readonly) NuoRayBuffer* spawnRays;
@property (nonatomic, readonly) id<MTLBuffer> spawnIntersection;

@property (nonatomic, weak) id<MTLBuffer> tracingUniform;
@property (nonatomic, weak) NuoRayTracingRenderer* rayTracer;

@property (nonatomic, assign) size_t rayStride;
@property (nonatomic, readonly) id<MTLBuffer> visibilities;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;

- (void)setDrawableSize:(CGSize)drawableSize;

- (void)visibilityTestInit:(NuoCommandBuffer*)commandBuffer;
- (void)visibilityTest:(NuoCommandBuffer*)commandBuffer;


@end


