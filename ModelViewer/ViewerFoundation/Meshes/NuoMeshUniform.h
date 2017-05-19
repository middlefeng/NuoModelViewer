//
//  NuoMeshUniform.h
//  ModelViewer
//
//  Created by middleware on 2/2/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#ifndef NuoMeshUniform_h
#define NuoMeshUniform_h

#include "NuoMatrixTypes.h"


/**
 *  vertex shader uniform to calculate interpolatable per-vertex data
 */
typedef struct
{
    matrix44 transform;
    matrix33 normalTransform;
}
NuoMeshUniforms;


#endif /* NuoMeshUniform_h */
