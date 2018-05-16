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
inline typename NuoVector<itemType, itemCount>::_typeTrait::_vectorType
NuoVector<itemType, itemCount>::Normalize(const typename NuoVector<itemType, itemCount>::_typeTrait::_vectorType& v)
{
    glm::vec3 vec;
    vec.x = v.x;
    vec.y = v.y;
    vec.z = v.z;
    
    vec = glm::normalize(vec);
    
    typename NuoVector<itemType, itemCount>::_typeTrait::_vectorType r;
    r.x = vec.x;
    r.y = vec.y;
    r.z = vec.z;
    return r;
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

inline float NuoDistance(const NuoVector<float, 2>& v1, const NuoVector<float, 2>& v2)
{
    glm::vec2 vec1(v1._vector.x, v1._vector.y);
    glm::vec2 vec2(v2._vector.x, v2._vector.y);
    return glm::distance(vec1, vec2);
}

inline float NuoDistance(const NuoVector<float, 3>& v1, const NuoVector<float, 3>& v2)
{
    glm::vec3 vec1(v1._vector.x, v1._vector.y, v1._vector.z);
    glm::vec3 vec2(v2._vector.x, v2._vector.y, v2._vector.z);
    return glm::distance(vec1, vec2);
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


inline float NuoDot(const NuoVector<float, 3>& v1, const NuoVector<float, 3>& v2)
{
    glm::vec3 vec1(v1._vector.x, v1._vector.y, v1._vector.z);
    glm::vec3 vec2(v2._vector.x, v2._vector.y, v2._vector.z);
    return glm::dot(vec1, vec2);
}

inline float NuoDot(const NuoVector<float, 4>& v1, const NuoVector<float, 4>& v2)
{
    glm::vec4 vec1(v1._vector.x, v1._vector.y, v1._vector.z, v1._vector.w);
    glm::vec4 vec2(v2._vector.x, v2._vector.y, v2._vector.z, v2._vector.w);
    return glm::dot(vec1, vec2);
}

inline NuoVector<float, 3>
NuoCross(const NuoVector<float, 3>& v1, const NuoVector<float, 3>& v2)
{
    glm::vec3 vec1(v1._vector.x, v1._vector.y, v1._vector.z);
    glm::vec3 vec2(v2._vector.x, v2._vector.y, v2._vector.z);
    glm::vec3 vec = glm::cross(vec1, vec2);
    
    NuoVector<float, 3> r;
    r._vector.x = vec.x;
    r._vector.y = vec.y;
    r._vector.z = vec.z;
    
    return r;
}


template <>
inline NuoMatrix<float, 3>::NuoMatrix()
{
}


template <>
inline NuoMatrix<float, 4>::NuoMatrix()
{
}


template <>
inline bool NuoMatrix<float, 4>::IsIdentity() const
{
    return _m == NuoMatrix<float, 4>()._m;
}


template <>
inline typename NuoMatrix<float, 3>::_typeTrait::_vectorType& NuoMatrix<float, 3>::operator[] (size_t i)
{
    return _m[(int)i];
}


template <>
inline typename NuoMatrix<float, 3>::_typeTrait::_vectorType NuoMatrix<float, 3>::operator[] (size_t i) const
{
    return _m[(int)i];
}


template <>
inline typename NuoMatrix<float, 4>::_typeTrait::_vectorType& NuoMatrix<float, 4>::operator[] (size_t i)
{
    return _m[(int)i];
}


template <>
inline typename NuoMatrix<float, 4>::_typeTrait::_vectorType NuoMatrix<float, 4>::operator[] (size_t i) const
{
    return _m[(int)i];
}


template <>
inline NuoMatrix<float, 4>
operator * (const NuoMatrix<float, 4>& m1, const NuoMatrix<float, 4>& m2)
{
    return NuoMatrix<float, 4>(m1._m * m2._m);
}


inline NuoMatrix<float, 3> NuoMatrixExtractLinear(const NuoMatrix<float, 4>& m)
{
    NuoMatrix<float, 3> r;
    r[0].x = m._m[0][0]; r[0].y = m._m[0][1]; r[0].z = m._m[0][2];
    r[1].x = m._m[1][0]; r[1].y = m._m[1][1]; r[1].z = m._m[1][2];
    r[2].x = m._m[2][0]; r[2].y = m._m[2][1]; r[2].z = m._m[2][2];
    return r;
}


static inline NuoMatrix<float, 4> ToMatrix(glm::mat4x4& gmat)
{
    NuoInternalMatrix<4>* mat = (NuoInternalMatrix<4>*)&gmat;
    return NuoMatrix<float, 4>(*mat);
}




typedef NuoVector<float, 4> NuoVectorFloat4;
typedef NuoVector<float, 3> NuoVectorFloat3;
typedef NuoVector<float, 2> NuoVectorFloat2;

typedef NuoMatrix<float, 3> NuoMatrixFloat33;
typedef NuoMatrix<float, 4> NuoMatrixFloat44;


#endif /* NuoMathVectorMac_h */
