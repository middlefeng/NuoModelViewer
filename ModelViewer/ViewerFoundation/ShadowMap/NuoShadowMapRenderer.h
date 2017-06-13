//
//  NuoShadowMapRenderer.h
//  ModelViewer
//
//  Created by middleware on 1/16/17.
//  Copyright © 2017 middleware. All rights reserved.
//



#import <Foundation/Foundation.h>
#import <simd/simd.h>

#import "NuoRenderPass.h"


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


- (instancetype)initWithDevice:(id<MTLDevice>)device withName:(NSString*)name;


/**
 *  The projection matrix from the view point of the lightSource.
 */
- (matrix_float4x4)lightCastMatrix;


@end
