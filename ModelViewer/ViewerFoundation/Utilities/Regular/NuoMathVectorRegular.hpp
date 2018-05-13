//
//  NuoMathVectorMac.hpp
//  ModelViewer
//
//  Created by Dong on 5/12/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#ifndef NuoMathVectorFunctions_h
#define NuoMathVectorFunctions_h


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
    return NuoVector<float, itemCount>(m._m * v._vector);
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
    return glm::distance(v1._vector, v2._vector);
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
{
}


template <>
inline bool NuoMatrix<float, 4>::IsIdentity() const
{
    return _m == glm::mat4x4();
}


template <>
inline NuoMatrix<float, 4>
operator * (const NuoMatrix<float, 4>& m1, const NuoMatrix<float, 4>& m2)
{
    return NuoMatrix<float, 4>(m1._m * m2._m);
}


inline NuoMatrix<float, 3> NuoMatrixExtractLinear(const NuoMatrix<float, 4>& m)
{
    glm::vec3 X(m._m[0][0], m._m[0][1], m._m[0][2]);
    glm::vec3 Y(m._m[1][0], m._m[1][1], m._m[1][2]);
    glm::vec3 Z(m._m[2][0], m._m[2][1], m._m[2][2]);
    glm::mat3x3 l(X, Y, Z);
    return NuoMatrix<float, 3>(l);
}


static inline NuoMatrix<float, 4> ToMatrix(glm::mat4x4& gmat)
{
    return NuoMatrix<float, 4>(gmat);
}




typedef NuoVector<float, 4> NuoVectorFloat4;
typedef NuoVector<float, 3> NuoVectorFloat3;
typedef NuoVector<float, 2> NuoVectorFloat2;

typedef NuoMatrix<float, 3> NuoMatrixFloat33;
typedef NuoMatrix<float, 4> NuoMatrixFloat44;


#endif /* NuoMathVectorMac_h */
