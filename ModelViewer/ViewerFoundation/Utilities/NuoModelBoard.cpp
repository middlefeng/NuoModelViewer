//
//  NuoModelCube.cpp
//  ModelViewer
//
//  Created by middleware on 5/22/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#include "NuoModelBoard.h"




NuoModelBoard::NuoModelBoard(float width, float height, float thickness)
    : NuoModelBoardBase<NuoItemSimple>(width, height, thickness)
{
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


