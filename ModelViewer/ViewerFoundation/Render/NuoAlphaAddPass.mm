//
//  NuoRenderPipelinePass.m
//  ModelViewer
//
//  Created by middleware on 1/17/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoAlphaAddPass.h"
#import "NuoTextureMesh.h"


@interface NuoRenderPipelinePass()

@property (nonatomic, strong) NuoTextureMesh* textureMesh;

@end


@implementation NuoAlphaOverflowPass


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                     withSampleCount:(uint)sampleCount
{
    self = [super init];
    if (self)
    {
        self.commandQueue = commandQueue;
        self.textureMesh = [[NuoTextureMesh alloc] initWithCommandQueue:commandQueue];
        self.textureMesh.sampleCount = sampleCount;
        [self.textureMesh makePipelineAndSampler:pixelFormat withBlendMode:kBlend_AlphaOverflow];
    }
    
    return self;
}

@end
