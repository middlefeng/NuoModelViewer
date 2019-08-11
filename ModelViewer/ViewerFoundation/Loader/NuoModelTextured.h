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
    NuoVectorFloat4::_typeTrait::_vectorType _position;
    NuoVectorFloat4::_typeTrait::_vectorType _normal;
    NuoVectorFloat2::_typeTrait::_vectorType _texCoord;
    
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
    
    virtual void GenerateIndices() override;
    
    virtual void GenerateTangents() override;
    virtual void SetTexturePathBump(const std::string texPath) override;
    virtual std::string GetTexturePathBump() override;
};




class NuoModelTextured : virtual public NuoModelTextureBase<NuoItemTextured>
{
public:
    
    IMPL_CLONE(NuoModelTextured);
    
    virtual void AddMaterial(const NuoMaterial& material) override;
    virtual bool HasTransparent() override;
    virtual std::shared_ptr<NuoMaterial> GetUnifiedMaterial() override;
    virtual void UpdateBufferWithUnifiedMaterial() override;
    virtual NuoMaterial GetMaterial(size_t primtiveIndex) const override;
    virtual NuoGlobalBuffers GetGlobalBuffers() const override;
    
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
    
    std::vector<NuoVectorFloat3> tan1(buffer.size());
    std::vector<NuoVectorFloat3> tan2(buffer.size());
    std::vector<NuoVectorFloat4> tangents(buffer.size());
    
    memset(tan1.data(), 0, sizeof(NuoVectorFloat3) * tan1.size());
    memset(tan2.data(), 0, sizeof(NuoVectorFloat3) * tan2.size());
    memset(tangents.data(), 0, sizeof(NuoVectorFloat4) * tangents.size());
    
    for (size_t a = 0; a < indices.size(); a += 3)
    {
        uint32_t index1 = indices[a];
        uint32_t index2 = indices[a + 1];
        uint32_t index3 = indices[a + 2];
        
        NuoVectorFloat4 v1(buffer[index1]._position);
        NuoVectorFloat4 v2(buffer[index2]._position);
        NuoVectorFloat4 v3(buffer[index3]._position);
        
        NuoVectorFloat2 w1(buffer[index1]._texCoord);
        NuoVectorFloat2 w2(buffer[index2]._texCoord);
        NuoVectorFloat2 w3(buffer[index3]._texCoord);
        
        float x1 = v2.x() - v1.x();
        float x2 = v3.x() - v1.x();
        float y1 = v2.y() - v1.y();
        float y2 = v3.y() - v1.y();
        float z1 = v2.z() - v1.z();
        float z2 = v3.z() - v1.z();
        float s1 = w2.x() - w1.x();
        float s2 = w3.x() - w1.x();
        float t1 = w2.y() - w1.y();
        float t2 = w3.y() - w1.y();
        
        // a crude way to eliminate NaN
        float div = (s1 * t2 - s2 * t1);
        float r = 1.0f; if (fabs(div) > 1e-9) r = 1.0 / div;
        
        NuoVectorFloat3 sdir = NuoVectorFloat3((t2 * x1 - t1 * x2) * r, (t2 * y1 - t1 * y2) * r, (t2 * z1 - t1 * z2) * r);
        NuoVectorFloat3 tdir = NuoVectorFloat3((s1 * x2 - s2 * x1) * r, (s1 * y2 - s2 * y1) * r, (s1 * z2 - s2 * z1) * r);
        
        tan1[index1] = tan1[index1] + sdir;
        tan1[index2] = tan1[index2] + sdir;
        tan1[index3] = tan1[index3] + sdir;
        tan2[index1] = tan2[index1] + tdir;
        tan2[index2] = tan2[index2] + tdir;
        tan2[index3] = tan2[index3] + tdir;
    }
    
    for (size_t a = 0; a < buffer.size(); ++a)
    {
        NuoVectorFloat3 n = NuoVectorFloat3(buffer[a]._normal.x, buffer[a]._normal.y, buffer[a]._normal.z);
        NuoVectorFloat3 t = tan1[a];
        t = (t - n * NuoDot(n, t)).Normalize();
        buffer[a]._tangent = NuoVectorFloat4(t.x(), t.y(), t.z(), 0)._vector;
        
        // not full sure this is completely right because somehow the Y of normal-texture need to
        // be negated
        //
        NuoVectorFloat3 b = tan2[a];
        b = (b - (b * NuoDot(n, b)) - (t * NuoDot(t, b))).Normalize();
        buffer[a]._bitangent = NuoVectorFloat4(b.x(), b.y(), b.z(), 0)._vector;
    }
}



template <class ItemBase>
void NuoModelTexturedWithTangentBase<ItemBase>::GenerateIndices()
{
    // used to pass "false" because some all-black artifacts were considered caused by the
    // buffer-index compacting. turns out that was because of the NaN handling.
    //
    NuoModelCommon<ItemBase>::DoGenerateIndices(true);
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
