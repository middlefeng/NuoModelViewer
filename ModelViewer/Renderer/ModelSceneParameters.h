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

class NuoBounds;



@protocol ModelShadowMapProvider <NSObject>

- (id<MTLTexture>)shadowMap:(uint)index withMask:(NuoSceneMask)mask;

@end


/**
 *  app level implementation to the provider protocol of info that required by render a scene
 *
 *  note that almost none of the properties or methods defined below blong to the protocol. they
 *  are all app-specific method which help to calculate the required parameters
 *
 *  also note that this provider implementation does not hold a reference to the app level centrialized
 *  model. it is preferred be dedicated to parameter buffers management, and information are synced
 *  through a set of "update...." methods.
 */

@interface ModelSceneParameters : NSObject < NuoMeshSceneParametersProvider >


@property (assign, nonatomic) BOOL cullEnabled;

@property (assign, nonatomic) NuoVectorFloat3 ambient;

@property (assign, nonatomic) float fieldOfView;
@property (assign, nonatomic) CGSize drawableSize;
@property (readonly, nonatomic) NuoMatrixFloat44 projection;


/**
 *  unlike most parameters, shadow map management is a bit too complicated to be handled in a "update..." method.
 *  so a shadow map provider protocol is implemented by a renderer that generates them in the course of rendering.
 *
 *  note that this is an app-level protocol rather than a foundation-level one. simpler app would provide shadow
 *  maps in their ModelSceneParameters implementation directly
 */
@property (weak, nonatomic) id<ModelShadowMapProvider> shadowMap;


- (instancetype)initWithDevice:(id<MTLDevice>)device;


- (void)updateLightCastWithInFlight:(id<NuoRenderInFlight>)inFlight
                        withContent:(NuoLightVertexUniforms*)content;

- (void)updateUniforms:(NuoCommandBuffer*)commandBuffer withBounds:(const NuoBounds&)bounds
              withView:(const NuoMatrixFloat44&)viewMatrix withLights:(NSArray<NuoLightSource*>*)lights;


@end


