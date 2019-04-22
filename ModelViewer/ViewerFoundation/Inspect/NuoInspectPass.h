//
//  NuoInspectPass.h
//  ModelViewer
//
//  Created by middleware on 9/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoRenderPipelinePass.h"
#import "NuoUniforms.h"


@class NuoTextureMesh;


@interface NuoInspectPass : NuoRenderPipelinePass


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                         withProcess:(NSString*)inspectMean
                           forBuffer:(BOOL)forBuffer;

- (void)updateBuffer:(id<MTLBuffer>)buffer withRange:(const NuoRangeUniform&)range;


@end


