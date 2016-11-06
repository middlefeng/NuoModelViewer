//
//  NuoTextureMesh.h
//  ModelViewer
//
//  Created by middleware on 11/3/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "NuoMesh.h"


@interface NuoTextureMesh : NuoMesh

- (instancetype)initWithDevice:(id<MTLDevice>)device
                   withTexture:(id<MTLTexture>)texture;

- (void)makePipelineAndSampler;

@end
