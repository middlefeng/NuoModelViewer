//
//  NuoTextureMesh.h
//  ModelViewer
//
//  Created by middleware on 11/3/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "NuoMesh.h"


@interface NuoTextureMesh : NuoMesh


@property (nonatomic, weak) id<MTLTexture> modelTexture;


- (instancetype)initWithDevice:(id<MTLDevice>)device;

/**
 *  the pixelFormat is used for the target color attachement and
 *  may or may not the same as to that of modelTexture. Metal supports
 *  this as implicit pixel format conversion.
 */
- (void)makePipelineAndSampler:(MTLPixelFormat)pixelFormat;

@end
