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
@class NuoMeshSceneRoot;


@interface NuoDeferredRenderer : NuoRenderPass

/**
 *  shadowOverlayMap is preserved for future study. currently, it is no
 *  longer used because results of normal/virutal surfaces are stored separatedly
 */
@property (nonatomic, readonly) id<MTLTexture> shadowOverlayMap;

@property (nonatomic, readonly) id<MTLTexture> ambientBuffer;


/**
 *  result from the immediate phase
 */
@property (nonatomic, weak) id<MTLTexture> immediateResult;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                  withSceneParameter:(id<NuoMeshSceneParametersProvider>)sceneParameter;

- (void)setRoot:(NuoMeshSceneRoot*)root;

- (void)setParameters:(const NuoAmbientUniformField&)params;


@end
