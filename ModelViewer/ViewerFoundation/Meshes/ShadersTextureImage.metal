#include <metal_stdlib>
#include <metal_matrix>

#include "ShadersCommon.h"

using namespace metal;


struct Vertex
{
    metal::float4 position;
    metal::float2 texCoord;
};


struct TextureMixFragment
{
    float mixProportion;
};


struct ClearFragment
{
    float4 clearColor;
};


vertex PositionTextureSimple backdrop_project(device Vertex *vertices [[buffer(0)]],
                                              constant NuoUniforms& uniforms [[buffer(3)]],
                                              uint vid [[vertex_id]])
{
    PositionTextureSimple outVert;
    outVert.position = uniforms.viewMatrix * vertices[vid].position;
    outVert.position.z = 0.5;
    outVert.position.w = 1.0;
    outVert.texCoord = vertices[vid].texCoord;
    
    return outVert;
}


fragment float4 backdrop_texutre(PositionTextureSimple vert [[stage_in]],
                                 texture2d<float> texture [[texture(2)]],
                                 sampler samplr [[sampler(1)]])
{
    float4 color = texture.sample(samplr, vert.texCoord);
    return color;
}



vertex PositionTextureSimple texture_project(device Vertex *vertices [[buffer(0)]],
                                             uint vid [[vertex_id]])
{
    PositionTextureSimple outVert;
    outVert.position = vertices[vid].position;
    outVert.position.z = 1.0;
    outVert.position.w = 1.0;
    outVert.texCoord = vertices[vid].texCoord;
    
    return outVert;
}



fragment float4 fragment_clear(PositionTextureSimple vert [[stage_in]],
                               constant ClearFragment& clearFragment [[buffer(0)]])
{
    return clearFragment.clearColor;
}


fragment FragementScreenSpace fragement_clear_screen_space(PositionTextureSimple vert [[stage_in]],
                                                           constant ClearFragment& clearFragment [[buffer(0)]])
{
    FragementScreenSpace result;
    result.position = clearFragment.clearColor;
    result.normal = clearFragment.clearColor;;
    result.ambientColorFactor = clearFragment.clearColor;
    result.shadowOverlay = 0.0;
    
    return result;
}


fragment float4 fragment_texture(PositionTextureSimple vert [[stage_in]],
                                 texture2d<float> texture [[texture(0)]],
                                 sampler samplr [[sampler(0)]])
{
    float4 color = texture.sample(samplr, vert.texCoord);
    return color;
}


fragment float4 fragment_texture_mix(PositionTextureSimple vert [[stage_in]],
                                     texture2d<float> texture1 [[texture(0)]],
                                     texture2d<float> texture2 [[texture(1)]],
                                     constant TextureMixFragment& mixFragment [[buffer(0)]],
                                     sampler samplr [[sampler(0)]])
{
    float4 color;
    if (fabs(vert.texCoord.x - mixFragment.mixProportion) > 0.002)
    {
        if (vert.texCoord.x > mixFragment.mixProportion)
            color = texture1.sample(samplr, vert.texCoord);
        else
            color = texture2.sample(samplr, vert.texCoord);
    }
    else
    {
        float factor = (vert.texCoord.x - mixFragment.mixProportion + 0.002) / 0.004;
        color = texture1.sample(samplr, vert.texCoord) * factor + texture2.sample(samplr, vert.texCoord) * (1.0 - factor);
    }
        
    return color;
}
