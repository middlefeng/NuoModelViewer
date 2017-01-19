

#include <simd/simd.h>


#if __cplusplus
extern "C" {
#endif

/// Builds a translation matrix that translates by the supplied vector
matrix_float4x4 matrix_float4x4_translation(vector_float3 t);

/// Builds a scale matrix that uniformly scales all axes by the supplied factor
matrix_float4x4 matrix_float4x4_uniform_scale(float scale);

/// Builds a rotation matrix that rotates about the supplied axis by an
/// angle (given in radians). The axis should be normalized.
matrix_float4x4 matrix_float4x4_rotation(vector_float3 axis, float angle);

/// Builds a symmetric perspective projection matrix with the supplied aspect ratio,
/// vertical field of view (in radians), and near and far distances
matrix_float4x4 matrix_float4x4_perspective(float aspect, float fovy, float near, float far);
    
matrix_float4x4 matrix_float4x4_orthor(float left, float right, float top, float bottom, float near, float far);

matrix_float3x3 matrix_float4x4_extract_linear(matrix_float4x4);    
    
matrix_float4x4 matrix_rotate(float rotationX, float rotationY);
    
matrix_float4x4 matrix_lookAt(vector_float3 eye, vector_float3 center, vector_float3 up);
    
    
#if __cplusplus
} // extern "C"
#endif
