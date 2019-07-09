//
//  NuoRayTracingRandom.hpp
//  ModelViewer
//
//  Created by Dong on 6/3/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#ifndef NuoRayTracingRandom_hpp
#define NuoRayTracingRandom_hpp


#include <sys/types.h>


#include "NuoRandomBuffer.h"
#include "NuoRayTracingUniform.h"


template <>
inline void NuoRandomBufferStratified<NuoRayTracingRandomUnit>::UpdateBuffer()
{
    const float invSample = 1.0f / (float)_stratification;
    
    for (size_t i = 0; i < _bufferSize; ++i)
    {
        for (size_t currentDimension = 0; currentDimension < _dimension; ++currentDimension)
        {
            _buffer[i + _bufferSize * currentDimension] =
            {
                // _uv
                {
                    ((float)_stratCurrentX[currentDimension] + UniformRandom()) * invSample,
                    ((float)_stratCurrentY[currentDimension] + UniformRandom()) * invSample
                },
                
                // path determinator
                UniformRandom()
            };
        }
    }
    
    UpdateStratification();
}


typedef NuoRandomBufferStratified<NuoRayTracingRandomUnit> NuoRayTracingRandom;
typedef std::shared_ptr<NuoRayTracingRandom> PNuoRayTracingRandom;


#endif /* NuoRayTracingRandom_hpp */
