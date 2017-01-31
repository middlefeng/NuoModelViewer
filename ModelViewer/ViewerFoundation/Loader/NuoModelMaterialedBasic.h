//
//  NuoModelMaterialed.hpp
//  ModelViewer
//
//  Created by dfeng on 9/7/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#ifndef NuoModelMaterialedBasic_hpp
#define NuoModelMaterialedBasic_hpp


#include "tiny_obj_loader.h"
#include "NuoModelBase.h"
#include "NuoModelTextured.h"
#include "NuoMaterial.h"

#include <memory>




template <class ItemBase>
class NuoModelMaterialedBasicBase : virtual public NuoModelCommon<ItemBase>
{

private:
    
    bool _hasTransparent { false };
    
    /**
     *  the common material shared by all vertices.
     *  null if any of the per-vertex material are different from each other
     */
    std::shared_ptr<NuoMaterial> _material;
    
public:
    
    virtual void AddMaterial(const NuoMaterial& material) override;
    virtual bool HasTransparent() override;
    virtual std::shared_ptr<NuoMaterial> GetUnifiedMaterial() override;
    virtual void UpdateBufferWithUnifiedMaterial() override;
    
};



struct NuoItemMaterialedTexturedBasic
{
    vector_float4 _position;
    vector_float4 _normal;
    vector_float2 _texCoord;
    
    vector_float3 _diffuse;
    vector_float3 _ambient;
    vector_float3 _specular;
    vector_float2 _shinessDisolve;
    
    NuoItemMaterialedTexturedBasic();
    
    bool operator == (const NuoItemMaterialedTexturedBasic& other);
};



class NuoModelMaterialedTextured : virtual public NuoModelTextureBase<NuoItemMaterialedTexturedBasic>,
                                   virtual public NuoModelMaterialedBasicBase<NuoItemMaterialedTexturedBasic>
{
public:
    NuoModelMaterialedTextured();
    
    IMPL_CLONE(NuoModelMaterialedTextured);
    
    virtual void GenerateTangents() override;
    virtual void SetTexturePathBump(const std::string texPath) override;
    virtual std::string GetTexturePathBump() override;
};




struct NuoItermMaterialedBumpedTextured
{
    vector_float4 _position;
    vector_float4 _normal;
    vector_float4 _tangent;
    vector_float4 _bitangent;
    vector_float2 _texCoord;
    
    vector_float3 _diffuse;
    vector_float3 _ambient;
    vector_float3 _specular;
    vector_float2 _shinessDisolve;
    
    NuoItermMaterialedBumpedTextured();
    
    bool operator == (const NuoItermMaterialedBumpedTextured& other);
};




class NuoModelMaterialedBumpedTextured : virtual public NuoModelTexturedWithTangentBase<NuoItermMaterialedBumpedTextured>,
                                         virtual public NuoModelMaterialedBasicBase<NuoItermMaterialedBumpedTextured>
{
public:
    IMPL_CLONE(NuoModelMaterialedBumpedTextured);
};




struct NuoItemMaterialedBasic
{
    vector_float4 _position;
    vector_float4 _normal;
    
    vector_float3 _diffuse;
    vector_float3 _ambient;
    vector_float3 _specular;
    vector_float2 _shinessDisolve;
    
    NuoItemMaterialedBasic();
    
    bool operator == (const NuoItemMaterialedBasic& other);
};



template <>
bool ItemTexCoordEequal<NuoItemMaterialedBasic>(const NuoItemMaterialedBasic& i1, const NuoItemMaterialedBasic& i2);



class NuoModelMaterialed : public NuoModelMaterialedBasicBase<NuoItemMaterialedBasic>
{

public:
    
    IMPL_CLONE(NuoModelMaterialed);
    
    virtual void AddTexCoord(size_t sourceIndex, const std::vector<float>& texCoordBuffer) override;
    virtual void GenerateTangents() override;
    
    virtual void SetTexturePathDiffuse(const std::string texPath) override;
    virtual std::string GetTexturePathDiffuse() override;
    virtual void SetTexturePathOpacity(const std::string texPath) override;
    virtual std::string GetTexturePathOpacity() override;
    virtual void SetTexturePathBump(const std::string texPath) override;
    virtual std::string GetTexturePathBump() override;
};



template <class ItemBase>
void NuoModelMaterialedBasicBase<ItemBase>::AddMaterial(const NuoMaterial& material)
{
    size_t targetOffset = NuoModelCommon<ItemBase>::_buffer.size() - 1;
    
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._diffuse.x = material.diffuse[0];
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._diffuse.y = material.diffuse[1];
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._diffuse.z = material.diffuse[2];
    
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._ambient.x = material.ambient[0];
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._ambient.y = material.ambient[1];
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._ambient.z = material.ambient[2];
    
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._specular.x = material.specular[0];
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._specular.y = material.specular[1];
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._specular.z = material.specular[2];
    
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._shinessDisolve.x = material.shininess;
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._shinessDisolve.y = material.dissolve;
    
    if (!_material)
        _material.reset(new NuoMaterial(material));
    else if ((*(_material.get()) < material) || ((material < (*(_material.get())))))
        _material.reset();
    
    if (material.dissolve - 1.0 < -1e-3)
        _hasTransparent = true;
}


template <class ItemBase>
bool NuoModelMaterialedBasicBase<ItemBase>::HasTransparent()
{
    return _hasTransparent;
}


template <class ItemBase>
std::shared_ptr<NuoMaterial> NuoModelMaterialedBasicBase<ItemBase>::GetUnifiedMaterial()
{
    return _material;
}


template <class ItemBase>
void NuoModelMaterialedBasicBase<ItemBase>::UpdateBufferWithUnifiedMaterial()
{
    NuoMaterial material = *(_material.get());
    
    for (size_t targetOffset = 0; targetOffset < NuoModelCommon<ItemBase>::_buffer.size();
         ++targetOffset)
    {
        NuoModelCommon<ItemBase>::_buffer[targetOffset]._diffuse.x = material.diffuse[0];
        NuoModelCommon<ItemBase>::_buffer[targetOffset]._diffuse.y = material.diffuse[1];
        NuoModelCommon<ItemBase>::_buffer[targetOffset]._diffuse.z = material.diffuse[2];
        
        NuoModelCommon<ItemBase>::_buffer[targetOffset]._ambient.x = material.ambient[0];
        NuoModelCommon<ItemBase>::_buffer[targetOffset]._ambient.y = material.ambient[1];
        NuoModelCommon<ItemBase>::_buffer[targetOffset]._ambient.z = material.ambient[2];
        
        NuoModelCommon<ItemBase>::_buffer[targetOffset]._specular.x = material.specular[0];
        NuoModelCommon<ItemBase>::_buffer[targetOffset]._specular.y = material.specular[1];
        NuoModelCommon<ItemBase>::_buffer[targetOffset]._specular.z = material.specular[2];
        
        NuoModelCommon<ItemBase>::_buffer[targetOffset]._shinessDisolve.x = material.shininess;
        NuoModelCommon<ItemBase>::_buffer[targetOffset]._shinessDisolve.y = material.dissolve;
    }
    
}



#endif /* NuoModelMaterialed_hpp */
