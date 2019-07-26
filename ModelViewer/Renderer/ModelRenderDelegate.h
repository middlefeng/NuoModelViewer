//
//  ModelRenderDelegate.h
//  ModelViewer
//
//  Created by Dong on 7/22/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "NuoUniforms.h"
#import "NuoCommandBuffer.h"


typedef enum
{
    kRecord_Start,
    kRecord_Stop,
    kRecord_Pause
}
RecordStatus;


@class NuoLightSource;
@class NuoMeshSceneRoot;


@protocol ModelRenderDelegate <NSObject>

@property (assign, nonatomic) RecordStatus rayTracingRecordStatus;
@property (assign, nonatomic) float fieldOfView;
@property (assign, nonatomic) NuoMatrixFloat44 viewMatrix;
@property (assign, nonatomic) float illuminationStrength;


@property (weak, nonatomic) NSArray<NuoLightSource*>* lights;
@property (readonly, nonatomic) NuoBufferSwapChain* lightCastBuffers;
@property (readonly, nonatomic) NuoBufferSwapChain* transUniformBuffers;
@property (readonly, nonatomic) id<MTLBuffer> modelCharacterUnfiromBuffer;


- (void)setDrawableSize:(CGSize)drawableSize;
- (void)setSampleCount:(uint)count;

- (void)setAmbientParameters:(const NuoAmbientUniformField&)ambientParameters;
- (void)setAmbient:(const NuoVectorFloat3&)ambient;

- (void)setResolveDepth:(BOOL)resolveDepth;
- (id<MTLTexture>)depthMap;
- (id<MTLTexture>)shadowMap:(uint)index withMask:(NuoSceneMask)mask;

- (void)updateUniforms:(NuoCommandBuffer*)commandBuffer;

- (void)predrawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer
            withRayStructChanged:(BOOL)changed
           withRayStructAdjusted:(BOOL)adjusted;

- (void)drawWithCommandBufferPriorBackdrop:(NuoCommandBuffer*)commandBuffer;
- (void)drawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer;

- (void)setDelegateTarget:(NuoRenderPassTarget*)target;

@end


