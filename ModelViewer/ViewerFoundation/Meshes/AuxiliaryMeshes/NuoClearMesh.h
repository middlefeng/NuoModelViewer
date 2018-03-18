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


- (void)makePipelineStateWithPixelFormat:(MTLPixelFormat)pixelFormat;
- (void)makePipelineScreenSpaceState;


@end
