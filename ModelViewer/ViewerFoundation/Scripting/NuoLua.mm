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


@implementation NuoLua
{
    lua_State* _luaState;
}



- (instancetype)init
{
    self = [super init];
    if (self)
        _luaState = luaL_newstate();
    
    return self;
}



- (void)loadFile:(NSString*)path
{
    luaL_dofile(_luaState, path.UTF8String);
}



- (NSArray*)getKeysFromTable:(int)index
{
    NSMutableArray* result = [[NSMutableArray alloc] init];
    
    lua_pushnil(_luaState);  /* first key */
    while (lua_next(_luaState, index - 1) != 0)
    {
        const char* key = lua_tostring(_luaState, -2);
        lua_pop(_luaState, 1);
        
        [result addObject:[[NSString alloc] initWithUTF8String:key]];
    }
    
    return result;
}



- (void)getField:(NSString*)key fromTable:(int)index
{
    lua_getfield(_luaState, index, key.UTF8String);
}


- (size_t)getArraySize:(int)index
{
    lua_len(_luaState, index);
    size_t len = lua_tointeger(_luaState, -1);
    lua_pop(_luaState, 1);
    
    return len;
}


- (void)getItem:(int)itemIndex fromTable:(int)index
{
    lua_geti(_luaState, index, itemIndex);
}


- (void)removeField
{
    lua_pop(_luaState, 1);
}


- (bool)getArrayItemAsBool:(size_t)item fromTable:(int)index
{
    lua_geti(_luaState, index, item);
    bool result = lua_toboolean(_luaState, -1);
    lua_pop(_luaState, 1);
    
    return result;
}


- (float)getArrayItemAsNumber:(size_t)item fromTable:(int)index
{
    lua_geti(_luaState, index, item);
    float result = lua_tonumber(_luaState, -1);
    lua_pop(_luaState, 1);
    
    return result;
}


- (NSString*)getArrayItemAsString:(size_t)item fromTable:(int)index
{
    lua_geti(_luaState, index, item);
    const char* result = lua_tostring(_luaState, -1);
    lua_pop(_luaState, 1);
    
    return [[NSString alloc] initWithUTF8String:result];
}


- (NSString*)getFieldAsString:(NSString*)key fromTable:(int)index
{
    lua_getfield(_luaState, index, key.UTF8String);
    const char* result = lua_tostring(_luaState, -1);
    NSString* r = [[NSString alloc] initWithUTF8String:result];
    lua_pop(_luaState, 1);
    
    return r;
}


- (float)getFieldAsNumber:(NSString*)key fromTable:(int)index
{
    lua_getfield(_luaState, index, key.UTF8String);
    float value = lua_tonumber(_luaState, -1);
    lua_pop(_luaState, 1);
    
    return value;
}


- (bool)getFieldAsBool:(NSString*)key fromTable:(int)index
{
    lua_getfield(_luaState, index, key.UTF8String);
    bool value = lua_toboolean(_luaState, -1);
    lua_pop(_luaState, 1);
    
    return value;
}


- (NuoMatrixFloat44)getMatrixFromTable:(int)index
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


- (bool)isNil:(int)index
{
    return lua_isnil(_luaState, index);
}



@end
