//
//  NuoClearMesh.h
//  ModelViewer
//
//  Created by Dong on 3/10/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoScreenSpaceMesh.h"



@interface NuoClearMesh : NuoScreenSpaceMesh


@property (nonatomic, assign) MTLClearColor clearColor;


- (void)makePipelineState:(MTLPixelFormat)pixelFormat sampleCount:(NSUInteger)sampleCount;
- (void)makePipelineScreenSpaceState;


@end
