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




@end
