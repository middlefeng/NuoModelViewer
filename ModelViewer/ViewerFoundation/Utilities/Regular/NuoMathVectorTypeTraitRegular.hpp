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


/*template <>
struct NuoRegularVector<2>
{
    glm::vec4
};


template <>
struct NuoRegularVector<3>
{
    float x;
    float y;
    float z;
};


template <>
struct NuoRegularVector<4>
{
    float x;
    float y;
    float z;
    float w;
};


template <int itemCount>
struct NuoRegularMatrix
{
    NuoRegularVector<itemCount> vector[itemCount];
};*/


template <>
class VectorTrait<float, 2>
{
public:
    typedef glm::vec2 _vectorType;
};


template <>
class VectorTrait<float, 3>
{
public:
    typedef glm::vec3 _vectorType;
    typedef glm::mat3x3 _matrixType;
};

template <>
class VectorTrait<float, 4>
{
public:
    typedef glm::vec4 _vectorType;
    typedef glm::mat4x4 _matrixType;
};

#endif /* NuoMathVectorTypeTrait_h */
