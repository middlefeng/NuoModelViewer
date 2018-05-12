//
//  NuoMathVectorMac.hpp
//  ModelViewer
//
//  Created by Dong on 5/12/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#ifndef NuoMathVectorTypeTrait_h
#define NuoMathVectorTypeTrait_h

#include <simd/simd.h>


template <>
class VectorTrait<float, 2>
{
public:
    typedef vector_float2 _vectorType;
};


template <>
class VectorTrait<float, 3>
{
public:
    typedef vector_float3 _vectorType;
    typedef matrix_float3x3 _matrixType;
};

template <>
class VectorTrait<float, 4>
{
public:
    typedef vector_float4 _vectorType;
    typedef matrix_float4x4 _matrixType;
};

#endif /* NuoMathVectorMac_h */
