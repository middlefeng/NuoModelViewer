//
//  NuoMathVectorTypeTraitRegular.hpp
//  ModelViewer
//
//  Created by Dong on 5/12/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#ifndef NuoMathVectorTypeTrait_h
#define NuoMathVectorTypeTrait_h


#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>


template <int itemCount> struct NuoRegularVector;


/**
 *  vector must be 16-byte aligned regardless the dimension it is of, in order
 *  to compatible with Metal shader
 */


template <int itemCount>
struct NuoInternalVec
{
    float x;
    float y;
    float z;
    float w;
    
    NuoInternalVec() : x(0), y(0), z(0), w(0) {}
    
    NuoInternalVec(float v) : x(v), y(v), z(v), w(v) {}

    float operator[] (size_t i) const
    {
        switch(i)
        {
            case 0: return x;
            case 1: return y;
            case 2: return z;
            case 3: return w;
            default: break;
        }
        
        return 0;
    }
    
    inline bool operator == (const NuoInternalVec& v) const;
    
    inline bool operator != (const NuoInternalVec& v) const { return !operator==(v); }
    
    inline NuoInternalVec operator - () const;
};


template <>
inline bool NuoInternalVec<3>::operator == (const NuoInternalVec<3>& v) const
{
    return (x == v.x) && (y == v.y) && (z == v.z);
}

template <>
inline bool NuoInternalVec<4>::operator == (const NuoInternalVec<4>& v) const
{
    return (x == v.x) && (y == v.y) && (z == v.z) && (w == v.w);
}

template <>
inline NuoInternalVec<3> NuoInternalVec<3>::operator - () const
{
    NuoInternalVec<3> r;
    r.x = -x;
    r.y = -y;
    r.z = -z;
    
    return r;
}



template <int itemCount>
inline NuoInternalVec<itemCount>
operator - (const NuoInternalVec<itemCount>& v1, const NuoInternalVec<itemCount>& v2)
{
    NuoInternalVec<itemCount> r;
    r.x = v1.x - v2.x;
    r.y = v1.y - v2.y;
    r.z = v1.z - v2.z;
    r.w = v1.w - v2.w;
    
    return r;
}


template <int itemCount>
inline NuoInternalVec<itemCount>
operator + (const NuoInternalVec<itemCount>& v1, const NuoInternalVec<itemCount>& v2)
{
    NuoInternalVec<itemCount> r;
    r.x = v1.x + v2.x;
    r.y = v1.y + v2.y;
    r.z = v1.z + v2.z;
    r.w = v1.w + v2.w;
    
    return r;
}


template <int itemCount>
inline NuoInternalVec<itemCount>
operator * (const NuoInternalVec<itemCount>& v, float f)
{
    NuoInternalVec<itemCount> r;
    r.x = v.x * f;
    r.y = v.y * f;
    r.z = v.z * f;
    r.w = v.w * f;
    
    return r;
}


template <int itemCount>
inline NuoInternalVec<itemCount>
operator / (const NuoInternalVec<itemCount>& v, float f)
{
    NuoInternalVec<itemCount> r;
    r.x = v.x / f;
    r.y = v.y / f;
    r.z = v.z / f;
    r.w = v.w / f;
    
    return r;
}



template <int dimension>
struct NuoInternalMatrix
{
    NuoInternalVec<dimension> columns[dimension];
    
    NuoInternalMatrix();
    
    NuoInternalVec<dimension>& operator[] (size_t i)
    {
        return columns[i];
    }
    
    const NuoInternalVec<dimension> operator[] (size_t i) const
    {
        return columns[i];
    }
    
    bool operator == (const NuoInternalMatrix& m) const
    {
        for (size_t i = 0; i < dimension; ++i)
        {
            if (columns[i] != m[i])
                return false;
        }
        return true;
    }
};


template <>
inline NuoInternalMatrix<3>::NuoInternalMatrix()
{
    (*this)[0].x = 1.;
    (*this)[1].y = 1.;
    (*this)[2].z = 1.;
}

template <>
inline NuoInternalMatrix<4>::NuoInternalMatrix()
{
    (*this)[0].x = 1.;
    (*this)[1].y = 1.;
    (*this)[2].z = 1.;
    (*this)[3].w = 1.;
}


NuoInternalMatrix<4> operator * (const NuoInternalMatrix<4>& m1, const NuoInternalMatrix<4>& m2);

NuoInternalVec<4> operator * (const NuoInternalMatrix<4>& m, const NuoInternalVec<4>& v);




template <class itemType, int itemCount>
class VectorTrait;


template <>
class VectorTrait<float, 2>
{
public:
    typedef NuoInternalVec<2> _vectorType;
};


template <int itemCount>
class VectorTrait<float, itemCount>
{
public:
    typedef NuoInternalVec<itemCount> _vectorType;
    typedef NuoInternalMatrix<itemCount> _matrixType;
};



#endif /* NuoMathVectorTypeTrait_h */
