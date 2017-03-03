//
//  ShadersCube.metal
//  ModelViewer
//
//  Created by dfeng on 3/3/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#include <metal_stdlib>

#include "ShadersSpecialCommon.h"
#include "NuoUniforms.h"


using namespace metal;


struct ProjectedVertex
{
    metal::float4 position [[position]];
    metal::float3 texCoords;
};



vertex ProjectedVertex vertex_cube(device Vertex *vertices            [[buffer(0)]],
                                   constant ModelUniforms &uniforms   [[buffer(1)]],
                                   uint vid                           [[vertex_id]])
{
    float4 position = vertices[vid].position;
    
    ProjectedVertex outVert;
    outVert.position = uniforms.modelViewProjectionMatrix * position;
    outVert.texCoords = position.xyz;
    return outVert;
}



fragment half4 fragment_cube(ProjectedVertex vert          [[stage_in]],
                             texturecube<half> cubeTexture [[texture(0)]],
                             sampler cubeSampler           [[sampler(0)]])
{
    float3 texCoords = float3(vert.texCoords.x, vert.texCoords.y, -vert.texCoords.z);
    return cubeTexture.sample(cubeSampler, texCoords);
}
