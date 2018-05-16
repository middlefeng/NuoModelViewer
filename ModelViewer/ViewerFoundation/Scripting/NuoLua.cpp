//
//  NuoLua.m
//  ModelViewer
//
//  Created by middleware on 12/17/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "NuoLua.h"

extern "C"
{

#include "lua.h"
#include "lauxlib.h"
    
}


NuoLua::NuoLua()
{
    _luaState = luaL_newstate();
}


NuoLua::~NuoLua()
{
    lua_close(_luaState);
}



void NuoLua::LoadFile(const std::string& path)
{
    luaL_dofile(_luaState, path.c_str());
}



NuoLua::KeySet NuoLua::GetKeysFromTable(int index)
{
    NuoLua::KeySet result;
    
    lua_pushnil(_luaState);  /* first key */
    while (lua_next(_luaState, index - 1) != 0)
    {
        const char* key = lua_tostring(_luaState, -2);
        lua_pop(_luaState, 1);
        
        result.insert(key);
    }
    
    return result;
}



void NuoLua::GetField(const std::string& key, int index)
{
    lua_getfield(_luaState, index, key.c_str());
}


size_t NuoLua::GetArraySize(int index)
{
    lua_len(_luaState, index);
    size_t len = lua_tointeger(_luaState, -1);
    lua_pop(_luaState, 1);
    
    return len;
}


void NuoLua::GetItem(int itemIndex, int index)
{
    lua_geti(_luaState, index, itemIndex);
}


void NuoLua::RemoveField()
{
    lua_pop(_luaState, 1);
}


bool NuoLua::GetArrayItemAsBool(size_t item, int index)
{
    lua_geti(_luaState, index, item);
    bool result = lua_toboolean(_luaState, -1);
    lua_pop(_luaState, 1);
    
    return result;
}


float NuoLua::GetArrayItemAsNumber(size_t item, int index)
{
    lua_geti(_luaState, index, item);
    float result = lua_tonumber(_luaState, -1);
    lua_pop(_luaState, 1);
    
    return result;
}


std::string NuoLua::GetArrayItemAsString(size_t item, int index)
{
    lua_geti(_luaState, index, item);
    const std::string result = lua_tostring(_luaState, -1);
    lua_pop(_luaState, 1);
    
    return result;
}


std::string NuoLua::GetFieldAsString(const std::string& key, int index)
{
    lua_getfield(_luaState, index, key.c_str());
    const std::string result = lua_tostring(_luaState, -1);
    lua_pop(_luaState, 1);
    
    return result;
}


float NuoLua::GetFieldAsNumber(const std::string& key, int index)
{
    lua_getfield(_luaState, index, key.c_str());
    float value = lua_tonumber(_luaState, -1);
    lua_pop(_luaState, 1);
    
    return value;
}


bool NuoLua::GetFieldAsBool(const std::string& key, int index)
{
    lua_getfield(_luaState, index, key.c_str());
    bool value = lua_toboolean(_luaState, -1);
    lua_pop(_luaState, 1);
    
    return value;
}


NuoMatrixFloat44 NuoLua::GetMatrixFromTable(int index)
{
    NuoMatrixFloat44 matrix;
    
    for (size_t i = 0; i < 4; ++i)
    {
        NuoVectorFloat4 vector(0, 0, 0, 0);
        lua_geti(_luaState, index, i);
        
        for (int itemIndex = 0; itemIndex < 4; ++itemIndex)
        {
            lua_geti(_luaState, -1, itemIndex);
            switch (itemIndex)
            {
                case 0: vector.x(lua_tonumber(_luaState, -1)); break;
                case 1: vector.y(lua_tonumber(_luaState, -1)); break;
                case 2: vector.z(lua_tonumber(_luaState, -1)); break;
                case 3: vector.w(lua_tonumber(_luaState, -1)); break;
                default: break;
            }
            lua_pop(_luaState, 1);
        }
        
        lua_pop(_luaState, 1);
        
        matrix[i] = vector._vector;
    }
    
    return matrix;
}


bool NuoLua::IsNil(int index)
{
    return lua_isnil(_luaState, index);
}



