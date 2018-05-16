//
//  NuoMathVectorMac.hpp
//  ModelViewer
//
//  Created by Dong on 5/12/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#ifndef NuoMathVectorFunctions_h
#define NuoMathVectorFunctions_h


#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>


template <class itemType, int itemCount>
inline typename NuoVector<itemType, itemCount>::_typeTrait::_vectorType
NuoVector<itemType, itemCount>::Normalize(const typename NuoVector<itemType, itemCount>::_typeTrait::_vectorType& v)
{
    return vector_normalize(v);
}


template <class itemType, int itemCount>
inline NuoVector<itemType, itemCount> NuoVector<itemType, itemCount>::operator - () const
{
    return NuoVector<itemType, itemCount>(-(_vector));
}


template <class itemType, int dimension>
inline NuoVector<itemType, dimension>
operator * (const NuoMatrix<itemType, dimension>& m, const NuoVector<itemType, dimension>& v);


template <class itemType, int dimension>
inline NuoMatrix<itemType, dimension>
operator * (const NuoMatrix<itemType, dimension>& m1, const NuoMatrix<itemType, dimension>& m2);


template <int itemCount>
inline NuoVector<float, itemCount>
operator * (const NuoMatrix<float, itemCount>& m, const NuoVector<float, itemCount>& v)
{
    return NuoVector<float, itemCount>(matrix_multiply(m._m, v._vector));
}


template <int itemCount>
inline NuoVector<float, itemCount>
operator - (const NuoVector<float, itemCount>& v1,
            const NuoVector<float, itemCount>& v2)
{
    return NuoVector<float, itemCount>(v1._vector - v2._vector);
}


template <int itemCount>
inline NuoVector<float, itemCount>
operator + (const NuoVector<float, itemCount>& v1,
            const NuoVector<float, itemCount>& v2)
{
    return NuoVector<float, itemCount>(v1._vector + v2._vector);
}

template <int itemCount>
inline float NuoDistance(const NuoVector<float, itemCount>& v1, const NuoVector<float, itemCount>& v2)
{
    return simd::distance(v1._vector, v2._vector);
}


template <int itemCount>
inline NuoVector<float, itemCount>
operator / (const NuoVector<float, itemCount>& v, float div)
{
    return NuoVector<float, itemCount>(v._vector / div);
}

template <int itemCount>
inline float NuoDot(const NuoVector<float, itemCount>& v1, const NuoVector<float, itemCount>& v2)
{
    return vector_dot(v1._vector, v2._vector);
}

template <int itemCount>
inline NuoVector<float, itemCount>
NuoCross(const NuoVector<float, itemCount>& v1, const NuoVector<float, itemCount>& v2)
{
    return NuoVector<float, itemCount>(vector_cross(v1._vector, v2._vector));
}

template <int itemCount>
inline NuoVector<float, itemCount>
operator * (const NuoVector<float, itemCount>& v, float mul)
{
    return NuoVector<float, itemCount>(v._vector * mul);
}


template <>
inline NuoMatrix<float, 4>::NuoMatrix()
    : _m(matrix_identity_float4x4)
{
}


template <>
inline bool NuoMatrix<float, 4>::IsIdentity() const
{
    return matrix_equal(_m, matrix_identity_float4x4);
}


template <>
inline NuoMatrix<float, 4>
operator * (const NuoMatrix<float, 4>& m1, const NuoMatrix<float, 4>& m2)
{
    return NuoMatrix<float, 4>(matrix_multiply(m1._m, m2._m));
}


inline NuoMatrix<float, 3> NuoMatrixExtractLinear(const NuoMatrix<float, 4>& m)
{
    vector_float3 X = m._m.columns[0].xyz;
    vector_float3 Y = m._m.columns[1].xyz;
    vector_float3 Z = m._m.columns[2].xyz;
    matrix_float3x3 l = { X, Y, Z };
    return NuoMatrix<float, 3>(l);
}


template <>
inline typename NuoMatrix<float, 4>::_typeTrait::_vectorType& NuoMatrix<float, 4>::operator[] (size_t i)
{
    return _m.columns[i];
}


template <>
inline typename NuoMatrix<float, 4>::_typeTrait::_vectorType NuoMatrix<float, 4>::operator[] (size_t i) const
{
    return _m.columns[i];
}


#include <stdio.h>


static inline NuoMatrix<float, 4> ToMatrix(glm::mat4x4& gmat)
{
    matrix_float4x4* result = (matrix_float4x4*)(&gmat);
    return NuoMatrix<float, 4>(*result);
}




typedef NuoVector<float, 4> NuoVectorFloat4;
typedef NuoVector<float, 3> NuoVectorFloat3;
typedef NuoVector<float, 2> NuoVectorFloat2;

typedef NuoMatrix<float, 3> NuoMatrixFloat33;
typedef NuoMatrix<float, 4> NuoMatrixFloat44;


#endif /* NuoMathVectorMac_h */
