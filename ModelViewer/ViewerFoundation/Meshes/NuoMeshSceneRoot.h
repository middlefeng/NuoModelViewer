//
//  NuoMeshSceneRoot.h
//  ModelViewer
//
//  Created by middleware on 7/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoMeshCompound.h"


@class NuoBoardMesh;


@interface NuoMeshSceneRoot : NuoMeshCompound


- (void)addBoardObject:(NuoBoardMesh*)board;
- (void)removeMesh:(NuoMesh*)mesh;
- (void)replaceMesh:(NuoMesh*)meshOld with:(NuoMesh*)replacer;


@end


