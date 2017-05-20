//
//  NuoMeshCompound.h
//  ModelViewer
//
//  Created by middleware on 5/18/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoMesh.h"


@interface NuoMeshCompound : NuoMesh


@property (nonatomic, assign) matrix_float4x4 modelTransform;
@property (nonatomic, strong) NSArray<NuoMesh*>* meshes;
@property (nonatomic, strong) NSArray<id<MTLBuffer>>* uniformBuffers;
@property (nonatomic, assign) BOOL cullEnabled;

@property (nonatomic, assign) float maxSpan;

@end
