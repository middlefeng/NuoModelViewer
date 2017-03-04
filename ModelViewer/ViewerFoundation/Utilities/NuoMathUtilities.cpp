

#import "NuoMathUtilities.h"


#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>

static matrix_float4x4& to_matrix(glm::mat4x4& gmat)
{
    matrix_float4x4* result = (matrix_float4x4*)(&gmat);
    return *result;
}

matrix_float4x4 matrix_translation(vector_float3 t)
{
    glm::vec3 gt(t.x, t.y, t.z);
    glm::mat4x4 gmat = glm::translate(glm::mat4x4(1.0), gt);
    
    return to_matrix(gmat);
}

matrix_float4x4 matrix_uniform_scale(float scale)
{
    glm::mat4x4 gmat = glm::scale(glm::mat4x4(1.0), glm::vec3(scale));
    return to_matrix(gmat);
}

matrix_float4x4 matrix_rotation(vector_float3 axis, float angle)
{
    glm::vec3 gaxis(axis.x, axis.y, axis.z);
    glm::mat4x4 gmat = glm::rotate(glm::mat4x4(1.0), -angle, gaxis);
    
    return to_matrix(gmat);
}

matrix_float4x4 matrix_perspective(float aspect, float fovy, float near, float far)
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
    
    vector_float4 P = { xScale, 0, 0, 0 };
    vector_float4 Q = { 0, yScale, 0, 0 };
    vector_float4 R = { 0, 0, zScale, -1 };
    vector_float4 S = { 0, 0, wzScale, 0 };
    
    matrix_float4x4 mat = { P, Q, R, S };
    return mat;
}

matrix_float4x4 matrix_orthor(float left, float right, float top, float bottom, float near, float far)
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
    
    vector_float4 P = { xScale, 0, 0, 0 };
    vector_float4 Q = { 0, yScale, 0, 0 };
    vector_float4 R = { 0, 0, zScale, 0 };
    vector_float4 S = { wxScale, wyScale, wzScale, 1 };
    
    matrix_float4x4 mat = { P, Q, R, S };
    return mat;
}

matrix_float3x3 matrix_extract_linear(matrix_float4x4 m)
{
    vector_float3 X = m.columns[0].xyz;
    vector_float3 Y = m.columns[1].xyz;
    vector_float3 Z = m.columns[2].xyz;
    matrix_float3x3 l = { X, Y, Z };
    return l;
}


matrix_float4x4 matrix_rotate(float rotationX, float rotationY)
{
    const vector_float3 xAxis = { 1, 0, 0 };
    const vector_float3 yAxis = { 0, 1, 0 };
    const matrix_float4x4 xRot = matrix_rotation(xAxis, rotationX);
    const matrix_float4x4 yRot = matrix_rotation(yAxis, rotationY);
    
    return matrix_multiply(xRot, yRot);
}


matrix_float4x4 matrix_rotation_append(matrix_float4x4 start, float rotateX, float rotateY)
{
    matrix_float4x4 rotate = matrix_rotate(rotateX, rotateY);
    return matrix_multiply(rotate, start);
}


matrix_float4x4 matrix_lookAt(vector_float3 eye, vector_float3 center, vector_float3 up)
{
    glm::vec3 aeye(eye.x, eye.y, eye.z);
    glm::vec3 acenter(center.x, center.y, center.z);
    glm::vec3 aup(up.x, up.y, up.z);
    
    glm::mat4x4 gmat = glm::lookAt(aeye, acenter, aup);
    return to_matrix(gmat);
}


