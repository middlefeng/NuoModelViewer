//
//  NuoBounds.hpp
//  ModelViewer
//
//  Created by Dong on 1/25/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#ifndef NuoBounds_hpp
#define NuoBounds_hpp



#include <simd/simd.h>


class NuoBounds
{
public:
    vector_float3 _center;
    vector_float3 _span;

    NuoBounds Transform(const matrix_float4x4& matrix);

    NuoBounds Union(const NuoBounds& bounds);
    NuoBounds Union(const vector_float3& point);
};



#endif /* NuoBounds_hpp */
