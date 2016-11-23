//
//  NuoModelTextured.hpp
//  ModelViewer
//
//  Created by middleware on 9/5/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#ifndef NuoModelTextured_hpp
#define NuoModelTextured_hpp


#include "NuoModelBase.h"


struct NuoItemTextured
{
    vector_float4 _position;
    vector_float4 _normal;
    vector_float2 _texCoord;
    
    NuoItemTextured();
    
    bool operator == (const NuoItemTextured& other);
};



template <class ItemBase>
class NuoModelTextureBase : virtual public NuoModelCommon<ItemBase>
{
protected:
    std::string _texPathDiffuse;
    bool _checkTransparency;
    
    std::string _texPathOpacity;
    
public:
    
    virtual void AddTexCoord(size_t sourceIndex, const std::vector<float>& texCoordBuffer) override;
    
    virtual void SetTexturePathDiffuse(const std::string texPath) override;
    virtual std::string GetTexturePathDiffuse() override;
    
    virtual void SetTexturePathOpacity(const std::string texPath) override;
    virtual std::string GetTexturePathOpacity() override;
    
    void SetCheckTransparency(bool check);
};



template <class ItemBase>
class NuoModelTexturedWithTangentBase : virtual public NuoModelTextureBase<ItemBase>
{
protected:
    std::string _texPathBump;
    
public:
    
    virtual void GenerateTangents() override;
    virtual void SetTexturePathBump(const std::string texPath) override;
    virtual std::string GetTexturePathBump() override;
};




class NuoModelTextured : public NuoModelTextureBase<NuoItemTextured>
{
public:
    virtual void AddMaterial(const NuoMaterial& material) override;
    virtual bool HasTransparent() override;
    
    virtual void GenerateTangents() override;
    
    virtual void SetTexturePathOpacity(const std::string texPath) override;
    virtual std::string GetTexturePathOpacity() override;
    virtual void SetTexturePathBump(const std::string texPath) override;
    virtual std::string GetTexturePathBump() override;
};



template <class ItemBase>
void NuoModelTextureBase<ItemBase>::AddTexCoord(size_t sourceIndex, const std::vector<float>& texCoordBuffer)
{
    size_t sourceOffset = sourceIndex * 2;
    size_t targetOffset = NuoModelCommon<ItemBase>::_buffer.size() - 1;
    
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._texCoord.x = texCoordBuffer[sourceOffset];
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._texCoord.y = texCoordBuffer[sourceOffset + 1];
}


template <class ItemBase>
void NuoModelTextureBase<ItemBase>::SetTexturePathDiffuse(const std::string texPath)
{
    _texPathDiffuse = texPath;
}



template <class ItemBase>
void NuoModelTextureBase<ItemBase>::SetCheckTransparency(bool check)
{
    _checkTransparency = check;
}

template <class ItemBase>
std::string NuoModelTextureBase<ItemBase>::GetTexturePathDiffuse()
{
    return _texPathDiffuse;
}


template <class ItemBase>
void NuoModelTextureBase<ItemBase>::SetTexturePathOpacity(const std::string texPath)
{
    _texPathOpacity = texPath;
}


template <class ItemBase>
std::string NuoModelTextureBase<ItemBase>::GetTexturePathOpacity()
{
    return _texPathOpacity;
}


/* http://answers.unity3d.com/questions/7789/calculating-tangents-vector4.html */

template <class ItemBase>
void NuoModelTexturedWithTangentBase<ItemBase>::GenerateTangents()
{
    std::vector<uint32_t>& indices = NuoModelCommon<ItemBase>::_indices;
    std::vector<ItemBase>& buffer = NuoModelCommon<ItemBase>::_buffer;
    
    std::vector<vector_float3> tan1(buffer.size());
    std::vector<vector_float3> tan2(buffer.size());
    std::vector<vector_float4> tangents(buffer.size());
    
    memset(tan1.data(), 0, sizeof(vector_float3) * tan1.size());
    memset(tan2.data(), 0, sizeof(vector_float3) * tan2.size());
    memset(tangents.data(), 0, sizeof(vector_float4) * tangents.size());
    
    for (size_t a = 0; a < indices.size(); a += 3)
    {
        uint32_t index1 = indices[a];
        uint32_t index2 = indices[a + 1];
        uint32_t index3 = indices[a + 2];
        
        vector_float4 v1 = buffer[index1]._position;
        vector_float4 v2 = buffer[index2]._position;
        vector_float4 v3 = buffer[index3]._position;
        
        vector_float2 w1 = buffer[index1]._texCoord;
        vector_float2 w2 = buffer[index2]._texCoord;
        vector_float2 w3 = buffer[index3]._texCoord;
        
        float x1 = v2.x - v1.x;
        float x2 = v3.x - v1.x;
        float y1 = v2.y - v1.y;
        float y2 = v3.y - v1.y;
        float z1 = v2.z - v1.z;
        float z2 = v3.z - v1.z;
        float s1 = w2.x - w1.x;
        float s2 = w3.x - w1.x;
        float t1 = w2.y - w1.y;
        float t2 = w3.y - w1.y;
        float r = 1.0f / (s1 * t2 - s2 * t1);
        vector_float3 sdir = vector_float3 { (t2 * x1 - t1 * x2) * r, (t2 * y1 - t1 * y2) * r, (t2 * z1 - t1 * z2) * r };
        vector_float3 tdir = vector_float3 { (s1 * x2 - s2 * x1) * r, (s1 * y2 - s2 * y1) * r, (s1 * z2 - s2 * z1) * r };
        
        tan1[index1] += sdir;
        tan1[index2] += sdir;
        tan1[index3] += sdir;
        tan2[index1] += tdir;
        tan2[index2] += tdir;
        tan2[index3] += tdir;
    }
    
    for (size_t a = 0; a < buffer.size(); ++a)
    {
        vector_float3 n = buffer[a]._normal.xyz;
        vector_float3 t = tan1[a];
        vector_float3 tmp = vector_normalize(t - n * vector_dot(n, t));
        buffer[a]._tangent = vector_float4 { tmp.x, tmp.y, tmp.z, 0 };
        buffer[a]._tangent.w = vector_dot(vector_cross(n, t), tan2[a]) < 0.0f ? -1.0f : 1.0f;
    }
}



template <class ItemBase>
void NuoModelTexturedWithTangentBase<ItemBase>::SetTexturePathBump(const std::string texPath)
{
    _texPathBump = texPath;
}


template <class ItemBase>
std::string NuoModelTexturedWithTangentBase<ItemBase>::GetTexturePathBump()
{
    return _texPathBump;
}






#endif /* NuoModelTextured_hpp */
