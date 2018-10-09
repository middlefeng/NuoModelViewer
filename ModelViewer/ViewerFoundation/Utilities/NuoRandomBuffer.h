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
    ItemType* _buffer;
    size_t _bufferSize;
    size_t _dimension;
    
public:
    
    inline NuoRandomBuffer(size_t size, size_t dimension);
    void SetBuffer(void* buffer) { _buffer = (ItemType*)buffer; }
    size_t Size() { return _bufferSize; }
    size_t BytesSize() { return _bufferSize * sizeof(ItemType); }
    
    void UpdateBuffer();
};


template <class ItemType>
inline NuoRandomBuffer<ItemType>::NuoRandomBuffer(size_t size, size_t dimension)
    : _bufferSize(size),
      _dimension(dimension)
{
}


template <>
inline void NuoRandomBuffer<NuoVectorFloat2::_typeTrait::_vectorType>::UpdateBuffer()
{
    size_t amount = _bufferSize * _dimension;
    
    for (int i = 0; i < amount; ++i)
    {
        _buffer[i] =
        {
            (float)rand() / (float)RAND_MAX,
            (float)rand() / (float)RAND_MAX
        };
    }
}


typedef NuoRandomBuffer<NuoVectorFloat2::_typeTrait::_vectorType> RandomGenerator;
typedef std::shared_ptr<RandomGenerator> PRandomGenerator;


#endif /* NuoRandomBuffer_hpp */
