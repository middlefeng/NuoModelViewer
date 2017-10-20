//
//  ShadersCommon.h
//  ModelViewer
//
//  Created by dfeng on 11/11/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#ifndef ShadersCommon_h
#define ShadersCommon_h

#include <metal_stdlib>
#include <metal_matrix>

#include "NuoUniforms.h"
#include "NuoMeshUniform.h"


struct Material
{
    metal::float3 ambientColor;
    metal::float3 diffuseColor;
    metal::float3 specularColor;
    float specularPower;
};

constant Material material = {
    .ambientColor = { 0.6, 0.6, 0.6 },
    .diffuseColor = { 0.6, 0.6, 0.6 },
    .specularColor = { 1, 1, 1 },
    .specularPower = 100
};

struct Light
{
    metal::float3 diffuseColor;
    metal::float3 specularColor;
};

constant Light light = {
    .diffuseColor = { 1, 1, 1 },
    .specularColor = { 0.5, 0.5, 0.5 }
};


struct VertexFragmentCharacters
{
    metal::float3 eye;
    
    metal::float3 diffuseColor;
    metal::float3 ambientColor;
    metal::float3 specularColor;
    float specularPower;
    float opacity;
    
    metal::float4 shadowPosition[2];
};


struct VertexScreenSpace
{
    metal::float4 projectedPosition [[position]];
    metal::float4 position;
    metal::float4 normal;
    metal::float2 texCoord;
    
    metal::float3 diffuseColorFactor;
    float opacity;
};


struct FragementScreenSpace
{
    // alpha channel is always 1.0
    //
    metal::float4 position              [[ color(0) ]];
    metal::float4 normal                [[ color(1) ]];
    
    // alpha channel is the material opacity (i.e. considering both vertex material and texture opacity).
    //
    // the blending is turned OFF so the alpha is that of the last rendered object (in the ordered rendering it's
    // a semi-translucent one if there is any). the color is "premultiplyed" by "hand" in the shader code.
    //
    // the premultiplication is mandatory because of the presence of MSAA. and the mutiplication must be done at the end
    // of the fragement shader, rather than deferred to after the texture sampling, otherwise the result is incorrect
    // because the order of MSAA and the multipication
    //
    metal::float4 ambientColorFactor    [[ color(2) ]];
};


/**
 *  output for depth only vertex shaders
 */
struct PositionSimple
{
    metal::float4 position [[position]];
};


/**
 *  output for screen-space shaders
 */
struct PositionTextureSimple
{
    metal::float4 position [[position]];
    metal::float2 texCoord;
};


constant bool kAlphaChannelInTexture            [[ function_constant(0) ]];
constant bool kAlphaChannelInSeparatedTexture   [[ function_constant(1) ]];
constant bool kPhysicallyReflection             [[ function_constant(2) ]];
constant bool kShadowOverlay                    [[ function_constant(3) ]];

constant bool kShadowPCSS                       [[ function_constant(4) ]];
constant bool kShadowPCF                        [[ function_constant(5) ]];

constant int  kMeshMode                         [[ function_constant(6) ]];



metal::float4 fragment_light_tex_materialed_common(VertexFragmentCharacters vert,
                                                   metal::float3 normal,
                                                   constant NuoLightUniforms &lighting,
                                                   metal::float4 diffuseTexel,
                                            #if METAL_2
                                                   metal::depth2d<float> shadowMap[2],
                                            #else
                                                   metal::depth2d<float> shadowMap0,
                                                   metal::depth2d<float> shadowMap1,
                                            #endif
                                                   metal::sampler samplr);


metal::float4 diffuse_common(metal::float4 diffuseTexel, float extraOpacity);


metal::float3 specular_common(metal::float3 materialSpecularColor, float materialSecularPower,
                              NuoLightParameterUniformField lightParams,
                              metal::float3 normal, metal::float3 halfway, float dotNL);


float shadow_coverage_common(metal::float4 shadowCastModelPostion,
                             NuoShadowParameterUniformField shadowParams, float shadowedSurfaceAngle, float shadowMapSampleRadius,
                             metal::depth2d<float> shadowMap, metal::sampler samplr);

metal::float2 rand(metal::float2 co);



#endif /* ShadersCommon_h */
