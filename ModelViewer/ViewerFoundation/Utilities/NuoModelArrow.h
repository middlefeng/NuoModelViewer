//
//  NuoModelArrow.hpp
//  ModelViewer
//
//  Created by middleware on 8/28/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#ifndef NuoModelArrow_hpp
#define NuoModelArrow_hpp


#include "NuoModelBase.h"


class NuoModelArrow : public NuoModelSimple
{
    
    float _bodyLength;
    float _bodyRadius;
    float _headLength;
    float _headRadius;
    
    
public:
    
    NuoModelArrow(float bodyLength, float bodyRadius, float headLength, float headRadius);
    
    void CreateBuffer();

private:
    
    vector_float4 GetBodyVertex(size_t index, size_t type);
    vector_float4 GetBodyNormal(size_t index);
    vector_float4 GetEndVertex(size_t type);
    vector_float4 GetHeadVertex(size_t index);
    
    void CreateEndSurface();
    void CreateBodySurface();
    
};



#endif /* NuoModelArrow_hpp */
