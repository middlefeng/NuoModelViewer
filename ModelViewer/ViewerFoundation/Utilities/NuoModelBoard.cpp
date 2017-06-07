//
//  NuoModelCube.cpp
//  ModelViewer
//
//  Created by middleware on 5/22/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#include "NuoModelBoard.h"


NuoModelBoard::NuoModelBoard(float width, float height, float thickness)
    : _width(width), _height(height), _thickness(thickness)
{
}


void NuoModelBoard::CreateBuffer()
{
    vector_float2 corners[4];
    
    corners[kCorner_BL].x = -_width / 2.0;
    corners[kCorner_BL].y = -_height / 2.0;
    
    corners[kCorner_BR].x = _width / 2.0;
    corners[kCorner_BR].y = -_height / 2.0;
    
    corners[kCorner_TL].x = -_width / 2.0;
    corners[kCorner_TL].y = _height / 2.0;
    
    corners[kCorner_TR].x = _width / 2.0;
    corners[kCorner_TR].y = _height / 2.0;
    
    std::vector<float> bufferPosition(9), bufferNormal(9);
    float halfHeight = _height / 2.0;
    
    // top
    bufferPosition[0] = corners[kCorner_TL].x;
    bufferPosition[1] = corners[kCorner_TL].y;
    bufferPosition[2] = halfHeight;
    bufferPosition[3] = corners[kCorner_BL].x;
    bufferPosition[4] = corners[kCorner_BL].y;
    bufferPosition[5] = halfHeight;
    bufferPosition[6] = corners[kCorner_TR].x;
    bufferPosition[7] = corners[kCorner_TR].y;
    bufferPosition[8] = halfHeight;
    
    bufferNormal[0] = 0;
    bufferNormal[1] = 0;
    bufferNormal[2] = 1;
    bufferNormal[3] = 0;
    bufferNormal[4] = 0;
    bufferNormal[5] = 1;
    bufferNormal[6] = 0;
    bufferNormal[7] = 0;
    bufferNormal[8] = 1;
    
    AddPosition(0, bufferPosition);
    AddNormal(0, bufferNormal);
    AddPosition(1, bufferPosition);
    AddNormal(1, bufferNormal);
    AddPosition(2, bufferPosition);
    AddNormal(2, bufferNormal);
    
    GenerateIndices();
}

