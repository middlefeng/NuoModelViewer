//
//  ShadowMapRenderer.m
//  ModelViewer
//
//  Created by middleware on 1/16/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "ShadowMapRenderer.h"
#import "LightSource.h"

#include "NuoMesh.h"
#include "NuoUniforms.h"
#include "NuoMathUtilities.h"



@interface ShadowMapRenderer()

@property (nonatomic, strong) NSArray<id<MTLBuffer>>* modelUniformBuffers;

@end



@implementation ShadowMapRenderer


- (void)updateUniformsForView
{
    vector_float3 center = {0, 0, 0};
    vector_float4 lightAsEye = {0, 0, 1, 0};
    vector_float3 up = {0, 1, 0};
    
    LightSource* lightSource = _lightSource;
    const matrix_float4x4 lightAsEyeMatrix = matrix_rotate(lightSource.lightingRotationX,
                                                           lightSource.lightingRotationY);
    lightAsEye = matrix_multiply(lightAsEyeMatrix, lightAsEye);
    vector_float3 lightAsEye3 = {lightAsEye.x, lightAsEye.y, lightAsEye.z};
    const matrix_float4x4 viewMatrix = matrix_lookAt(lightAsEye3, center, up);
    
    float meshRadius = _meshMaxSpan / 2.0;
    const matrix_float4x4 projectionMatrix = matrix_float4x4_orthor(-meshRadius, meshRadius,
                                                                    meshRadius, -meshRadius,
                                                                    -meshRadius, meshRadius);
    
    ModelUniforms uniforms;
    uniforms.modelViewMatrix = matrix_multiply(viewMatrix, _modelMatrix);
    uniforms.modelViewProjectionMatrix = matrix_multiply(projectionMatrix, uniforms.modelViewMatrix);
    uniforms.normalMatrix = matrix_float4x4_extract_linear(uniforms.modelViewMatrix);
}


@end
