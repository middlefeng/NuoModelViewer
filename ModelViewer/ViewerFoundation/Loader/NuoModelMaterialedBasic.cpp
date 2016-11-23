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


NuoItermMaterialedBumpedTextured::NuoItermMaterialedBumpedTextured() :
    _position(0), _normal(0), _tangent(0), _texCoord(0),
    _ambient(0), _diffuse(0), _specular(0)
{
}


bool NuoItermMaterialedBumpedTextured::operator == (const NuoItermMaterialedBumpedTextured& i2)
{
    return
        (_position.x == i2._position.x) &&
        (_position.y == i2._position.y) &&
        (_position.z == i2._position.z) &&
        (_normal.x == i2._normal.x) &&
        (_normal.y == i2._normal.y) &&
        (_normal.z == i2._normal.z) &&
        (_tangent.x == i2._tangent.x) &&
        (_tangent.y == i2._tangent.y) &&
        (_tangent.z == i2._tangent.z) &&
        (_tangent.w == i2._tangent.w) &&
    
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



NuoModelMaterialedTextured::NuoModelMaterialedTextured()
{
}



void NuoModelMaterialedTextured::GenerateTangents()
{
}


void NuoModelMaterialedTextured::SetTexturePathBump(const std::string texPath)
{
}


std::string NuoModelMaterialedTextured::GetTexturePathBump()
{
    return std::string();
}



void NuoModelMaterialed::SetTexturePathDiffuse(const std::string texPath)
{
}



std::string NuoModelMaterialed::GetTexturePathDiffuse()
{
    return "";
}


void NuoModelMaterialed::SetTexturePathOpacity(const std::string texPath)
{
}


std::string NuoModelMaterialed::GetTexturePathOpacity()
{
    return std::string();
}


void NuoModelMaterialed::AddTexCoord(size_t sourceIndex, const std::vector<float>& texCoordBuffer)
{
}


void NuoModelMaterialed::GenerateTangents()
{
}


void NuoModelMaterialed::SetTexturePathBump(const std::string texPath)
{
}


std::string NuoModelMaterialed::GetTexturePathBump()
{
    return std::string();
}

