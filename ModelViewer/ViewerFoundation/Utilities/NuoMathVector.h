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
    
#endif


template <class itemType, int itemCount>
class NuoVector
{
    typedef VectorTrait<itemType, itemCount> _typeTrait;
    
public:
    typename _typeTrait::_vectorType _vector;

    inline itemType x() const { return _vector.x; }
    inline itemType y() const { return _vector.y; }
    inline itemType z() const { return _vector.z; }
    inline itemType w() const;
    
    inline void x(itemType x) { _vector.x = x; }
    inline void y(itemType y) { _vector.y = y; }
    inline void z(itemType z) { _vector.z = z; }
    inline void w(itemType w) const;
    
    inline itemType operator[] (size_t i) const { return _vector[i]; }
    
    inline NuoVector(const typename _typeTrait::_vectorType& x) : _vector(x) {};
    
    inline NuoVector() {};
    inline NuoVector(itemType x, itemType y);
    inline NuoVector(itemType x, itemType y, itemType z);
    inline NuoVector(itemType x, itemType y, itemType z, itemType w);
    
    inline const typename _typeTrait::_vectorType&
    operator = (const typename _typeTrait::_vectorType& v)
    {
        return (_vector = v);
    }
    
    inline NuoVector operator - () const;
    
    inline NuoVector Normalize() const;
};


template <>
inline float NuoVector<float, 3>::w() const
{
    return 1.0;
}


template <>
inline float NuoVector<float, 4>::w() const
{
    return _vector.w;
}

template <>
inline void NuoVector<float, 4>::w(float w) const
{
    _vector.w = w;
}


template <>
inline NuoVector<float, 2>::NuoVector(float x, float y)
{
    _vector.x = x;
    _vector.y = y;
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


template <class itemType, int itemCount>
inline NuoVector<itemType, itemCount>
operator - (const NuoVector<itemType, itemCount>& v1, const NuoVector<itemType, itemCount>& v2);

template <class itemType, int itemCount>
inline NuoVector<itemType, itemCount>
operator + (const NuoVector<itemType, itemCount>& v1, const NuoVector<itemType, itemCount>& v2);

template <class itemType, int itemCount>
inline itemType NuoDistance(const NuoVector<itemType, itemCount>& v1, const NuoVector<itemType, itemCount>& v2);

template <class itemType, int itemCount>
inline NuoVector<itemType, itemCount>
operator / (const NuoVector<itemType, itemCount>& v, itemType div);

template <class itemType, int itemCount>
inline NuoVector<itemType, itemCount>
operator * (const NuoVector<itemType, itemCount>& v, itemType div);


template <class itemType, int dimension>
class NuoMatrix
{
private:
    typedef VectorTrait<itemType, dimension> _typeTrait;
    
public:
    typename _typeTrait::_matrixType _m;
    
    inline NuoMatrix();
    
    inline typename _typeTrait::_vectorType operator[] (size_t i) const { return _m.columns[i]; }
    
    inline NuoMatrix(const typename _typeTrait::_matrixType& v)
    {
        _m = v;
    }
    
    inline const typename _typeTrait::_matrixType&
    operator = (const typename _typeTrait::_matrixType& v)
    {
        return (_m = v);
    }
    
    inline bool IsIdentity() const;
};


NuoMatrix<float, 4> NuoMatrixPerspective(float aspect, float fovy, float near, float far);
NuoMatrix<float, 4> NuoMatrixOrthor(float left, float right, float top, float bottom, float near, float far);

NuoMatrix<float, 4> NuoMatrixScale(const NuoVector<float, 3>& scale);
NuoMatrix<float, 4> NuoMatrixRotationAround(NuoMatrix<float, 4> rotate, NuoVector<float, 3> center);
NuoMatrix<float, 4> NuoMatrixLookAt(const NuoVector<float, 3>& eye,
                                    const NuoVector<float, 3>& center,
                                    const NuoVector<float, 3>& up);



#if __APPLE__


template <class itemType, int itemCount>
inline NuoVector<itemType, itemCount> NuoVector<itemType, itemCount>::Normalize() const
{
    return NuoVector<itemType, itemCount>(vector_normalize(_vector));
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


static inline NuoMatrix<float, 4> ToMatrix(glm::mat4x4& gmat)
{
    matrix_float4x4* result = (matrix_float4x4*)(&gmat);
    return NuoMatrix<float, 4>(*result);
}


#endif


inline NuoMatrix<float, 4> NuoMatrixRotation(const NuoVector<float, 3>& axis, float angle)
{
    glm::vec3 gaxis(axis.x(), axis.y(), axis.z());
    glm::mat4x4 gmat = glm::rotate(glm::mat4x4(1.0), -angle, gaxis);
    
    return ToMatrix(gmat);
}


inline NuoMatrix<float, 4> NuoMatrixRotation(float rotateX, float rotateY)
{
    NuoVector<float, 3> xAxis(1, 0, 0);
    NuoVector<float, 3> yAxis(0, 1, 0);
    const NuoMatrix<float, 4> xRot = NuoMatrixRotation(xAxis, rotateX);
    const NuoMatrix<float, 4> yRot = NuoMatrixRotation(yAxis, rotateY);
    
    return xRot * yRot;
}


inline NuoMatrix<float, 4> NuoMatrixTranslation(const NuoVector<float, 3>& t)
{
    glm::vec3 gt(t.x(), t.y(), t.z());
    glm::mat4x4 gmat = glm::translate(glm::mat4x4(1.0), gt);
    
    return ToMatrix(gmat);
}


inline NuoMatrix<float, 4> NuoMatrixRotationAppend(const NuoMatrix<float, 4>& start, float rotateX, float rotateY)
{
    const NuoMatrix<float, 4> rotate = NuoMatrixRotation(rotateX, rotateY);
    return rotate * start;
}


#if __APPLE__

typedef NuoVector<float, 4> NuoVectorFloat4;
typedef NuoVector<float, 3> NuoVectorFloat3;
typedef NuoVector<float, 2> NuoVectorFloat2;

typedef NuoMatrix<float, 3> NuoMatrixFloat33;
typedef NuoMatrix<float, 4> NuoMatrixFloat44;

#endif


#endif /* NuoMathVector_h */
