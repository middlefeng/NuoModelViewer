//
//  ShadersBoardImaged.metal
//  ModelViewer
//
//  Created by middleware on 6/12/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#include <metal_stdlib>

#include "NuoUniforms.h"
#include "NuoMeshUniform.h"

using namespace metal;

struct Vertex
{
    float4 position;
    float4 normal;
};

struct ProjectedVertex
{
    float4 position [[position]];
    float2 textureCoord;
};

vertex ProjectedVertex vertex_project_board_image(device Vertex *vertices [[buffer(0)]],
                                                  constant NuoUniforms &uniforms [[buffer(1)]],
                                                  constant NuoMeshUniforms &meshUniform [[buffer(3)]],
                                                  uint vid [[vertex_id]])
{
    ProjectedVertex outVert;
    float4 meshPosition = meshUniform.transform * vertices[vid].position;
    
    outVert.position = uniforms.viewProjectionMatrix * meshPosition;
    
    outVert.textureCoord.x = (sign(vertices[vid].position.x) + 1.0) / 2.0;
    outVert.textureCoord.y = (sign(vertices[vid].position.y) + 1.0) / 2.0;
    
    return outVert;
}


fragment float4 fragment_board_image(ProjectedVertex vert           [[stage_in]],
                                     texture2d<float> imageTexture  [[texture(2)]],
                                     sampler texSampler             [[sampler(0)]])
{
    return imageTexture.sample(texSampler, vert.textureCoord);
}


