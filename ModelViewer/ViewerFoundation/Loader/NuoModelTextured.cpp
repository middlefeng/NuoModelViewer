//
//  NuoModelTextured.cpp
//  ModelViewer
//
//  Created by middleware on 9/5/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#include "NuoModelTextured.h"
#include "NuoMaterial.h"




NuoItemTextured::NuoItemTextured() :
    _position(0), _normal(0), _texCoord(0)
{
}


bool NuoItemTextured::operator == (const NuoItemTextured& i2)
{
    return
        (_position.x == i2._position.x) &&
        (_position.y == i2._position.y) &&
        (_position.z == i2._position.z) &&
        (_normal.x == i2._normal.x) &&
        (_normal.y == i2._normal.y) &&
        (_normal.z == i2._normal.z) &&
        (_texCoord.x == i2._texCoord.x) &&
        (_texCoord.y == i2._texCoord.y);
}



void NuoModelTextured::SetTexturePathOpacity(const std::string texPath)
{
}



std::string NuoModelTextured::GetTexturePathOpacity()
{
    return std::string();
}



bool NuoModelTextured::HasTransparent()
{
    return false;
}


void NuoModelTextured::GenerateTangents()
{
}


void NuoModelTextured::SetTexturePathBump(const std::string texPath)
{
}


std::string NuoModelTextured::GetTexturePathBump()
{
    return std::string();
}




void NuoModelTextured::AddMaterial(const NuoMaterial& material)
{
}



std::shared_ptr<NuoMaterial> NuoModelTextured::GetUnifiedMaterial()
{
    return nullptr;
}


void NuoModelTextured::UpdateBufferWithUnifiedMaterial()
{
}



NuoMaterial NuoModelTextured::GetMaterial(size_t primtiveIndex) const
{
    return NuoMaterial();
}


GlobalBuffers NuoModelTextured::GetGlobalBuffers() const
{
    GlobalBuffers result;
    
    for (const NuoItemTextured& item : _buffer)
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
            
            // the texture index is not available yet
            material.texCoord.x = item._texCoord.x;
            material.texCoord.y = item._texCoord.y;
            material.diffuseTex = -2;
            
            material.diffuseColor = NuoVectorFloat3(1, 1, 1)._vector;
            material.illuminate = 2;
            
            result._materials.push_back(material);
        }
    }
    
    result._indices = _indices;
    
    return result;
}
