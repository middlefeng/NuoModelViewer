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




template <class ItemBase>
class NuoModelMaterialedBasicBase : virtual public NuoModelCommon<ItemBase>
{
public:
    
    virtual void AddMaterial(const NuoMaterial& material) override;
    
};



struct NuoItemMaterialedTexturedBasic
{
    vector_float4 _position;
    vector_float4 _normal;
    vector_float2 _texCoord;
    
    vector_float3 _diffuse;
    vector_float3 _ambient;
    vector_float3 _specular;
    float _shiness;
    
    NuoItemMaterialedTexturedBasic();
    
    bool operator == (const NuoItemMaterialedTexturedBasic& other);
};



class NuoModelMaterialedTextured : virtual public NuoModelTextureBase<NuoItemMaterialedTexturedBasic>,
                                           public NuoModelMaterialedBasicBase<NuoItemMaterialedTexturedBasic>
{
public:
    virtual std::string TypeName() override;
};



template <class ItemBase>
void NuoModelMaterialedBasicBase<ItemBase>::AddMaterial(const NuoMaterial& material)
{
    size_t targetOffset = NuoModelCommon<ItemBase>::_buffer.size() - 1;
    
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._diffuse[0] = material.diffuse[0];
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._diffuse[1] = material.diffuse[1];
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._diffuse[2] = material.diffuse[2];
    
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._ambient[0] = material.ambient[0];
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._ambient[1] = material.ambient[1];
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._ambient[2] = material.ambient[2];
    
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._specular[0] = material.specular[0];
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._specular[1] = material.specular[1];
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._specular[2] = material.specular[2];
    
    NuoModelCommon<ItemBase>::_buffer[targetOffset]._shiness = material.shininess;
}



#endif /* NuoModelMaterialed_hpp */
