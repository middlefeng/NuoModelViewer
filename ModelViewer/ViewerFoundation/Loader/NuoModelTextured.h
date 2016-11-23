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




class NuoModelTextured : public NuoModelTextureBase<NuoItemTextured>
{
public:
    virtual void AddMaterial(const NuoMaterial& material) override;
    virtual bool HasTransparent() override;
    
    virtual void SetTexturePathOpacity(const std::string texPath) override;
    virtual std::string GetTexturePathOpacity() override;
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





#endif /* NuoModelTextured_hpp */
