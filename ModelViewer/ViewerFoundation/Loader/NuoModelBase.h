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
#include <map>
#include <sys/types.h>

#include "NuoGlobalBuffers.h"
#include "NuoBounds.h"



class NuoModelBase;
class NuoMaterial;




class NuoModelOption
{
public:
    bool _textured;
    bool _textureEmbedMaterialTransparency;
    bool _texturedBump;
    
    bool _basicMaterialized;
    
    bool _physicallyReflection;
};



typedef std::shared_ptr<NuoModelBase> PNuoModelBase;



PNuoModelBase CreateModel(const NuoModelOption& options, const NuoMaterial& material,
                          const std::string& modelItemName);

template <class ItemBase>
class SmoothItem
{
    NuoVectorFloat4 _position;

public:
    SmoothItem(ItemBase& item);
    bool operator < (const SmoothItem& other) const;
};



template <class ItemBase>
SmoothItem<ItemBase>::SmoothItem(ItemBase& item)
{
    _position = item._position;
}



template <class ItemBase>
bool SmoothItem<ItemBase>::operator < (const SmoothItem<ItemBase>& other) const
{
#define compare_element(a) \
    if (a < other.a) return true; \
    if (a > other.a) return false;
    
    compare_element(_position.x());
    compare_element(_position.y());
    compare_element(_position.z());
    compare_element(_position.w());
    
    return false;
}


template <class ItemBase>
bool ItemTexCoordEequal(const ItemBase& i1, const ItemBase& i2)
{
    return  fabs(i1._texCoord.x - i2._texCoord.x) < 1e-3 &&
    fabs(i1._texCoord.y - i2._texCoord.y) < 1e-3;
}




class NuoModelBase : public std::enable_shared_from_this<NuoModelBase>
{
protected:
    std::string _name;
    std::vector<uint32_t> _indices;
    
public:
    
    virtual std::shared_ptr<NuoModelBase> Clone() const = 0;
    
    virtual void AddPosition(size_t sourceIndex, const std::vector<float>& positionsBuffer) = 0;
    virtual void AddNormal(size_t sourceIndex, const std::vector<float>& normalBuffer) = 0;
    virtual void AddTexCoord(size_t sourceIndex, const std::vector<float>& texCoordBuffer) = 0;
    virtual void AddMaterial(const NuoMaterial& material) = 0;
    
    virtual void SetTexturePathDiffuse(const std::string texPath) = 0;
    virtual std::string GetTexturePathDiffuse() = 0;
    virtual void SetTexturePathOpacity(const std::string texPath) = 0;
    virtual std::string GetTexturePathOpacity() = 0;
    virtual void SetTexturePathBump(const std::string texPath) = 0;
    virtual std::string GetTexturePathBump() = 0;
    
    virtual void GenerateIndices() = 0;
    virtual void GenerateNormals() = 0;
    virtual void GenerateTangents() = 0;
    
    virtual void SmoothSurface(float tolerance, bool texDiscontinuityOnly) = 0;
    
    virtual size_t GetVerticesNumber() const = 0;
    virtual size_t GetIndicesNumber() const = 0;
    virtual NuoVectorFloat4 GetPosition(size_t index) = 0;
    virtual NuoMaterial GetMaterial(size_t primtiveIndex) const = 0;
    virtual NuoBounds GetBoundingBox();
    
    virtual NuoGlobalBuffers GetGlobalBuffers() const = 0;
    
    virtual void* Ptr() = 0;
    virtual size_t Length() = 0;
    virtual void* IndicesPtr();
    virtual size_t IndicesLength();
    
    virtual const std::string& GetName() const = 0;
    
    virtual bool HasTransparent() = 0;
    virtual std::shared_ptr<NuoMaterial> GetUnifiedMaterial() = 0;
    virtual void UpdateBufferWithUnifiedMaterial() = 0;
};


#define IMPL_CLONE(className)                                       \
    virtual std::shared_ptr<NuoModelBase> Clone() const override    \
    {                                                               \
        std::shared_ptr<NuoModelBase> result(new className(*this)); \
        return result;                                              \
    }



template <class ItemBase>
class NuoModelCommon : virtual public NuoModelBase
{
protected:
    std::vector<ItemBase> _buffer;

public:
    virtual void AddPosition(size_t sourceIndex, const std::vector<float>& positionsBuffer) override;
    virtual void AddNormal(size_t sourceIndex, const std::vector<float>& normalBuffer) override;
    
    virtual void GenerateIndices() override;
    virtual void GenerateNormals() override;
    
    virtual void SmoothSurface(float tolerance, bool texDiscontinuityOnly) override;
    
    virtual size_t GetVerticesNumber() const override;
    virtual size_t GetIndicesNumber() const override;
    virtual NuoVectorFloat4 GetPosition(size_t index) override;
    
    virtual NuoGlobalBuffers GetGlobalBuffers() const override;
    
    virtual void* Ptr() override;
    virtual size_t Length() override;
    
    virtual void SetName(const std::string& name);
    virtual const std::string& GetName() const override;

protected:
    virtual void DoGenerateIndices(bool compressBuffer);
};



struct NuoItemSimple
{
    NuoVectorFloat4::_typeTrait::_vectorType _position;
    NuoVectorFloat4::_typeTrait::_vectorType _normal;
    
    NuoItemSimple();
    
    bool operator == (const NuoItemSimple& other);
};




template <>
bool ItemTexCoordEequal<NuoItemSimple>(const NuoItemSimple& i1, const NuoItemSimple& i2);




class NuoModelSimple : virtual public NuoModelCommon<NuoItemSimple>
{
protected:
    
    
public:
    NuoModelSimple();
    
    IMPL_CLONE(NuoModelSimple);
    
    virtual void AddTexCoord(size_t sourceIndex, const std::vector<float>& texCoordBuffer) override;
    virtual void AddMaterial(const NuoMaterial& material) override;
    
    virtual void GenerateTangents() override;
    
    virtual void SetTexturePathDiffuse(const std::string texPath) override;
    virtual std::string GetTexturePathDiffuse() override;
    virtual void SetTexturePathOpacity(const std::string texPath) override;
    virtual std::string GetTexturePathOpacity() override;
    virtual void SetTexturePathBump(const std::string texPath) override;
    virtual std::string GetTexturePathBump() override;
    
    virtual NuoMaterial GetMaterial(size_t primtiveIndex) const override;
    virtual bool HasTransparent() override;
    virtual std::shared_ptr<NuoMaterial> GetUnifiedMaterial() override;
    virtual void UpdateBufferWithUnifiedMaterial() override;
};



template <class ItemBase>
void NuoModelCommon<ItemBase>::GenerateIndices()
{
    DoGenerateIndices(true);
}



template <class ItemBase>
void NuoModelCommon<ItemBase>::DoGenerateIndices(bool compressBuffer)
{
    uint32_t indexCurrent = 0;
    
    if (compressBuffer)
    {
        std::vector<ItemBase> compactBuffer;
        size_t checkBackward = 200;
        
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
    else
    {
        for (size_t i = 0; i < _buffer.size(); ++i)
            _indices.push_back(indexCurrent++);
    }
}

template <class ItemBase>
void NuoModelCommon<ItemBase>::SmoothSurface(float tolerance, bool texDiscontinuityOnly)
{
    typedef std::vector<ItemBase*> ItemVec;
    typedef std::map<SmoothItem<ItemBase>, ItemVec> Smoother;
    
    Smoother smoother;
    for (size_t i = 0; i < _buffer.size(); ++i)
    {
        SmoothItem<ItemBase> smoothItem(_buffer[i]);
        auto existingSmoother = smoother.find(smoothItem);

        if (existingSmoother != smoother.end())
        {
            ItemVec& existingSmootherValue = existingSmoother->second;
            
            for (ItemBase* item : existingSmootherValue)
            {
                const NuoVectorFloat4 normal1 = NuoVectorFloat4(item->_normal).Normalize();
                const NuoVectorFloat4 normal2 = NuoVectorFloat4(_buffer[i]._normal).Normalize();
                float cross = NuoDot(normal2, normal1);
                if (fabs(cross) > tolerance &&
                    (!texDiscontinuityOnly || !ItemTexCoordEequal(*item, _buffer[i])))
                {
                    existingSmootherValue.push_back(&_buffer[i]);
                    break;
                }
            }
        }
        else
        {
            ItemVec existingSmootherValue;
            existingSmootherValue.push_back(&_buffer[i]);
            smoother.insert(std::make_pair(smoothItem, existingSmootherValue));
        }
    }
    
    for (auto smoothItem : smoother)
    {
        ItemVec smoothVertex = smoothItem.second;
        
        if (smoothVertex.size() <= 1)
            continue;
        
        NuoVectorFloat4 normalSum(0);
        for (ItemBase* item : smoothVertex)
            normalSum = normalSum + NuoVectorFloat4(item->_normal);

        NuoVectorFloat4 normal = normalSum.Normalize();
        for (ItemBase* item : smoothVertex)
            item->_normal = normal._vector;
    }
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
        
        const NuoVectorFloat3 p0(v0->_position.x, v0->_position.y, v0->_position.z);
        const NuoVectorFloat3 p1(v1->_position.x, v1->_position.y, v1->_position.z);
        const NuoVectorFloat3 p2(v2->_position.x, v2->_position.y, v2->_position.z);
        
        const NuoVectorFloat3 cross = NuoCross((p1 - p0), (p2 - p0));
        const NuoVectorFloat4 cross4(cross.x(), cross.y(), cross.z(), 0);
        
        v0->_normal = v0->_normal + cross4._vector;
        v1->_normal = v1->_normal + cross4._vector;
        v2->_normal = v2->_normal + cross4._vector;
    }
    
    for (size_t i = 0; i < _buffer.size(); ++i)
    {
        _buffer[i]._normal = NuoVectorFloat4::Normalize(_buffer[i]._normal);
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
size_t NuoModelCommon<ItemBase>::GetVerticesNumber() const
{
    return _buffer.size();
}


template <class ItemBase>
size_t NuoModelCommon<ItemBase>::GetIndicesNumber() const
{
    return _indices.size();
}



template <class ItemBase>
NuoVectorFloat4 NuoModelCommon<ItemBase>::GetPosition(size_t index)
{
    return _buffer[index]._position;
}


template <class ItemBase>
NuoGlobalBuffers NuoModelCommon<ItemBase>::GetGlobalBuffers() const
{
    NuoGlobalBuffers result;
    
    for (const ItemBase& item : _buffer)
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
            
            // no texture
            material.texCoord = NuoVectorFloat3(0, 0, 0)._vector;
            material.diffuseTex = -1;
            
            material.specularColor = NuoVectorFloat3(0, 0, 0)._vector;
            material.shinessDisolveIllum = NuoVectorFloat3(1, 0, 2)._vector;
            
            result._materials.push_back(material);
        }
    }
    
    result._indices = _indices;

    return result;
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



template <class ItemBase>
void NuoModelCommon<ItemBase>::SetName(const std::string &name)
{
    _name = name;
}



template <class ItemBase>
const std::string& NuoModelCommon<ItemBase>::GetName() const
{
    return _name;
}



template <class ModelClass>
std::shared_ptr<NuoModelBase> CloneModel(std::shared_ptr<ModelClass> source)
{
    std::shared_ptr<NuoModelBase> result(new ModelClass(*(source.get())));
    return result;
}




#endif /* NuoModelBase_hpp */
