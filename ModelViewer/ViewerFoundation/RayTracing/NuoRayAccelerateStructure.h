//
//  NuoRayTracingAccelerateStructure.h
//  ModelViewer
//
//  Created by middleware on 6/16/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#include "NuoMathVector.h"


extern const uint kRayIntersectionStride;


@class NuoRayBuffer;
@class NuoMeshSceneRoot;
@class NuoRenderPassTarget;
@class NuoCommandBuffer;
@protocol NuoRenderInFlight;


@interface NuoRayAccelerateStructure : NSObject


@property (nonatomic, assign) CGFloat fieldOfView;
@property (nonatomic, assign) CGSize drawableSize;

@property (nonatomic, readonly) NuoRayBuffer* primaryRayBuffer;

@property (nonatomic, readonly) id<MTLBuffer> indexBuffer;
@property (nonatomic, readonly) id<MTLBuffer> vertexBuffer;
@property (nonatomic, readonly) id<MTLBuffer> materialBuffer;
@property (nonatomic, readonly) id<MTLBuffer> maskBuffer;
@property (nonatomic, readonly) NSArray* diffuseTextures;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;

- (void)setRoot:(NuoMeshSceneRoot*)root;
- (void)setRoot:(NuoMeshSceneRoot*)root withCommandBuffer:(NuoCommandBuffer*)commandBuffer;
- (void)setView:(const NuoMatrixFloat44&)viewTrans;

- (void)updatePrimaryRayMask:(uint32)mask withCommandBuffer:(NuoCommandBuffer*)commandBuffer;

- (void)primaryRayEmit:(NuoCommandBuffer*)commandBuffer;

- (void)primaryRayIntersect:(NuoCommandBuffer*)commandBuffer withIntersection:(id<MTLBuffer>)intersection;
- (void)rayIntersect:(NuoCommandBuffer*)commandBuffer withRays:(NuoRayBuffer*)rayBuffer
            withIntersection:(id<MTLBuffer>)intersection;;


- (id<MTLBuffer>)uniformBuffer:(id<NuoRenderInFlight>)inFlight;


@end


