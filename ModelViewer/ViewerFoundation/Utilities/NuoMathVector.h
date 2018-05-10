//
//  NuoMathVector.h
//  ModelViewer
//
//  Created by Dong on 5/10/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#ifndef NuoMathVector_h
#define NuoMathVector_h


#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>


template <class itemType, int itemCount> class VectorTrait;


#if __APPLE__

#include <simd/simd.h>

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
    
#endif


template <class itemType, int itemCount>
class NuoVector
{
    typedef VectorTrait<itemType, itemCount> _typeTrait;
    
public:
    typename _typeTrait::_vectorType _vector;

    inline itemType x() { return _vector.x; }
    inline itemType y() { return _vector.y; }
    inline itemType z() { return _vector.z; }
    inline itemType w();
    
    inline itemType& operator[] (size_t i) { return _vector[i]; }
    
    inline NuoVector(const typename _typeTrait::_vectorType& x) : _vector(x) {};
    
    inline NuoVector(itemType x, itemType y, itemType z);
    inline NuoVector(itemType x, itemType y, itemType z, itemType w);
    
    inline const typename _typeTrait::_vectorType&
    operator = (const typename _typeTrait::_vectorType& v)
    {
        return (_vector = v);
    }
};


template <>
inline float NuoVector<float, 3>::w()
{
    return 1.0;
}


template <>
inline float NuoVector<float, 4>::w()
{
    return _vector.w;
}


template <>
inline NuoVector<float, 3>::NuoVector(float x, float y, float z)
{
    _vector.x = x;
    _vector.y = y;
    _vector.z = z;
}


template <>
inline NuoVector<float, 4>::NuoVector(float x, float y, float z, float w)
{
    _vector.x = x;
    _vector.y = y;
    _vector.z = z;
    _vector.w = w;
}


template <class itemType, int dimension>
class NuoMatrix
{
private:
    typedef VectorTrait<itemType, dimension> _typeTrait;
    
public:
    typename _typeTrait::_matrixType _m;
    
    inline typename _typeTrait::_vectorType& operator[] (size_t i) { return _m[i]; }
    
    inline NuoMatrix(const typename _typeTrait::_matrixType& v)
    {
        _m = v;
    }
    
    inline const typename _typeTrait::_matrixType&
    operator = (const typename _typeTrait::_matrixType& v)
    {
        return (_m = v);
    }
};


template <class itemType, int dimension>
inline NuoVector<itemType, dimension>
operator * (const NuoMatrix<itemType, dimension>& m, const NuoVector<itemType, dimension>& v);


static inline NuoMatrix<float, 4> ToMatrix(glm::mat4x4& gmat);


inline NuoMatrix<float, 4> NuoMatrixRotation(NuoVector<float, 3> axis, float angle)
{
    glm::vec3 gaxis(axis.x(), axis.y(), axis.z());
    glm::mat4x4 gmat = glm::rotate(glm::mat4x4(1.0), -angle, gaxis);
    
    return ToMatrix(gmat);
}


#if __APPLE__

typedef NuoVector<float, 4> NuoVectorFloat4;
typedef NuoVector<float, 3> NuoVectorFloat3;

typedef NuoMatrix<float, 3> NuoMatrixFloat33;
typedef NuoMatrix<float, 4> NuoMatrixFloat44;


template <>
inline NuoVector<float, 4>
operator * (const NuoMatrix<float, 4>& m, const NuoVector<float, 4>& v)
{
    return NuoVector<float, 4>(matrix_multiply(m._m, v._vector));
}


static inline NuoMatrix<float, 4> ToMatrix(glm::mat4x4& gmat)
{
    matrix_float4x4* result = (matrix_float4x4*)(&gmat);
    return NuoMatrix<float, 4>(*result);
}

#endif


#endif /* NuoMathVector_h */
