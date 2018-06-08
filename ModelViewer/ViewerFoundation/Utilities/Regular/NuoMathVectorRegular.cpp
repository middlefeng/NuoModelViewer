//
//  NuoMathVectorMac.cpp
//  ModelViewer
//
//  Created by Dong on 5/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#include "NuoMathVector.h"


NuoInternalMatrix<4> operator * (const NuoInternalMatrix<4>& m1, const NuoInternalMatrix<4>& m2)
{
    glm::mat4x4* mat1 = (glm::mat4x4*)&m1;
    glm::mat4x4* mat2 = (glm::mat4x4*)&m2;
    glm::mat4x4 mat = (*mat1) * (*mat2);
    return *(NuoInternalMatrix<4>*)&mat;
}



NuoInternalVec<4> operator * (const NuoInternalMatrix<4>& m, const NuoInternalVec<4>& v)
{
    glm::mat4x4* mat = (glm::mat4x4*)&m;
    glm::vec4* vec = (glm::vec4*)&v;
    glm::vec4 ve = (*mat) * (*vec);
    
    return *(NuoInternalVec<4>*)&ve;
}



NuoMatrix<float, 4> NuoMatrixPerspective(float aspect, float fovy, float near, float far)
{
    // NOT use OpenGL persepctive!
    // Metal uses a 2x2x1 canonical cube (z in [0,1]), rather than the 2x2x2 one in OpenGL.
    
    // glm::mat4x4 gmat = glm::perspective(fovy, aspect, near, far);
    /*
     T const tanHalfFovy = tan(fovy / static_cast<T>(2));
     
     tmat4x4<T, defaultp> Result(static_cast<T>(0));
     Result[0][0] = static_cast<T>(1) / (aspect * tanHalfFovy);
     Result[1][1] = static_cast<T>(1) / (tanHalfFovy);
     Result[2][2] = - (zFar + zNear) / (zFar - zNear);
     Result[2][3] = - static_cast<T>(1);
     Result[3][2] = - (static_cast<T>(2) * zFar * zNear) / (zFar - zNear);
     return Result;
     */
    
    float yScale = 1 / tan(fovy * 0.5);
    float xScale = yScale / aspect;
    float zRange = far - near;
    float zScale = -(far) / zRange;
    float wzScale = - far * near / zRange;
    
    glm::vec4 P(xScale, 0, 0, 0);
    glm::vec4 Q(0, yScale, 0, 0);
    glm::vec4 R(0, 0, zScale, -1);
    glm::vec4 S(0, 0, wzScale, 0);
    
    glm::mat4x4 mat(P, Q, R, S);
    return ToMatrix(mat);
}


NuoMatrix<float, 4> NuoMatrixOrthor(float left, float right, float top, float bottom, float near, float far)
{
    /* Ortho in OpenGL
     
     tmat4x4<T, defaultp> Result(1);
     Result[0][0] = static_cast<T>(2) / (right - left);
     Result[1][1] = static_cast<T>(2) / (top - bottom);
     Result[2][2] = - static_cast<T>(2) / (zFar - zNear);
     Result[3][0] = - (right + left) / (right - left);
     Result[3][1] = - (top + bottom) / (top - bottom);
     Result[3][2] = - (zFar + zNear) / (zFar - zNear);
     */
    
    // Ortho in Metal
    // http://blog.athenstean.com/post/135771439196/from-opengl-to-metal-the-projection-matrix
    
    float yScale = 2 / (top - bottom);
    float xScale = 2 / (right - left);
    float zRange = far - near;
    float zScale = - 1 / zRange;
    float wzScale = - near / zRange;
    float wyScale = - (top + bottom) / (top - bottom);
    float wxScale = - (right + left) / (right - left);
    
    glm::vec4 P(xScale, 0, 0, 0);
    glm::vec4 Q(0, yScale, 0, 0);
    glm::vec4 R(0, 0, zScale, 0);
    glm::vec4 S(wxScale, wyScale, wzScale, 1);
    
    glm::mat4x4 mat(P, Q, R, S);
    return ToMatrix(mat);
}
