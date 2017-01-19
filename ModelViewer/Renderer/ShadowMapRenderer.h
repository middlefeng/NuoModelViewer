//
//  ShadowMapRenderer.h
//  ModelViewer
//
//  Created by middleware on 1/16/17.
//  Copyright © 2017 middleware. All rights reserved.
//



#import <Foundation/Foundation.h>
#import <simd/simd.h>

#import "NuoRenderPass.h"


@class LightSource;
@class NuoMesh;
@class NuoShadowMapTarget;


@interface ShadowMapRenderer : NuoRenderPass


@property (nonatomic, weak) LightSource* lightSource;
@property (nonatomic, assign) float meshMaxSpan;
@property (nonatomic, assign) matrix_float4x4 modelMatrix;

@property (nonatomic, strong) NuoShadowMapTarget* shadowMap;


@end
