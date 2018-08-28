//
//  NuoIlluminationMesh.h
//  ModelViewer
//
//  Created by middleware on 8/27/18.
//  Copyright © 2018 middleware. All rights reserved.
//



#import "NuoTextureMesh.h"



@interface NuoIlluminationMesh : NuoTextureMesh


@property (nonatomic, strong) id<MTLTexture> illuminationMap;


@end


