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


ModelConfiguration::ModelConfiguration()
{
    const char* path = pathForOptionConfigureFile();
        
    struct stat buffer;
    bool fileExists = (stat(path, &buffer) == 0);
    if (!fileExists)
    {
        FILE *file = fopen(path, "w");
        assert(file != nullptr);
        
        fclose(file);
    }
        
    _lua = std::make_shared<NuoLua>();
    _lua->LoadFile(path);
}


bool ModelConfiguration::UseMPSIntersector()
{
    if (_lua->IsNil(-1))
    {
        return false;
    }
    
    const bool useMPS = _lua->GetFieldAsBool("MPSIntersector", -1);
    return useMPS;
}


bool ModelConfiguration::UseImageIO()
{
    if (_lua->IsNil(-1))
    {
        return true;
    }
    
    const bool imageIO = _lua->GetFieldAsBool("ImageIOSave", -1);
    return imageIO;
}


#endif
