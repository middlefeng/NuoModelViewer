//
//  NuoShadowMapRenderer.h
//  ModelViewer
//
//  Created by middleware on 1/16/17.
//  Copyright © 2017 middleware. All rights reserved.
//



#import <Foundation/Foundation.h>

#import "NuoRenderPass.h"
#import "NuoMathVector.h"


@class NuoLightSource;
@class NuoMesh;
@class NuoShadowMapTarget;


@interface NuoShadowMapRenderer : NuoRenderPass

/**
 *  The light source for which the shadow map is generated for.
 */
@property (nonatomic, weak) NuoLightSource* lightSource;

/**
 *  Scene model. Be weak reference because the owner should be the model render.
 */
@property (nonatomic, weak) NSArray<NuoMesh*>* meshes;

/**
 *  Shadow map, the depth texture from the view point of the light source.
 */
@property (nonatomic, strong) NuoShadowMapTarget* shadowMap;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue withName:(NSString*)name;


/**
 *  The projection matrix from the view point of the lightSource.
 */
- (const NuoMatrixFloat44&)lightCastMatrix;

/**
 *  The transform matrix which transform vector (0, 0, 1) into the direction of light
 */
- (const NuoMatrixFloat44&)lightDirectionMatrix;


@end
