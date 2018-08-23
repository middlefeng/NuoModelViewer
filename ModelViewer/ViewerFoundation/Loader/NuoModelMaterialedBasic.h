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
    virtual NuoMaterial GetMaterial(size_t primtiveIndex) const override;
    virtual GlobalBuffers GetGlobalBuffers() const override;
    
    virtual bool HasTransparent() override;
    virtual std::shared_ptr<NuoMaterial> GetUnifiedMaterial() override;
    virtual void UpdateBufferWithUnifiedMaterial() override;
    
};



struct NuoItemMaterialedTexturedBasic
{
    NuoVectorFloat4::_typeTrait::_vectorType _position;
    NuoVectorFloat4::_typeTrait::_vectorType _normal;
    NuoVectorFloat2::_typeTrait::_vectorType _texCoord;
    
    NuoVectorFloat3::_typeTrait::_vectorType _diffuse;
    NuoVectorFloat3::_typeTrait::_vectorType _ambient;
    NuoVectorFloat3::_typeTrait::_vectorType _specular;
    NuoVectorFloat3::_typeTrait::_vectorType _shinessDisolveIllum;
    
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
    NuoVectorFloat4::_typeTrait::_vectorType _position;
    NuoVectorFloat4::_typeTrait::_vectorType _normal;
    NuoVectorFloat4::_typeTrait::_vectorType _tangent;
    NuoVectorFloat4::_typeTrait::_vectorType _bitangent;
    NuoVectorFloat2::_typeTrait::_vectorType _texCoord;
    
    NuoVectorFloat3::_typeTrait::_vectorType _diffuse;
    NuoVectorFloat3::_typeTrait::_vectorType _ambient;
    NuoVectorFloat3::_typeTrait::_vectorType _specular;
    NuoVectorFloat3::_typeTrait::_vectorType _shinessDisolveIllum;
    
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
    NuoVectorFloat4::_typeTrait::_vectorType _position;
    NuoVectorFloat4::_typeTrait::_vectorType _normal;
    
    NuoVectorFloat3::_typeTrait::_vectorType _diffuse;
    NuoVectorFloat3::_typeTrait::_vectorType _ambient;
    NuoVectorFloat3::_typeTrait::_vectorType _specular;
    NuoVectorFloat3::_typeTrait::_vectorType _shinessDisolveIllum;
    
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
    
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._shinessDisolveIllum.x = material.shininess;
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._shinessDisolveIllum.y = material.dissolve;
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._shinessDisolveIllum.z = material.illum;
    
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
        
        NuoModelCommon<ItemBase>::_buffer[targetOffset]._shinessDisolveIllum.x = material.shininess;
        NuoModelCommon<ItemBase>::_buffer[targetOffset]._shinessDisolveIllum.y = material.dissolve;
        NuoModelCommon<ItemBase>::_buffer[targetOffset]._shinessDisolveIllum.z = material.illum;
    }
}


template <class ItemBase>
NuoMaterial NuoModelMaterialedBasicBase<ItemBase>::GetMaterial(size_t primtiveIndex) const
{
    size_t index = primtiveIndex * 3;
    
    // so far assuming the primitive material represented by its first vertex
    //
    const auto& item0 = NuoModelCommon<ItemBase>::_buffer[NuoModelCommon<ItemBase>::_indices[index]];
    
    uint32_t illumMode = (uint32_t)item0._shinessDisolveIllum.z;
    auto& color = item0._diffuse;
    
    NuoMaterial material;
    material.diffuse[0] = color.x;
    material.diffuse[1] = color.y;
    material.diffuse[2] = color.z;
    material.illum = illumMode;
    
    return material;
}


template <class ItemBase>
GlobalBuffers NuoModelMaterialedBasicBase<ItemBase>::GetGlobalBuffers() const
{
    GlobalBuffers result;
    
    for (const ItemBase& item : NuoModelCommon<ItemBase>::_buffer)
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
            
            material.texCoord.x = item._texCoord.x;
            material.texCoord.y = item._texCoord.y;
            
            material.diffuseColor = item._diffuse;
            material.illuminate = (int)item._shinessDisolveIllum[2];
            
            result._materials.push_back(material);
        }
    }
    
    result._indices = NuoModelCommon<ItemBase>::_indices;
    
    return result;
}


template <>
GlobalBuffers NuoModelMaterialedBasicBase<NuoItemMaterialedBasic>::GetGlobalBuffers() const;


#endif /* NuoModelMaterialed_hpp */
