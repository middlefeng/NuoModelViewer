//
//  NuoMeshRotation.h
//  ModelViewer
//
//  Created by middleware on 2/2/17.
//  Copyright © 2017 middleware. All rights reserved.
//


#ifndef __NUOMESHROTATION_H__
#define __NUOMESHROTATION_H__


#include "NuoMathVector.h"


class NuoMeshRotation
{

private:
    float _radius;
    NuoMatrixFloat44 _cachedResult;
    
    void GenerateMatrices();

public:
    NuoVectorFloat3 _transformVector;
    NuoVectorFloat3 _axis;
    
    NuoMeshRotation();
    NuoMeshRotation(const NuoMeshRotation& r);
    
    void SetRadius(float radius);
    float Radius() const { return _radius; }
    const NuoMatrixFloat44& RotationMatrix();

};


#endif
