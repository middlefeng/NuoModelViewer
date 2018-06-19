//
//  NuoRandomBuffer.hpp
//  ModelViewer
//
//  Created by middleware on 6/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#ifndef NuoRandomBuffer_hpp
#define NuoRandomBuffer_hpp


#include <vector>
#include "NuoMathVector.h"


template <class ItemType>
class NuoRandomBuffer
{
    std::vector<ItemType> _buffer;
    
    inline void InitBuffer();
    
public:
    
    inline NuoRandomBuffer(size_t size);
    void* Ptr() { return &_buffer[0]; }
    size_t Size() { return _buffer.size(); }
    size_t BytesSize() { return Size() * sizeof(ItemType); }
};


template <class ItemType>
inline NuoRandomBuffer<ItemType>::NuoRandomBuffer(size_t size)
{
    _buffer.resize(size);
    InitBuffer();
}


template <>
inline void NuoRandomBuffer<NuoVectorFloat2::_typeTrait::_vectorType>::InitBuffer()
{
    for (int i = 0; i < _buffer.size(); ++i)
    {
        _buffer[i] =
        {
            (float)rand() / (float)RAND_MAX,
            (float)rand() / (float)RAND_MAX
        };
    }
}



#endif /* NuoRandomBuffer_hpp */
