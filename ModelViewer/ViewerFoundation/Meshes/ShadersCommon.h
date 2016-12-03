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

struct Uniforms
{
    metal::float4x4 modelViewProjectionMatrix;
    metal::float4x4 modelViewMatrix;
    metal::float3x3 normalMatrix;
};

struct ModelCharacterUniforms
{
    float opacity;
};

struct LightUniform
{
    metal::float4 direction[4];
    float density[4];
    float ambientDensity;
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
    float specularPowerDisolve;
    float opacity;
};


metal::float4 fragment_light_tex_materialed_common(VertexFragmentCharacters vert,
                                                   metal::float3 normal,
                                                   constant LightUniform &lighting,
                                                   metal::float4 diffuseTexel);



#endif /* ShadersCommon_h */
