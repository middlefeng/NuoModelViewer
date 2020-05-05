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
@property (readonly, nonatomic) NuoBufferSwapChain* lightCastBuffers;

@property (weak, nonatomic) NSArray<NuoLightSource*>* lights;


- (void)setDrawableSize:(CGSize)drawableSize;

- (void)setAmbientParameters:(const NuoAmbientUniformField&)ambientParameters;
- (void)setAmbient:(const NuoVectorFloat3&)ambient;

// info that required by real-time/hybrid only
//
- (void)setSampleCount:(NSUInteger)count;

- (void)predrawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer
            withRayStructChanged:(BOOL)changed
           withRayStructAdjusted:(BOOL)adjusted;

- (void)drawWithCommandBufferPriorBackdrop:(NuoCommandBuffer*)commandBuffer;
- (void)drawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer;

- (void)setDelegateTarget:(NuoRenderPassTarget*)target;

@end


