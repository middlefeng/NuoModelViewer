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
 *  vertex shader uniform for model transform. if a mesh does cast shadow, the
 *  view-projection matrix has to be separated vith the model transform since
 *  the same model transform need to be applied to the view project and light/shadow-map
 *  project respectively.
 */
typedef struct
{
    matrix44 transform       __attribute__ ((aligned (16)));
    matrix33 normalTransform __attribute__ ((aligned (16)));
}
NuoMeshUniforms;


#endif /* NuoMeshUniform_h */
