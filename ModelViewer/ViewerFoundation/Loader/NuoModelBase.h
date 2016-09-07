//
//  NuoModelBase.hpp
//  ModelViewer
//
//  Created by middleware on 8/28/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#ifndef NuoModelBase_hpp
#define NuoModelBase_hpp

#include <vector>
#include <string>

#include <simd/simd.h>



class NuoModelBase;
class NuoMaterial;


class NuoBox
{
public:
    float _centerX;
    float _centerY;
    float _centerZ;
    
    float _spanX;
    float _spanY;
    float _spanZ;
};



std::shared_ptr<NuoModelBase> CreateModel(std::string type, const NuoMaterial& material);



class NuoModelBase : public std::enable_shared_from_this<NuoModelBase>
{
protected:
    std::vector<uint32_t> _indices;
    
public:
    virtual void AddPosition(size_t sourceIndex, const std::vector<float>& positionsBuffer) = 0;
    virtual void AddNormal(size_t sourceIndex, const std::vector<float>& normalBuffer) = 0;
    virtual void AddTexCoord(size_t sourceIndex, const std::vector<float>& texCoordBuffer) = 0;
    
    virtual void SetTexturePath(const std::string texPath) = 0;
    virtual std::string GetTexturePath() = 0;
    
    virtual void GenerateIndices() = 0;
    virtual void GenerateNormals() = 0;
    
    virtual size_t GetVerticesNumber() = 0;
    virtual vector_float4 GetPosition(size_t index) = 0;
    virtual NuoBox GetBoundingBox();
    
    virtual void* Ptr() = 0;
    virtual size_t Length() = 0;
    virtual void* IndicesPtr();
    virtual size_t IndicesLength();
    
    virtual std::string TypeName() = 0;
};



template <class ItemBase>
class NuoModelCommon : public NuoModelBase
{
protected:
    std::vector<ItemBase> _buffer;

public:
    virtual void AddPosition(size_t sourceIndex, const std::vector<float>& positionsBuffer) override;
    virtual void AddNormal(size_t sourceIndex, const std::vector<float>& normalBuffer) override;
    
    virtual void GenerateIndices() override;
    virtual void GenerateNormals() override;
    
    virtual size_t GetVerticesNumber() override;
    virtual vector_float4 GetPosition(size_t index) override;
    
    virtual void* Ptr() override;
    virtual size_t Length() override;
};



struct NuoItemSimple
{
    vector_float4 _position;
    vector_float4 _normal;
    
    NuoItemSimple();
    
    bool operator == (const NuoItemSimple& other);
};



class NuoModelSimple : public NuoModelCommon<NuoItemSimple>
{
protected:
    
    
public:
    NuoModelSimple();
    
    virtual void AddTexCoord(size_t sourceIndex, const std::vector<float>& texCoordBuffer) override;
    
    virtual void SetTexturePath(const std::string texPath) override;
    virtual std::string GetTexturePath() override;
    
    virtual std::string TypeName() override;
};





template <class ItemBase>
void NuoModelCommon<ItemBase>::GenerateIndices()
{
    std::vector<ItemBase> compactBuffer;
    size_t checkBackward = 100;
    uint32_t indexCurrent = 0;
    
    _indices.clear();
    
    for (size_t i = 0; i < _buffer.size(); ++i)
    {
        const ItemBase& item = _buffer[i];
        
        if (item._normal.x != 0.0f || item._normal.y != 0.0f || item._normal.z != 0.0f)
        {
            auto search = std::find((compactBuffer.size() < checkBackward ? compactBuffer.begin() : compactBuffer.end() - checkBackward),
                                    compactBuffer.end(), item);
            if (search != std::end(compactBuffer))
            {
                uint32_t indexExist = (uint32_t)(search - std::begin(compactBuffer));
                _indices.push_back(indexExist);
            }
            else
            {
                compactBuffer.push_back(item);
                _indices.push_back(indexCurrent++);
            }
        }
        else
        {
            compactBuffer.push_back(item);
            _indices.push_back(indexCurrent++);
        }
    }
    
    _buffer.swap(compactBuffer);
}



template <class ItemBase>
void NuoModelCommon<ItemBase>::GenerateNormals()
{
    size_t indexCount = _indices.size();
    for (size_t i = 0; i < indexCount; i += 3)
    {
        uint32_t i0 = _indices[i];
        uint32_t i1 = _indices[i + 1];
        uint32_t i2 = _indices[i + 2];
        
        ItemBase *v0 = &_buffer[i0];
        ItemBase *v1 = &_buffer[i1];
        ItemBase *v2 = &_buffer[i2];
        
        vector_float3 p0 = v0->_position.xyz;
        vector_float3 p1 = v1->_position.xyz;
        vector_float3 p2 = v2->_position.xyz;
        
        vector_float3 cross = vector_cross((p1 - p0), (p2 - p0));
        vector_float4 cross4 = { cross.x, cross.y, cross.z, 0 };
        
        v0->_normal += cross4;
        v1->_normal += cross4;
        v2->_normal += cross4;
    }
    
    for (size_t i = 0; i < _buffer.size(); ++i)
    {
        _buffer[i]._normal = vector_normalize(_buffer[i]._normal);
    }
}



template <class ItemBase>
void NuoModelCommon<ItemBase>::AddPosition(size_t sourceIndex, const std::vector<float>& positionsBuffer)
{
    size_t sourceOffset = sourceIndex * 3;
    
    ItemBase newItem;
    
    newItem._position.x = positionsBuffer[sourceOffset];
    newItem._position.y = positionsBuffer[sourceOffset + 1];
    newItem._position.z = positionsBuffer[sourceOffset + 2];
    newItem._position.w = 1.0f;
    
    _buffer.push_back(newItem);
}



template <class ItemBase>
void NuoModelCommon<ItemBase>::AddNormal(size_t sourceIndex, const std::vector<float>& normalBuffer)
{
    size_t sourceOffset = sourceIndex * 3;
    size_t targetOffset = _buffer.size() - 1;
    
    _buffer[targetOffset]._normal.x = normalBuffer[sourceOffset];
    _buffer[targetOffset]._normal.y = normalBuffer[sourceOffset + 1];
    _buffer[targetOffset]._normal.z = normalBuffer[sourceOffset + 2];
    _buffer[targetOffset]._normal.w = 0.0f;
}



template <class ItemBase>
size_t NuoModelCommon<ItemBase>::GetVerticesNumber()
{
    return _buffer.size();
}



template <class ItemBase>
vector_float4 NuoModelCommon<ItemBase>::GetPosition(size_t index)
{
    return _buffer[index]._position;
}



template <class ItemBase>
void* NuoModelCommon<ItemBase>::Ptr()
{
    return (void*)_buffer.data();
}


template <class ItemBase>
size_t NuoModelCommon<ItemBase>::Length()
{
    return _buffer.size() * sizeof(ItemBase);
}



#endif /* NuoModelBase_hpp */
