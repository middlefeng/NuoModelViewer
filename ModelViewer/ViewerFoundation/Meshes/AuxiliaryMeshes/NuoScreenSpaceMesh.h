//
//  NuoScreenSpaceMesh.h
//  ModelViewer
//
//  Created by Dong on 9/30/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoMesh.h"




@interface NuoScreenSpaceMesh : NuoMesh


@property (nonatomic, weak) id<MTLSamplerState> samplerState;


- (instancetype)initWithDevice:(id<MTLDevice>)device;


- (void)makePipelineAndSampler:(MTLPixelFormat)pixelFormat
           withFragementShader:(NSString*)shaderName
               withSampleCount:(NSUInteger)sampleCount
                     withAlpha:(BOOL)alpha;


@end
