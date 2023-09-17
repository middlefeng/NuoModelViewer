//
//  ModelConfiguration.cpp
//  ModelViewer
//
//  Created by Dong on 9/17/23
//  Copyright © 2023 Dong Feng. All rights reserved.
//

#ifndef __MODEL_CONFIGURATION_H__
#define __MODEL_CONFIGURATION_H__


#include "ModelConfiguration.h"

#include <sys/stat.h>

#include "NuoLua.h"
#include "NuoDirectoryUtils.h"


static ModelConfiguration* _sModelConfiguration = nullptr;


ModelConfiguration* ModelConfiguration::GetConfiguration()
{
    if (!_sModelConfiguration)
    {
        _sModelConfiguration = new ModelConfiguration;
    }
    
    const char* path = pathForOptionConfigureFile();
    
    struct stat buffer;
    bool fileExists = (stat(path, &buffer) == 0);
    if (!fileExists)
    {
        FILE *file = fopen(path, "w");
        assert(file != nullptr);
        
        fclose(file);
    }
    
    _sModelConfiguration->_lua = std::make_shared<NuoLua>();
    _sModelConfiguration->_lua->LoadFile(pathForOptionConfigureFile());
    
    return _sModelConfiguration;
}


#endif
