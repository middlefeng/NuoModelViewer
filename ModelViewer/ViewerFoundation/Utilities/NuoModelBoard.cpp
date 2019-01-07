//
//  NuoModelCube.cpp
//  ModelViewer
//
//  Created by middleware on 5/22/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#include "NuoModelBoard.h"
#include "NuoMaterial.h"




NuoModelBoard::NuoModelBoard(float width, float height, float thickness)
    : NuoModelBoardBase<NuoItemSimple>(width, height, thickness)
{
}


NuoModelBoard::NuoModelBoard(const NuoBounds& bounds)
    : NuoModelBoardBase<NuoItemSimple>(bounds._span.x(),
                                       bounds._span.y(),
                                       bounds._span.z())
{
}


GlobalBuffers NuoModelBoard::GetGlobalBuffers() const
{
    GlobalBuffers result;
    
    for (const NuoItemSimple& item : NuoModelCommon<NuoItemSimple>::_buffer)
    {
        {
            NuoVectorFloat3::_typeTrait::_vectorType vector;
            vector.x = item._position.x;
            vector.y = item._position.y;
            vector.z = item._position.z;
            result._vertices.push_back(vector);
        }
        
        {
            NuoRayTracingMaterial material;
            
            material.normal.x = item._normal.x;
            material.normal.y = item._normal.y;
            material.normal.z = item._normal.z;
            
            // no texture
            material.texCoord = NuoVectorFloat3(0, 0, 0)._vector;
            material.diffuseTex = -1;
            
            // diffuse factor is used in ray tracing. set to 1.0 so the result illumination is relative to the
            // lighting strength (usually ambient). see more comments in the "illumination_blend()" fragment shader
            //
            material.diffuseColor = NuoVectorFloat3(1, 1, 1)._vector;
            material.illuminate = 2;
            
            result._materials.push_back(material);
        }
    }
    
    result._indices = NuoModelCommon<NuoItemSimple>::_indices;
    
    return result;
}



NuoModelBackDrop::NuoModelBackDrop(float width, float height, float thickness)
    : NuoModelBoardBase<NuoItemTextured>(width, height, thickness)
{
}


NuoModelBackDrop::NuoModelBackDrop(const NuoModelBackDrop& other)
    : NuoModelBoardBase<NuoItemTextured>(0, 0, 0)
{
}


void NuoModelBackDrop::AddMaterial(const NuoMaterial& material)
{
}


NuoMaterial NuoModelBackDrop::GetMaterial(size_t primtiveIndex) const
{
    return NuoMaterial();
}


bool NuoModelBackDrop::HasTransparent()
{
    return false;
}


void NuoModelBackDrop::GenerateTangents()
{
}


std::shared_ptr<NuoMaterial> NuoModelBackDrop::GetUnifiedMaterial()
{
    return nullptr;
}


void NuoModelBackDrop::UpdateBufferWithUnifiedMaterial()
{
}



void NuoModelBackDrop::SetTexturePathBump(const std::string texPath)
{
}


std::string NuoModelBackDrop::GetTexturePathBump()
{
    return std::string();
}


