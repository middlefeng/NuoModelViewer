#include <metal_stdlib>
#include <metal_matrix>

#include "NuoUniforms.h"

using namespace metal;

struct Vertex
{
    float4 position;
};

struct ProjectedVertex
{
    float4 position [[position]];
};


vertex ProjectedVertex project_cube(device Vertex *vertices [[buffer(0)]],
                                    constant ModelUniforms& uniforms [[buffer(1)]],
                                    uint vid [[vertex_id]])
{
    ProjectedVertex outVert;
    outVert.position = vertices[vid].position * uniforms.modelViewProjectionMatrix;
    
    return outVert;
}


fragment float4 fragment_cube_texutred(ProjectedVertex vert [[stage_in]]/*,
                                                                         texture2d<float> texture [[texture(0)]],
                                                                         sampler samplr [[sampler(0)]]*/)
{
    return float4(0.0, 0.0, 0.0, 1.0);
    //float4 color = texture.sample(samplr, vert.texCoord);
    //return color;
}
