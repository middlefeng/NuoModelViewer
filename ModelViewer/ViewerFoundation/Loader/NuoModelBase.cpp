//
//  NuoModelBase.cpp
//  ModelViewer
//
//  Created by middleware on 8/28/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#include "NuoModelBase.h"
#include "NuoModelTextured.h"
#include "NuoModelMaterialedBasic.h"
#include "NuoMaterial.h"



template <>
bool ItemTexCoordEequal<NuoItemSimple>(const NuoItemSimple& i1, const NuoItemSimple& i2)
{
    return true;
}


std::shared_ptr<NuoModelBase> CreateModel(const NuoModelOption& options, const NuoMaterial& material,
                                          const std::string& modelItemName)
{
    bool textured = options._textured && material.HasTextureDiffuse();
    
    if (!textured && !options._basicMaterialized)
    {
        auto model = std::make_shared<NuoModelSimple>();
        model->SetName(modelItemName);
        return model;
    }
    else if (textured && !options._basicMaterialized)
    {
        auto model = std::make_shared<NuoModelTextured>();
        model->SetName(modelItemName);
        model->SetCheckTransparency(options._textureEmbedMaterialTransparency);
        return model;
    }
    else if (textured && options._basicMaterialized)
    {
        if (material.HasTextureBump() && options._texturedBump)
        {
            auto model = std::make_shared<NuoModelMaterialedBumpedTextured>();
            model->SetName(modelItemName);
            model->SetCheckTransparency(true);
            return model;
        }
        else
        {
            auto model = std::make_shared<NuoModelMaterialedTextured>();
            model->SetName(modelItemName);
            model->SetCheckTransparency(true);
            return model;
        }
    }
    else if (options._basicMaterialized)
    {
        auto model = std::make_shared<NuoModelMaterialed>();
        model->SetName(modelItemName);
        return model;
    }
    else
    {
        auto model = std::shared_ptr<NuoModelBase>();
        return model;
    }
}



void GlobalBuffers::Union(const GlobalBuffers& other)
{
    const uint32_t prevCount = (uint32_t)_vertices.size();
    _vertices.insert(_vertices.end(), other._vertices.begin(), other._vertices.end());
    _materials.insert(_materials.end(), other._materials.begin(), other._materials.end());
    _textureMap.insert(_textureMap.end(), other._textureMap.begin(), other._textureMap.end());
    
    for (uint32_t i = 0; i < other._indices.size(); ++i)
        _indices.push_back(other._indices[i] + prevCount);
}



void GlobalBuffers::TransformPosition(const NuoMatrixFloat44 &trans)
{
    for (auto& vertex : _vertices)
    {
        NuoVectorFloat4 vertexToTrans = NuoVectorFloat4(vertex.x, vertex.y, vertex.z, 1.0f);
        vertexToTrans = trans * vertexToTrans;
        
        vertex.x = vertexToTrans.x();
        vertex.y = vertexToTrans.y();
        vertex.z = vertexToTrans.z();
    }
}



void GlobalBuffers::TransformVector(const NuoMatrixFloat33 &trans)
{
    for (auto& material : _materials)
    {
        NuoVectorFloat3 vertexToTrans = trans * NuoVectorFloat3(material.normal);
        
        material.normal.x = vertexToTrans.x();
        material.normal.y = vertexToTrans.y();
        material.normal.z = vertexToTrans.z();
    }
}



void* NuoModelBase::IndicesPtr()
{
    return _indices.data();
}



size_t NuoModelBase::IndicesLength()
{
    return _indices.size() * sizeof(uint32_t);
}



NuoBounds NuoModelBase::GetBoundingBox()
{
    float xMin = 1e9f, xMax = -1e9f;
    float yMin = 1e9f, yMax = -1e9f;
    float zMin = 1e9f, zMax = -1e9f;
    
    for (size_t i = 0; i < GetVerticesNumber(); ++i)
    {
        NuoVectorFloat4 position = GetPosition(i);
        
        xMin = std::min(xMin, position.x());
        xMax = std::max(xMax, position.x());
        yMin = std::min(yMin, position.y());
        yMax = std::max(yMax, position.y());
        zMin = std::min(zMin, position.z());
        zMax = std::max(zMax, position.z());
    }
    
    NuoVectorFloat3 center((xMax + xMin) / 2.0f, (yMax + yMin) / 2.0f, (zMax + zMin) / 2.0f);
    NuoVectorFloat3 span(xMax - xMin, yMax - yMin, zMax - zMin);
    
    NuoBounds result;
    result._center = center;
    result._span = span;
    
    return result;
}



NuoItemSimple::NuoItemSimple() :
    _position(0), _normal(0)
{
}


bool NuoItemSimple::operator == (const NuoItemSimple& i2)
{
    return
        (_position.x == i2._position.x) &&
        (_position.y == i2._position.y) &&
        (_position.z == i2._position.z) &&
        (_normal.x == i2._normal.x) &&
        (_normal.y == i2._normal.y) &&
        (_normal.z == i2._normal.z);
}



NuoModelSimple::NuoModelSimple()
{
}


void NuoModelSimple::AddTexCoord(size_t sourceIndex, const std::vector<float>& texCoordBuffer)
{    
}


void NuoModelSimple::AddMaterial(const NuoMaterial& material)
{
}


void NuoModelSimple::GenerateTangents()
{
}


void NuoModelSimple::SetTexturePathDiffuse(const std::string texPath)
{
}



std::string NuoModelSimple::GetTexturePathDiffuse()
{
    return std::string();
}


void NuoModelSimple::SetTexturePathOpacity(const std::string texPath)
{
}


std::string NuoModelSimple::GetTexturePathOpacity()
{
    return std::string();
}


void NuoModelSimple::SetTexturePathBump(const std::string texPath)
{
}


std::string NuoModelSimple::GetTexturePathBump()
{
    return std::string();
}



NuoMaterial NuoModelSimple::GetMaterial(size_t primtiveIndex) const
{
    return NuoMaterial();
}



bool NuoModelSimple::HasTransparent()
{
    return false;
}



std::shared_ptr<NuoMaterial> NuoModelSimple::GetUnifiedMaterial()
{
    return nullptr;
}



void NuoModelSimple::UpdateBufferWithUnifiedMaterial()
{
}



