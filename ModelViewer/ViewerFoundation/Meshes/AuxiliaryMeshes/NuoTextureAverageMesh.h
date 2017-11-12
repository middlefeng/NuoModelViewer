//
//  NuoTextureAverageMesh.h
//  ModelViewer
//
//  Created by Dong on 11/11/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoScreenSpaceMesh.h"
#import <Metal/Metal.h>


@interface NuoTextureAverageMesh : NuoScreenSpaceMesh

- (instancetype)initWithDevice:(id<MTLDevice>)device;

- (void)appendTexture:(id<MTLTexture>)texture;

@end
