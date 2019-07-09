//
//  NuoGlobalBuffers.cpp
//  ModelViewer
//
//  Created by Dong on 7/9/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#include "NuoGlobalBuffers.h"



void NuoGlobalBuffers::Union(const NuoGlobalBuffers& other)
{
    const uint32_t prevCount = (uint32_t)_vertices.size();
    _vertices.insert(_vertices.end(), other._vertices.begin(), other._vertices.end());
    _materials.insert(_materials.end(), other._materials.begin(), other._materials.end());
    _textureMap.insert(_textureMap.end(), other._textureMap.begin(), other._textureMap.end());
    
    for (uint32_t i = 0; i < other._indices.size(); ++i)
        _indices.push_back(other._indices[i] + prevCount);
}



void NuoGlobalBuffers::TransformPosition(const NuoMatrixFloat44 &trans)
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



void NuoGlobalBuffers::TransformVector(const NuoMatrixFloat33 &trans)
{
    for (auto& material : _materials)
    {
        NuoVectorFloat3 vertexToTrans = trans * NuoVectorFloat3(material.normal);
        
        material.normal.x = vertexToTrans.x();
        material.normal.y = vertexToTrans.y();
        material.normal.z = vertexToTrans.z();
    }
}



void NuoGlobalBuffers::Clear()
{
    _vertices.clear();
    _materials.clear();
    
    _indices.clear();
    _textureMap.clear();
}
