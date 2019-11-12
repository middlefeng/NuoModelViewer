//
//  NuoRayTracingShadersCommon.h
//  ModelViewer
//
//  Created by middleware on 6/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#ifndef NuoRayTracingShadersCommon_h
#define NuoRayTracingShadersCommon_h


#include "Meshes/NuoMatrixTypes.h"


typedef enum
{
    kNuoRayIndex_OnOpaque = 0,
    kNuoRayIndex_OnTranslucent,
    kNuoRayIndex_OnVirtual,
    kNuoRayIndex_Size
}
NuoRayIndex;



typedef enum
{
    kNuoRayMask_Opaque          = 1,
    kNuoRayMask_Translucent     = 2,
    kNuoRayMask_Illuminating    = 4,
    kNuoRayMask_Virtual         = 8,
    kNuoRayMask_Disabled        = 16,
}
NuoRayMask;


typedef struct
{
    vector4 center;
    float span;
}
NuoBoundsUniform;



typedef struct
{
    vector3 direction;
    float coneAngleCosine;
    
    /**
     *  a light source is considered a far-away partial shpere that covers a solid angle.
     *  as it is far way, the effective light emission is not diffused, but perfectly
     *  directional along a cone.
     *
     *  the radiance emitted from the entire light source and received by a point on a
     *  surface is then the irradiance on that point, which is considered a character
     *  of the light source. for a given irradiance, the radiance of a direction within
     *  the cone is reversely in proportion to the solid angle.
     *
     *  in light source sampling of a monte carlo process, the (radiance / pdf-light)
     *  will be equal to radiance * solid-angle, hence the irradiance
     *
     *  in a scatter sampling, the radiance is (irradiance / (2 * PI * (1 - coneAngleCosine)) * PI),
     *  (the right-most PI factor is abitrarily multipled by the renderer, and in effct it cancels
     *  the PI term in the denominator)
     */
    float irradiance;
}
NuoRayTracingLightSource;



typedef struct
{
    vector3 ambient;
    float ambientRadius;
    float illuminationStrength;
    float specularMaterialAdjust;
}
NuoRayTracingGlobalIlluminationParam;


typedef struct
{
    NuoBoundsUniform bounds;
    NuoRayTracingLightSource lightSources[2];
    NuoRayTracingGlobalIlluminationParam globalIllum;
}
NuoRayTracingUniforms;


typedef struct
{
    vector3 normal;
    vector3 diffuseColor;
    vector3 specularColor;
    vector3 shinessDisolveIllum;
    
    vector3 texCoord;
    int diffuseTex;
}
NuoRayTracingMaterial;


typedef struct
{
    float uRange;
    float vRange;
    
    uint wViewPort;
    uint hViewPort;
    
    matrix44 viewTrans;
}
NuoRayVolumeUniform;


#define kTextureBindingsCap 18



typedef struct
{
    vector2 uv;                    // two-dimension random
    float pathTermDeterminator;    // random to determine which term in reflection is used
    
    vector2 uvLightSource;
    float lightSource;
    
    vector2 uvLightSourceByScatter;
    float pathTermForLightSourceByScatter;
}
NuoRayTracingRandomUnit;




#endif /* NuoRayTracingShadersCommon_h */
