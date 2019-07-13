//
//  NuoGlobalBuffers.hpp
//  ModelViewer
//
//  Created by Dong on 7/9/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#ifndef NuoGlobalBuffers_hpp
#define NuoGlobalBuffers_hpp

#include "NuoMathVector.h"
#include "NuoRayTracingUniform.h"

#include <vector>

/**
 *  buffers which are, or could be concatenated to, a continous buffer set used for
 *  global algorithm, e.g. ray tracing, global illuminating
 *
 *  the buffer is a per-vertex buffer. it cannot be passed to the MSP structure which
 *  requires per-primitive buffer. instead, it is for the subsequent custom computer
 *  shaders for global algorithms
 */

typedef std::vector<NuoVectorFloat3::_typeTrait::_vectorType> NuoVectorBufferItem;

struct NuoGlobalBuffers
{
    NuoVectorBufferItem _vertices;
    std::vector<NuoRayTracingMaterial> _materials;
    
    std::vector<uint32_t> _indices;
    std::vector<uint32_t> _indicesLightSource;
    std::vector<void*> _textureMap;
    
    void Union(const NuoGlobalBuffers& other);
    void TransformPosition(const NuoMatrixFloat44& trans);
    void TransformVector(const NuoMatrixFloat33& trans);
    void Clear();
    
    void UpdateLightSourceIndices();
};


#endif /* NuoGlobalBuffers_hpp */
