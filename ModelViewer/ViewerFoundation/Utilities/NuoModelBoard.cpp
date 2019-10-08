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
    : NuoModelBoardBase<NuoItemSimple>(width, height, thickness),
      _diffuse(0.15, 0.15, 0.15), _specular(0, 0, 0)
{
}


void NuoModelBoard::SetDiffuse(const NuoVectorFloat3& diffuse)
{
    _diffuse = diffuse;
}


const NuoVectorFloat3& NuoModelBoard::GetDiffuse()
{
    return _diffuse;
}


NuoGlobalBuffers NuoModelBoard::GetGlobalBuffers() const
{
    NuoGlobalBuffers result;
    
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
            
            material.diffuseColor = _diffuse._vector;
            material.specularColor = _specular._vector;
            material.shinessDisolveIllum = NuoVectorFloat3(1, 1, 2)._vector;
            
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


