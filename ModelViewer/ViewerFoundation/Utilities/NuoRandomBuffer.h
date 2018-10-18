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

protected:

    ItemType* _buffer;
    size_t _bufferSize;
    size_t _dimension;
    
public:
    
    NuoRandomBuffer(size_t size, size_t dimension);
    
    void SetBuffer(void* buffer) { _buffer = (ItemType*)buffer; }
    size_t Size() { return _bufferSize; }
    size_t BytesSize() { return _bufferSize * _dimension * sizeof(ItemType); }
    
    virtual void UpdateBuffer() = 0;

protected:
    
    inline float UniformRandom();
    
};


template <class ItemType>
class NuoRandomBufferStratified : public NuoRandomBuffer<ItemType>
{

protected:
    
    size_t _stratification;
    size_t _stratCurrentDimension;
    size_t* _stratCurrentX;
    size_t* _stratCurrentY;
    
public:
    
    inline NuoRandomBufferStratified(size_t size, size_t dimension,
                                     size_t stratification);
    
    virtual void UpdateBuffer() override;
};


template <class ItemType>
NuoRandomBuffer<ItemType>::NuoRandomBuffer(size_t size, size_t dimension)
    : _bufferSize(size),
      _dimension(dimension)
{
}



template <class ItemType>
inline float NuoRandomBuffer<ItemType>::UniformRandom()
{
    return (float)rand() / (float)RAND_MAX;
}



template <class ItemType>
NuoRandomBufferStratified<ItemType>::NuoRandomBufferStratified(size_t size, size_t dimension,
                                                               size_t stratification)
    : NuoRandomBuffer<ItemType>(size, dimension),
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
inline void NuoRandomBufferStratified<NuoVectorFloat2::_typeTrait::_vectorType>::UpdateBuffer()
{
    const float invSample = 1.0f / (float)_stratification;
    
    for (size_t i = 0; i < _bufferSize; ++i)
    {
        for (size_t currentDimension = 0; currentDimension < _dimension; ++currentDimension)
        {
            _buffer[i + _bufferSize * currentDimension] =
            {
                ((float)_stratCurrentX[currentDimension] + UniformRandom()) * invSample,
                ((float)_stratCurrentY[currentDimension] + UniformRandom()) * invSample
            };
        }
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


typedef NuoRandomBufferStratified<NuoVectorFloat2::_typeTrait::_vectorType> RandomGenerator;
typedef std::shared_ptr<RandomGenerator> PRandomGenerator;


#endif /* NuoRandomBuffer_hpp */
