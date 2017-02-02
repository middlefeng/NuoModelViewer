//
//  NuoMaterial.cpp
//  ModelViewer
//
//  Created by middleware on 8/28/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#include "NuoMaterial.h"



NuoMaterial::NuoMaterial() : id(-1)
{
}


static int last_id { 0 };


NuoMaterial::NuoMaterial(const tinyobj::material_t& material, bool unique) :
    id(0),

    ambient { material.ambient[0], material.ambient[1], material.ambient[2] },
    diffuse { material.diffuse[0], material.diffuse[1], material.diffuse[2] },
    specular { material.specular[0], material.specular[1], material.specular[2] },
    transmittance { material.transmittance[0], material.transmittance[1], material.transmittance[2] },
    emission { material.emission[0], material.emission[1], material.emission[2] },
    shininess(material.shininess),
    ior(material.ior),
    dissolve(material.dissolve),
    illum(material.illum),

    ambient_texname(material.ambient_texname),
    diffuse_texname(material.diffuse_texname),
    specular_texname(material.specular_texname),
    specular_highlight_texname(material.specular_highlight_texname),
    bump_texname(material.bump_texname),
    displacement_texname(material.displacement_texname),
    alpha_texname(material.alpha_texname),

    // PBR extension
    roughness_texname(material.roughness_texname),
    metallic_texname(material.metallic_texname),
    sheen_texname(material.sheen_texname),
    emissive_texname(material.emissive_texname),
    normal_texname(material.normal_texname)
{
    if (unique)
        id = last_id++;
}



bool NuoMaterial::operator < (const NuoMaterial& other) const
{
#define compare_element(a) \
            if (a < other.a) return true; \
            if (a > other.a) return false;
    
    compare_element(id)
    compare_element(dissolve)
    
    compare_element(ambient_texname)
    compare_element(diffuse_texname)
    compare_element(specular_texname)
    compare_element(specular_highlight_texname)
    compare_element(bump_texname)
    compare_element(displacement_texname)
    compare_element(alpha_texname)
    
    // PBR extension
    compare_element(roughness_texname)
    compare_element(metallic_texname)
    compare_element(sheen_texname)
    compare_element(emissive_texname)
    compare_element(normal_texname)
    
    return false;
}


bool NuoMaterial::HasTextureDiffuse() const
{
    return !diffuse_texname.empty();
}


bool NuoMaterial::HasTextureOpacity() const
{
    return !alpha_texname.empty();
}


bool NuoMaterial::HasTextureBump() const
{
    return !bump_texname.empty();
}




