//
//  NuoRenderParameterState.hpp
//  ModelViewer
//
//  Created by Dong on 5/8/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#ifndef NuoRenderParameterState_hpp
#define NuoRenderParameterState_hpp


#include <unordered_map>
#include <list>
#include <string>


typedef std::unordered_map<unsigned int, bool> NuoParameterUsage;


/**
 *  V: vertex shader
 *  F: fragement shader
 *  C: compute shader
 *
 *  T: texture
 *  B: buffer (also used as acceleration structure, function table)
 *  S: sampler
 */
enum NuoParameterSection
{
    kNuoParameter_VB = 0,
    kNuoParameter_VT,
    kNuoParameter_VS,
    kNuoParameter_FB,
    kNuoParameter_FT,
    kNuoParameter_FS,
    kNuoParameter_CB,
    kNuoParameter_CT,
    kNuoParameter_CS,
    kNuoParameter_Size
};


struct NuoRenderPassParameterUsage
{
    std::string _name;
    NuoParameterUsage _usage[kNuoParameter_Size];
    
    NuoRenderPassParameterUsage(const std::string& name);
};


class NuoRenderPassParameterState
{
    typedef std::list<NuoRenderPassParameterUsage> T;
    
    T _state;
    
public:
    
    void PushState(const std::string& name);
    void PopState();
    
    void SetState(unsigned int i, NuoParameterSection section);
    bool IsParameterSet(unsigned int i, NuoParameterSection section);
    
};

#endif /* NuoRenderParameterState_hpp */
