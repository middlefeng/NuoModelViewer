//
//  NuoLua.h
//  ModelViewer
//
//  Created by middleware on 12/17/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "NuoMathVector.h"


struct lua_State;



@interface NuoLua : NSObject


- (void)loadFile:(NSString*)path;

- (NSArray*)getKeysFromTable:(int)index;

- (void)getField:(NSString*)key fromTable:(int)index;
- (size_t)getArraySize:(int)index;
- (void)getItem:(int)itemIndex fromTable:(int)index;
- (void)removeField;

- (float)getFieldAsNumber:(NSString*)key fromTable:(int)index;
- (NSString*)getFieldAsString:(NSString*)key fromTable:(int)index;
- (bool)getFieldAsBool:(NSString*)key fromTable:(int)index;

- (bool)getArrayItemAsBool:(size_t)item fromTable:(int)index;
- (float)getArrayItemAsNumber:(size_t)item fromTable:(int)index;
- (NSString*)getArrayItemAsString:(size_t)item fromTable:(int)index;

- (NuoMatrixFloat44)getMatrixFromTable:(int)index;

- (bool)isNil:(int)index;

@end
