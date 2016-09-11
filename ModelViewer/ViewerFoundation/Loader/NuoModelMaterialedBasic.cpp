//
//  NuoModelMaterialed.cpp
//  ModelViewer
//
//  Created by dfeng on 9/7/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#include "NuoModelMaterialedBasic.h"
#include "NuoTypes.h"


NuoItemMaterialedTexturedBasic::NuoItemMaterialedTexturedBasic() :
    _position(0), _normal(0), _texCoord(0),
    _ambient(0), _diffuse(0), _specular(0)
{
}


bool NuoItemMaterialedTexturedBasic::operator == (const NuoItemMaterialedTexturedBasic& i2)
{
    return
        (_position.x == i2._position.x) &&
        (_position.y == i2._position.y) &&
        (_position.z == i2._position.z) &&
        (_normal.x == i2._normal.x) &&
        (_normal.y == i2._normal.y) &&
        (_normal.z == i2._normal.z) &&
    
        (_ambient.x == i2._ambient.x) &&
        (_ambient.y == i2._ambient.y) &&
        (_ambient.z == i2._ambient.z) &&
        (_diffuse.x == i2._diffuse.x) &&
        (_diffuse.y == i2._diffuse.y) &&
        (_diffuse.z == i2._diffuse.z) &&
        (_specular.x == i2._specular.x) &&
        (_specular.y == i2._specular.y) &&
        (_specular.z == i2._specular.z) &&
    
        (_texCoord.x == i2._texCoord.x) &&
        (_texCoord.y == i2._texCoord.y);
}



NuoItemMaterialedBasic::NuoItemMaterialedBasic() :
    _position(0), _normal(0),
    _ambient(0), _diffuse(0), _specular(0)
{
}


bool NuoItemMaterialedBasic::operator == (const NuoItemMaterialedBasic& i2)
{
    return
        (_position.x == i2._position.x) &&
        (_position.y == i2._position.y) &&
        (_position.z == i2._position.z) &&
        (_normal.x == i2._normal.x) &&
        (_normal.y == i2._normal.y) &&
        (_normal.z == i2._normal.z) &&
        
        (_ambient.x == i2._ambient.x) &&
        (_ambient.y == i2._ambient.y) &&
        (_ambient.z == i2._ambient.z) &&
        (_diffuse.x == i2._diffuse.x) &&
        (_diffuse.y == i2._diffuse.y) &&
        (_diffuse.z == i2._diffuse.z) &&
        (_specular.x == i2._specular.x) &&
        (_specular.y == i2._specular.y) &&
        (_specular.z == i2._specular.z);
}




std::string NuoModelMaterialedTextured::TypeName()
{
    return kNuoModelType_Textured_A_Materialed;
}


void NuoModelMaterialed::SetTexturePath(const std::string texPath)
{
}



std::string NuoModelMaterialed::GetTexturePath()
{
    return "";
}


void NuoModelMaterialed::AddTexCoord(size_t sourceIndex, const std::vector<float>& texCoordBuffer)
{
}


std::string NuoModelMaterialed::TypeName()
{
    return kNuoModelType_Materialed;
}

