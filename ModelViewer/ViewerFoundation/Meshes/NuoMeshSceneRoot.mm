//
//  NuoMeshSceneRoot.m
//  ModelViewer
//
//  Created by middleware on 7/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoMeshSceneRoot.h"
#import "NuoBoardMesh.h"
#include "NuoModelBase.h"



@implementation NuoMeshSceneRoot
{
    GlobalBuffers _cacheGlobalBuffer;
}


- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        NSMutableArray* array = [NSMutableArray new];
        [self setMeshes:array];
    }
    
    return self;
}


- (void)setCullEnabled:(BOOL)cullEnabled
{
    [super setCullEnabled:cullEnabled];
    
    for (NuoMesh* mesh in self.meshes)
         [mesh setCullEnabled:cullEnabled];
}


- (void)addBoardObject:(NuoBoardMesh*)board
{
    NSMutableArray<NuoMesh*>* meshes = (NSMutableArray<NuoMesh*>*)self.meshes;
    [meshes insertObject:board atIndex:0];
}


- (void)removeMesh:(NuoMesh*)mesh
{
    NSMutableArray<NuoMesh*>* meshes = (NSMutableArray<NuoMesh*>*)self.meshes;
    [meshes removeObject:mesh];
}


- (void)replaceMesh:(NuoMesh*)meshOld with:(NuoMesh*)replacer
{
    BOOL haveReplaced = NO;
    
    NSMutableArray<NuoMesh*>* meshes = (NSMutableArray<NuoMesh*>*)self.meshes;
    
    // put the main model at the end of the draw queue,
    // for now it is the only one has transparency
    //
    
    for (NSUInteger i = 0; i < meshes.count; ++i)
    {
        if (meshes[i] == meshOld)
        {
            meshes[i] = replacer;
            haveReplaced = YES;
        }
    }
    
    if (!haveReplaced)
        [meshes addObject:replacer];
}


/*- (bool)appendWorldBuffers:(const NuoMatrixFloat44&)transform toBuffers:(GlobalBuffers*)buffers
{
    if (![super appendWorldBuffers:transform toBuffers:nullptr])
        return false;
    
    if (!buffers)
        return true;
    
    [super appendWorldBuffers:transform toBuffers:buffers];
    return true;
}*/



@end
