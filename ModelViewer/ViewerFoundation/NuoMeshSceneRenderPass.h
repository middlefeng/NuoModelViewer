//
//  NuoMeshSceneRenderPass.h
//  ModelViewer
//
//  Created by Dong on 9/29/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoRenderPipelinePass.h"

#import <Metal/Metal.h>
#import <simd/simd.h>



@class NuoShadowMapRenderer;



@protocol NuoMeshSceneParametersProvider


- (NSArray<id<MTLBuffer>>*)transUniformBuffers;
- (NSArray<id<MTLBuffer>>*)lightCastBuffers;
- (NSArray<id<MTLBuffer>>*)lightingUniformBuffers;
- (id<MTLBuffer>)modelCharacterUnfiromBuffer;

- (NuoShadowMapRenderer*)shadowMapRenderer:(NSUInteger)index;


@end



@interface NuoMeshSceneRenderPass : NuoRenderPipelinePass


@property (nonatomic, weak) id<NuoMeshSceneParametersProvider> paramsProvider;
@property (nonatomic, readonly) id<MTLSamplerState> shadowMapSamplerState;


- (instancetype)initWithDevice:(id<MTLDevice>)device;

/**
 *  the function sets up all common uniforms that are shared by all meshes.
 *  the actual value of those uniforms come from the application-specific subclass.
 *  this is not only used by the rendering of the mesh-scene pass itself, but used by other passes which
 *  render meshes and require the common uniforms.
 */
- (void)setSceneBuffersTo:(id<MTLRenderCommandEncoder>)renderPass withInFlightIndex:(unsigned int)inFlight;


@end
