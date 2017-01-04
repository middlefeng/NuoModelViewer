//
//  NuoLua.m
//  ModelViewer
//
//  Created by middleware on 12/17/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "NuoLua.h"

#include "lua.h"
#include "lauxlib.h"


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



- (void)getField:(NSString*)key fromTable:(int)index
{
    lua_getfield(_luaState, index, key.UTF8String);
}


- (void)getItem:(int)itemIndex fromTable:(int)index
{
    lua_geti(_luaState, index, itemIndex);
}


- (void)removeField
{
    lua_pop(_luaState, 1);
}


- (float)getFieldAsNumber:(NSString*)key fromTable:(int)index
{
    lua_getfield(_luaState, index, key.UTF8String);
    float value = lua_tonumber(_luaState, -1);
    lua_pop(_luaState, 1);
    
    return value;
}


- (matrix_float4x4)getMatrixFromTable:(int)index
{
    matrix_float4x4 matrix = { 0 };
    
    for (size_t i = 0; i < 4; ++i)
    {
        vector_float4 vector = { 0 };
        lua_geti(_luaState, index, i);
        
        for (int itemIndex = 0; itemIndex < 4; ++itemIndex)
        {
            lua_geti(_luaState, -1, itemIndex);
            vector[itemIndex] = lua_tonumber(_luaState, -1);
            lua_pop(_luaState, 1);
        }
        
        lua_pop(_luaState, 1);
        
        matrix.columns[i] = vector;
    }
    
    return matrix;
}




@end
