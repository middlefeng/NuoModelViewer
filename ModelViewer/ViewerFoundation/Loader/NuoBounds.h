//
//  NuoBounds.hpp
//  ModelViewer
//
//  Created by Dong on 1/25/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#ifndef NuoBounds_hpp
#define NuoBounds_hpp



#include "NuoMathVector.h"
#include "NuoRay.h"

/**
 *  it's usually arbitrary to pick either the bounds (i.e. bounding box) or the sphere
 *  to position objects to a subjectively comfortable place.
 *
 *  when it comes to the near/far plane calcuation, bounds is more accurate as it utilize
 *  z-buffer range to the objects' span maximally.
 */



class NuoSphere
{

public:
    
    NuoVectorFloat3 _center;
    float _radius;
    
    NuoSphere();
    
    NuoSphere Union(const NuoSphere& sphere);
    NuoSphere Transform(const NuoMatrixFloat44& matrix) const;

};


class NuoBounds
{
    
public:
    
    NuoVectorFloat3 _center;
    NuoVectorFloat3 _span;
    
    NuoBounds();
    
    NuoBounds Transform(const NuoMatrixFloat44& matrix) const;

    NuoBounds Union(const NuoBounds& bounds) const;
    NuoBounds Union(const NuoVectorFloat3& point) const;
    float MaxDimension() const;
    
    NuoSphere Sphere() const;
    
    bool Intersect(const NuoRay& ray, float* near, float* far);
};





#endif /* NuoBounds_hpp */
