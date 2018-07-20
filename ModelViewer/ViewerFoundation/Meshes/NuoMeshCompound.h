//
//  NuoMeshCompound.h
//  ModelViewer
//
//  Created by middleware on 5/18/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoMesh.h"

#include <vector>


@interface NuoMeshCompound : NuoMesh


@property (nonatomic, strong) NSArray<NuoMesh*>* meshes;

- (std::vector<uint32_t>)maskBuffer;

@end
