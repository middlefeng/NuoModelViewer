//
//  NuoModelCube.hpp
//  ModelViewer
//
//  Created by middleware on 5/22/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#ifndef NuoModelBoard_hpp
#define NuoModelBoard_hpp


#include "NuoModelBase.h"

class NuoModelBoard : public NuoModelSimple
{
    
    float _width;
    float _height;
    float _thickness;
    
    enum
    {
        kCorner_TL,
        kCorner_TR,
        kCorner_BL,
        kCorner_BR
    }
    kCorner;
    
public:
    
    NuoModelBoard(float width, float height, float thickness);
    
    void CreateBuffer();
    
private:
    
    
};


typedef std::shared_ptr<NuoModelBoard> PNuoModelBoard;

#endif /* NuoModelCube_hpp */
