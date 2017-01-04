//
//  NuoLua.h
//  ModelViewer
//
//  Created by middleware on 12/17/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <simd/simd.h>



struct lua_State;



@interface NuoLua : NSObject


- (void)loadFile:(NSString*)path;

- (void)getField:(NSString*)key fromTable:(int)index;
- (void)getItem:(int)itemIndex fromTable:(int)index;
- (void)removeField;
- (float)getFieldAsNumber:(NSString*)key fromTable:(int)index;

- (matrix_float4x4)getMatrixFromTable:(int)index;

@end
