//
//  NuoRenderParameterState.cpp
//  ModelViewer
//
//  Created by Dong on 5/8/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#include <cassert>

#include "NuoRenderParameterState.h"

#include <cassert>



NuoRenderPassParameterUsage::NuoRenderPassParameterUsage(const std::string& name)
    : _name(name)
{
}




/**
 *    NuoRenderPassParameterState
 */


void NuoRenderPassParameterState::PushState(const std::string& name)
{
    _state.insert(_state.end(), NuoRenderPassParameterUsage(name));
}

void NuoRenderPassParameterState::PopState()
{
    _state.erase((--(_state.end())));
}

void NuoRenderPassParameterState::SetState(unsigned int i, NuoParameterSection section)
{
    assert(_state.size());
    assert(IsParameterSet(i, section) == false);
    
    NuoRenderPassParameterUsage& usage = *(_state.rbegin());
    usage._usage[section].insert(std::make_pair(i, true));
}

bool NuoRenderPassParameterState::IsParameterSet(unsigned int i, NuoParameterSection section)
{
    for (auto itr = _state.rbegin(); itr != _state.rend(); --itr)
    {
        const NuoRenderPassParameterUsage& usage = *itr;
        if (usage._usage[section].find(i) != usage._usage[section].end())
        {
            return true;
        }
    }
    
    return false;
}
