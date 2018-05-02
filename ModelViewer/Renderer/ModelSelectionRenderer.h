//
//  ModelSelectionRenderer.h
//  ModelViewer
//
//  Created by Dong on 3/27/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoMeshSceneRenderPass.h"

@class NuoMesh;


@interface ModelSelectionRenderer : NuoMeshSceneRenderPass

@property (nonatomic, strong) NSArray<NuoMesh*>* selectedMeshParts;

@end
