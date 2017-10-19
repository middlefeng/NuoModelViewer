//
//  NuoTextureMesh.h
//  ModelViewer
//
//  Created by middleware on 11/3/16.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoScreenSpaceMesh.h"


@interface NuoTextureMesh : NuoScreenSpaceMesh


@property (nonatomic, weak) id<MTLTexture> modelTexture;

/**
 *  in addition to showing a single texture, the mesh can take a second texture and display
 *  both textures in a split view
 */
@property (nonatomic, weak) id<MTLTexture> auxiliaryTexture;
@property (nonatomic, assign) float auxiliaryProportion;


- (instancetype)initWithDevice:(id<MTLDevice>)device;

/**
 *  the pixelFormat is used for the target color attachement and
 *  may or may not the same as to that of modelTexture. Metal supports
 *  this as implicit pixel format conversion.
 *
 *  sampleCount may be 1 if MSAA is not required, usually when there is no 3D involved and
 *  pixels between source and target are aligned
 */
- (void)makePipelineAndSampler:(MTLPixelFormat)pixelFormat withSampleCount:(NSUInteger)sampleCount;

@end
