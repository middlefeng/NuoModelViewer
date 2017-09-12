#include <metal_stdlib>
#include <metal_matrix>

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



struct ProjectedVertex
{
    float4 position [[position]];
    float2 texCoord;
};

vertex ProjectedVertex texture_project(device Vertex *vertices [[buffer(0)]],
                                       uint vid [[vertex_id]])
{
    ProjectedVertex outVert;
    outVert.position = vertices[vid].position;
    outVert.position.z = 0.5;
    outVert.position.w = 1.0;
    outVert.texCoord = vertices[vid].texCoord;
    
    return outVert;
}

fragment float4 fragment_texutre(ProjectedVertex vert [[stage_in]],
                                 texture2d<float> texture [[texture(0)]],
                                 sampler samplr [[sampler(0)]])
{
    float4 color = texture.sample(samplr, vert.texCoord);
    return color;
}


fragment float4 fragment_texutre_mix(ProjectedVertex vert [[stage_in]],
                                     texture2d<float> texture1 [[texture(0)]],
                                     texture2d<float> texture2 [[texture(1)]],
                                     constant TextureMixFragment& mixFragment [[buffer(0)]],
                                     sampler samplr [[sampler(0)]])
{
    float4 color;
    if (vert.texCoord.x > mixFragment.mixProportion)
        color = texture1.sample(samplr, vert.texCoord);
    else
        color = texture2.sample(samplr, vert.texCoord);
        
    return color;
}
