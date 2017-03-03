//
//  NuoMeshCube.h
//  ModelViewer
//
//  Created by dfeng on 3/3/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoMesh.h"




@interface NuoCubeMesh : NuoMesh


@property (nonatomic, weak) id<MTLTexture> cubeTexture;


- (instancetype)initWithDevice:(id<MTLDevice>)device;


@end
