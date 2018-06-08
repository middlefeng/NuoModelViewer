//
//  NuoLua.h
//  ModelViewer
//
//  Created by middleware on 12/17/16.
//  Copyright © 2016 middleware. All rights reserved.
//


#ifndef __NUO_LUA_H__
#define __NUO_LUA_H__


#include "NuoMathVector.h"
#include <string>
#include <set>

struct lua_State;



class NuoLua
{
    
    lua_State* _luaState;

public:
    
    typedef std::set<std::string> KeySet;
    
    NuoLua();
    ~NuoLua();
    
    void LoadFile(const std::string& path);

    KeySet GetKeysFromTable(int index);

    void GetField(const std::string& key, int index);
    size_t GetArraySize(int index);
    void GetItem(int itemIndex, int index);
    void RemoveField();

    float GetFieldAsNumber(const std::string& key, int index);
    std::string GetFieldAsString(const std::string& key, int index);
    bool GetFieldAsBool(const std::string& key, int index);

    bool GetArrayItemAsBool(size_t item, int index);
    float GetArrayItemAsNumber(size_t item, int index);
    std::string GetArrayItemAsString(size_t item, int index);

    NuoMatrixFloat44 GetMatrixFromTable(int index);

    bool IsNil(int index);

};

#endif
