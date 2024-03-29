//
//  NuoMeshSceneRenderPass.h
//  ModelViewer
//
//  Created by Dong on 9/29/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoRenderPipelinePass.h"

#import <Metal/Metal.h>



@class NuoShadowMapRenderer;



typedef enum
{
    kNuoSceneMask_Opaque,
    kNuoSceneMask_Translucent
}
NuoSceneMask;



@class NuoBufferInFlight;


/**
 *  an application should provide all required parameter buffers through this protocol
 *  to a NuoMeshSceneRenderPass to render a set of meshes (i.e. a scene)
 */
@protocol NuoMeshSceneParametersProvider


- (NuoBufferInFlight*)transUniformBuffers;
- (NuoBufferInFlight*)lightCastBuffers;
- (NuoBufferInFlight*)lightingUniformBuffers;
- (id<MTLBuffer>)modelCharacterUnfiromBuffer;
- (BOOL)cullEnabled;

- (id<MTLTexture>)shadowMap:(uint)index withMask:(NuoSceneMask)mask;

@end



@interface NuoMeshSceneRenderPass : NuoRenderPipelinePass


@property (nonatomic, weak) id<NuoMeshSceneParametersProvider> paramsProvider;
@property (nonatomic, readonly) id<MTLSamplerState> shadowMapSamplerState;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;

/**
 *  the function sets up all common uniforms that are shared by all meshes.
 *  the actual value of those uniforms come from the NuoMeshSceneParametersProvider.
 */
- (void)setSceneBuffersTo:(NuoRenderPassEncoder*)renderPass;

/**
 *  sub class to override to provide a depthMap
 */
- (id<MTLTexture>)depthMap;


@end
