//
//  NuoModelArrow.cpp
//  ModelViewer
//
//  Created by middleware on 8/28/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#include "NuoModelArrow.h"
#include <math.h>



static const size_t kNumOfFins = 36;




NuoModelArrow::NuoModelArrow(float bodyLength, float bodyRadius, float headLength, float headRadius)
: _bodyLength(bodyLength),
  _bodyRadius(bodyRadius),
  _headLength(headLength),
  _headRadius(headRadius)
{
}


void NuoModelArrow::CreateBuffer()
{
    CreateEndSurface();
    CreateBodySurface();
    CreateMiddleSurface();
    CreateHeadSurface();
    GenerateIndices();
}


NuoVectorFloat4 NuoModelArrow::GetMiddleSurfaceVertex(size_t index, size_t type)
{
    float arc = ((float)index / (float)kNumOfFins) * 2 * 3.1416;
    float radius = (1 - type) * _bodyRadius + type * _headRadius;
    
    float x = cos(arc) * radius;
    float y = sin(arc) * radius;
    float z = _bodyLength;
    
    return NuoVectorFloat4(x, y, z, 1.0);
}


NuoVectorFloat4 NuoModelArrow::GetBodyVertex(size_t index, size_t type)
{
    float arc = ((float)index / (float)kNumOfFins) * 2 * 3.1416;
    float x = cos(arc) * _bodyRadius;
    float y = sin(arc) * _bodyRadius;
    float z = type * _bodyLength;
    
    return NuoVectorFloat4(x, y, z, 1.0);
}


NuoVectorFloat4 NuoModelArrow::GetBodyNormal(size_t index)
{
    float arc = ((float)index / (float)kNumOfFins) * 2 * 3.1416;
    float x = cos(arc);
    float y = sin(arc);
    
    return NuoVectorFloat4(x, y, 0, 0);
}


NuoVectorFloat4 NuoModelArrow::GetEndVertex(size_t type)
{
    float length = _bodyLength + _headLength;
    return NuoVectorFloat4(0, 0, length * type, 0.0);
}



NuoVectorFloat4 NuoModelArrow::GetHeadNormal(size_t index)
{
    NuoVectorFloat4 outward4 = GetBodyNormal(index);
    NuoVectorFloat4 middleVertex = GetMiddleSurfaceVertex(index, 1);
    NuoVectorFloat4 headVertex(0, 0, _bodyLength + _headLength, 1);
    
    NuoVectorFloat3 bodyVector = NuoVectorFloat3(headVertex.x() - middleVertex.x(),
                                                 headVertex.y() - middleVertex.y(),
                                                 headVertex.z() - middleVertex.z());
    NuoVectorFloat3 outward = NuoVectorFloat3(outward4.x(), outward4.y(), outward4.z());
    
    NuoVectorFloat3 tangentVector = NuoCross(outward, bodyVector);
    NuoVectorFloat3 normal = NuoCross(bodyVector, tangentVector);
    normal = normal.Normalize();
    
    return NuoVectorFloat4(normal.x(), normal.y(), normal.z(), 0.0);
}


void NuoModelArrow::CreateEndSurface()
{
    NuoVectorFloat4 endCenter(0, 0, 0, 1.0);
    std::vector<float> bufferPosition(9), bufferNormal(3);
    
    bufferNormal[0] = 0;
    bufferNormal[1] = 0;
    bufferNormal[2] = -1.0;
    
    for (size_t index = 0; index < kNumOfFins; ++ index)
    {
        NuoVectorFloat4 edgeVertex1 = GetBodyVertex(index, 0);
        NuoVectorFloat4 edgeVertex2 = GetBodyVertex(index + 1, 0);
        
        bufferPosition[0] = endCenter.x();
        bufferPosition[1] = endCenter.y();
        bufferPosition[2] = endCenter.z();
        bufferPosition[3] = edgeVertex2.x();
        bufferPosition[4] = edgeVertex2.y();
        bufferPosition[5] = edgeVertex2.z();
        bufferPosition[6] = edgeVertex1.x();
        bufferPosition[7] = edgeVertex1.y();
        bufferPosition[8] = edgeVertex1.z();
        
        AddPosition(0, bufferPosition);
        AddNormal(0, bufferNormal);
        AddPosition(1, bufferPosition);
        AddNormal(0, bufferNormal);
        AddPosition(2, bufferPosition);
        AddNormal(0, bufferNormal);
    }
}


void NuoModelArrow::CreateBodySurface()
{
    std::vector<float> bufferPosition(18), bufferNormal(18);
    
    for (size_t index = 0; index < kNumOfFins; ++ index)
    {
        NuoVectorFloat4 endVertex1 = GetBodyVertex(index, 0);
        NuoVectorFloat4 endVertex2 = GetBodyVertex(index + 1, 0);
        NuoVectorFloat4 headVertex1 = GetBodyVertex(index, 1);
        NuoVectorFloat4 headVertex2 = GetBodyVertex(index + 1, 1);
        
        NuoVectorFloat4 normal1 = GetBodyNormal(index);
        NuoVectorFloat4 normal2 = GetBodyNormal(index + 1);
        
        // triangle 1
        bufferPosition[0] = headVertex1.x();
        bufferPosition[1] = headVertex1.y();
        bufferPosition[2] = headVertex1.z();
        bufferPosition[3] = endVertex1.x();
        bufferPosition[4] = endVertex1.y();
        bufferPosition[5] = endVertex1.z();
        bufferPosition[6] = headVertex2.x();
        bufferPosition[7] = headVertex2.y();
        bufferPosition[8] = headVertex2.z();
        
        bufferNormal[0] = normal1.x();
        bufferNormal[1] = normal1.y();
        bufferNormal[2] = normal1.z();
        bufferNormal[3] = normal1.x();
        bufferNormal[4] = normal1.y();
        bufferNormal[5] = normal1.z();
        bufferNormal[6] = normal2.x();
        bufferNormal[7] = normal2.y();
        bufferNormal[8] = normal2.z();
        
        // triangle 2
        bufferPosition[9] = headVertex2.x();
        bufferPosition[10] = headVertex2.y();
        bufferPosition[11] = headVertex2.z();
        bufferPosition[12] = endVertex1.x();
        bufferPosition[13] = endVertex1.y();
        bufferPosition[14] = endVertex1.z();
        bufferPosition[15] = endVertex2.x();
        bufferPosition[16] = endVertex2.y();
        bufferPosition[17] = endVertex2.z();
        
        bufferNormal[9] = normal2.x();
        bufferNormal[10] = normal2.y();
        bufferNormal[11] = normal2.z();
        bufferNormal[12] = normal1.x();
        bufferNormal[13] = normal1.y();
        bufferNormal[14] = normal1.z();
        bufferNormal[15] = normal2.x();
        bufferNormal[16] = normal2.y();
        bufferNormal[17] = normal2.z();
        
        AddPosition(0, bufferPosition);
        AddNormal(0, bufferNormal);
        AddPosition(1, bufferPosition);
        AddNormal(1, bufferNormal);
        AddPosition(2, bufferPosition);
        AddNormal(2, bufferNormal);
        
        AddPosition(3, bufferPosition);
        AddNormal(3, bufferNormal);
        AddPosition(4, bufferPosition);
        AddNormal(4, bufferNormal);
        AddPosition(5, bufferPosition);
        AddNormal(5, bufferNormal);
    }
}


void NuoModelArrow::CreateMiddleSurface()
{
    std::vector<float> bufferPosition(18), bufferNormal(3);
    
    bufferNormal[0] = 0;
    bufferNormal[1] = 0;
    bufferNormal[2] = -1.0;
    
    for (size_t index = 0; index < kNumOfFins; ++ index)
    {
        NuoVectorFloat4 innerVertex1 = GetMiddleSurfaceVertex(index, 0);
        NuoVectorFloat4 innerVertex2 = GetMiddleSurfaceVertex(index + 1, 0);
        NuoVectorFloat4 outterVertex1 = GetMiddleSurfaceVertex(index, 1);
        NuoVectorFloat4 outterVertex2 = GetMiddleSurfaceVertex(index + 1, 1);
        
        // triangle 1
        bufferPosition[0] = innerVertex1.x();
        bufferPosition[1] = innerVertex1.y();
        bufferPosition[2] = innerVertex1.z();
        bufferPosition[3] = outterVertex2.x();
        bufferPosition[4] = outterVertex2.y();
        bufferPosition[5] = outterVertex2.z();
        bufferPosition[6] = outterVertex1.x();
        bufferPosition[7] = outterVertex1.y();
        bufferPosition[8] = outterVertex1.z();
        
        // triangle 2
        bufferPosition[9] = innerVertex2.x();
        bufferPosition[10] = innerVertex2.y();
        bufferPosition[11] = innerVertex2.z();
        bufferPosition[12] = outterVertex2.x();
        bufferPosition[13] = outterVertex2.y();
        bufferPosition[14] = outterVertex2.z();
        bufferPosition[15] = innerVertex1.x();
        bufferPosition[16] = innerVertex1.y();
        bufferPosition[17] = innerVertex1.z();
        
        AddPosition(0, bufferPosition);
        AddNormal(0, bufferNormal);
        AddPosition(1, bufferPosition);
        AddNormal(0, bufferNormal);
        AddPosition(2, bufferPosition);
        AddNormal(0, bufferNormal);
        
        AddPosition(3, bufferPosition);
        AddNormal(0, bufferNormal);
        AddPosition(4, bufferPosition);
        AddNormal(0, bufferNormal);
        AddPosition(5, bufferPosition);
        AddNormal(0, bufferNormal);
    }
}


void NuoModelArrow::CreateHeadSurface()
{
    std::vector<float> bufferPosition(9), bufferNormal(9);
    
    for (size_t index = 0; index < kNumOfFins; ++ index)
    {
        NuoVectorFloat4 vertex1 = GetMiddleSurfaceVertex(index, 1);
        NuoVectorFloat4 vertex2 = GetMiddleSurfaceVertex(index + 1, 1);
        NuoVectorFloat4 headVertex(0, 0, _bodyLength + _headLength, 1);
        
        bufferPosition[0] = headVertex.x();
        bufferPosition[1] = headVertex.y();
        bufferPosition[2] = headVertex.z();
        bufferPosition[3] = vertex1.x();
        bufferPosition[4] = vertex1.y();
        bufferPosition[5] = vertex1.z();
        bufferPosition[6] = vertex2.x();
        bufferPosition[7] = vertex2.y();
        bufferPosition[8] = vertex2.z();
        
        NuoVectorFloat4 normal1 = GetHeadNormal(index);
        NuoVectorFloat4 normal2 = GetHeadNormal(index + 1);
        
        bufferNormal[0] = normal1.x();
        bufferNormal[1] = normal1.y();
        bufferNormal[2] = normal1.z();
        bufferNormal[3] = normal1.x();
        bufferNormal[4] = normal1.y();
        bufferNormal[5] = normal1.z();
        bufferNormal[6] = normal2.x();
        bufferNormal[7] = normal2.y();
        bufferNormal[8] = normal2.z();
     
        AddPosition(0, bufferPosition);
        AddNormal(0, bufferNormal);
        AddPosition(1, bufferPosition);
        AddNormal(1, bufferNormal);
        AddPosition(2, bufferPosition);
        AddNormal(2, bufferNormal);
    }
}


