//
//  ModelSceneParameters.h
//  ModelViewer
//
//  Created by Dong on 7/26/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "NuoMeshSceneRenderPass.h"
#import "NuoUniforms.h"



@protocol NuoRenderInFlight;
@class NuoMeshSceneRoot;
@class NuoLightSource;



@protocol ModelShadowMapProvider <NSObject>

- (id<MTLTexture>)depthMap;
- (id<MTLTexture>)shadowMap:(uint)index withMask:(NuoSceneMask)mask;

@end


/**
 *  provider of info that required by render a scene
 *
 *  shadow map is option for a ray tracing based renderer
 */

@interface ModelSceneParameters : NSObject < NuoMeshSceneParametersProvider >


@property (assign, nonatomic) BOOL cullEnabled;
@property (weak, nonatomic) NuoMeshSceneRoot* sceneRoot;
@property (weak, nonatomic) NSArray<NuoLightSource*>* lights;

@property (assign, nonatomic) NuoVectorFloat3 ambient;

@property (assign, nonatomic) float fieldOfView;
@property (assign, nonatomic) CGSize drawableSize;
@property (assign, nonatomic) NuoMatrixFloat44 viewMatrix;
@property (readonly, nonatomic) NuoMatrixFloat44 projection;


@property (weak, nonatomic) id<ModelShadowMapProvider> shadowMap;


- (instancetype)initWithDevice:(id<MTLDevice>)device;


- (void)updateLightCastWithInFlight:(id<NuoRenderInFlight>)inFlight
                        withContent:(NuoLightVertexUniforms*)content;

- (void)updateUniforms:(NuoCommandBuffer*)commandBuffer;


@end


