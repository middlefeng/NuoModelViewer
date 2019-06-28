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
    kNuoRayMask_Opaue           = 1,
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
    matrix44 direction;
    float density;
    float coneAngleCosine;
}
NuoRayTracingLightSource;



typedef struct
{
    float ambient;
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


#define kTextureBindingsCap 15



typedef struct
{
    vector2 uv;                    // two-dimension random
    float pathTermDeterminator;    // random to determine which term in reflection is used
}
NuoRayTracingRandomUnit;




#endif /* NuoRayTracingShadersCommon_h */
