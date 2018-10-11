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
    
    size_t _stratification;
    size_t _stratCurrentDimension;
    size_t* _stratCurrentX;
    size_t* _stratCurrentY;
    
public:
    
    inline NuoRandomBuffer(size_t size, size_t dimension,
                           size_t stratification);
    
    void SetBuffer(void* buffer) { _buffer = (ItemType*)buffer; }
    size_t Size() { return _bufferSize; }
    size_t BytesSize() { return _bufferSize * _dimension * sizeof(ItemType); }
    
    void UpdateBuffer();
};


template <class ItemType>
inline NuoRandomBuffer<ItemType>::NuoRandomBuffer(size_t size, size_t dimension,
                                                  size_t stratification)
    : _bufferSize(size),
      _dimension(dimension),
      _stratification(stratification),
      _stratCurrentDimension(0)
{
    _stratCurrentX = new size_t[dimension];
    _stratCurrentY = new size_t[dimension];
    
    for (size_t i = 0; i < dimension; ++i)
    {
        _stratCurrentX[i] = 0;
        _stratCurrentY[i] = 0;
    }
}


template <>
inline void NuoRandomBuffer<NuoVectorFloat2::_typeTrait::_vectorType>::UpdateBuffer()
{
    const float invSample = 1.0f / (float)_stratification;
    
    for (size_t i = 0; i < _bufferSize; ++i)
    {
        for (size_t currentDimension = 0; currentDimension < _dimension; ++currentDimension)
        {
            _buffer[i + _bufferSize * currentDimension] =
            {
                ((float)_stratCurrentX[currentDimension] + (float)rand() / (float)RAND_MAX) * invSample,
                ((float)_stratCurrentY[currentDimension] + (float)rand() / (float)RAND_MAX) * invSample
            };
        }
    }
    
    if (_dimension == 2)
    {
        printf("Stratifying: %lu, %lu, %lu, %lu.\n", _stratCurrentX[0], _stratCurrentY[0], _stratCurrentX[1], _stratCurrentY[1]);
    }
    
    for (size_t i = 0; i < _dimension;)
    {
        _stratCurrentX[i] += 1;
        
        if (_stratCurrentX[i] == _stratification)
        {
            _stratCurrentX[i] = 0;
            _stratCurrentY[i] += 1;
        }
        else
        {
            break;
        }
        
        if (_stratCurrentY[i] == _stratification)
        {
            _stratCurrentY[i] = 0;
            i += 1;
        }
        else
        {
            break;
        }
    }
}


typedef NuoRandomBuffer<NuoVectorFloat2::_typeTrait::_vectorType> RandomGenerator;
typedef std::shared_ptr<RandomGenerator> PRandomGenerator;


#endif /* NuoRandomBuffer_hpp */
