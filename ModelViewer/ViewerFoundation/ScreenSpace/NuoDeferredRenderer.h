//
//  NuoAmbientOcclusionRenderer.h
//  ModelViewer
//
//  Created by Dong on 10/1/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoRenderPass.h"
#import "NuoUniforms.h"


@protocol NuoMeshSceneParametersProvider;
@class NuoMesh;


@interface NuoDeferredRenderer : NuoRenderPass


/**
 *  result from the immediate phase
 */
@property (nonatomic, weak) id<MTLTexture> immediateResult;

@property (nonatomic, strong) id<MTLRenderCommandEncoder> lastRenderPass;


- (instancetype)initWithDevice:(id<MTLDevice>)device
            withSceneParameter:(id<NuoMeshSceneParametersProvider>)sceneParameter;

- (void)setMeshes:(NSArray<NuoMesh*>*)meshes;

- (void)setParameters:(NuoDeferredRenderUniforms*)params;

- (void)drawWithRenderPass:(id<MTLRenderCommandEncoder>)renderPass withInFlightIndex:(unsigned int)inFlight;


@end
