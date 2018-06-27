//
//  NuoMeshSceneRenderPass.h
//  ModelViewer
//
//  Created by Dong on 9/29/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoRenderPipelinePass.h"

#import <Metal/Metal.h>

#include "NuoBounds.h"



@class NuoShadowMapRenderer;



@protocol NuoMeshSceneParametersProvider


- (NSArray<id<MTLBuffer>>*)transUniformBuffers;
- (NSArray<id<MTLBuffer>>*)lightCastBuffers;
- (NSArray<id<MTLBuffer>>*)lightingUniformBuffers;
- (id<MTLBuffer>)modelCharacterUnfiromBuffer;
- (BOOL)cullEnabled;

- (NuoShadowMapRenderer*)shadowMapRenderer:(NSUInteger)index;
- (id<MTLTexture>)depthMap;
- (NuoBounds)sceneBounds;


@end



@interface NuoMeshSceneRenderPass : NuoRenderPipelinePass


@property (nonatomic, weak) id<NuoMeshSceneParametersProvider> paramsProvider;
@property (nonatomic, readonly) id<MTLSamplerState> shadowMapSamplerState;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;

/**
 *  the function sets up all common uniforms that are shared by all meshes.
 *  the actual value of those uniforms come from the NuoMeshSceneParametersProvider.
 */
- (void)setSceneBuffersTo:(id<MTLRenderCommandEncoder>)renderPass withInFlightIndex:(unsigned int)inFlight;

/**
 *  the function set a depth map to the render pass. unlike "setSceneBuffersTo:..." which is very
 *  basic and almost always needed, this is not required by renderers which do not need a depth map
 */
- (void)setDepthMapTo:(id<MTLRenderCommandEncoder>)renderPass;


@end
