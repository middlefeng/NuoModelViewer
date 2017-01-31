//
//  NuoModelTextured.cpp
//  ModelViewer
//
//  Created by middleware on 9/5/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#include "NuoModelTextured.h"
#include "NuoTypes.h"




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
