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




struct LightUniform
{
    metal::float4 direction;
    float density;
};

struct Light
{
    metal::float3 ambientColor;
    metal::float3 diffuseColor;
    metal::float3 specularColor;
};

constant Light light = {
    .ambientColor = { 0.28, 0.28, 0.28 },
    .diffuseColor = { 1, 1, 1 },
    .specularColor = { 0.5, 0.5, 0.5 }
};



#endif /* ShadersCommon_h */
