//
//  ShadersCube.metal
//  ModelViewer
//
//  Created by dfeng on 3/3/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#include <metal_stdlib>

#include "NuoUniforms.h"


using namespace metal;



struct CubeVertex
{
    metal::float4 position;
    metal::float4 normal;
};


struct ProjectedVertex
{
    metal::float4 position [[position]];
    metal::float3 texCoords;
};



vertex ProjectedVertex vertex_cube(device CubeVertex *vertices        [[buffer(0)]],
                                   constant ModelUniforms &uniforms   [[buffer(1)]],
                                   uint vid                           [[vertex_id]])
{
    float4 position = vertices[vid].position;
    
    ProjectedVertex outVert;
    outVert.position = uniforms.modelViewProjectionMatrix * position;
    outVert.texCoords = float3(position.x, position.y, -position.z);
    return outVert;
}



fragment float4 fragment_cube(ProjectedVertex vert          [[stage_in]],
                             texturecube<float> cubeTexture [[texture(0)]],
                             sampler cubeSampler            [[sampler(0)]])
{
    return cubeTexture.sample(cubeSampler, vert.texCoords);
}
