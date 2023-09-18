//
//  ModelConfiguration.h
//  ModelViewer
//
//  Created by Dong on 9/17/23
//  Copyright © 2023 Dong Feng. All rights reserved.
//


#include <memory>


class NuoLua;



class ModelConfiguration
{
    
    std::shared_ptr<NuoLua> _lua;
    
public:
        
    ModelConfiguration();
    
    bool UseMPSIntersector();
    bool UseImageIO();
    
};

