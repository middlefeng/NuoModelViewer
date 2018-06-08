//
//  NuoRenderPipelinePass.m
//  ModelViewer
//
//  Created by middleware on 1/17/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoRenderPipelinePass.h"
#import "NuoTextureMesh.h"


@interface NuoRenderPipelinePass()

@property (nonatomic, strong) NuoTextureMesh* textureMesh;

@end


@implementation NuoRenderPipelinePass


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                     withSampleCount:(uint)sampleCount
{
    self = [super init];
    if (self)
    {
        self.commandQueue = commandQueue;
        _textureMesh = [[NuoTextureMesh alloc] initWithCommandQueue:commandQueue];
        _textureMesh.sampleCount = sampleCount;
        [_textureMesh makePipelineAndSampler:pixelFormat withBlendMode:kBlend_None];
    }
    
    return self;
}


- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    [_textureMesh setModelTexture:self.sourceTexture];
    
    id<MTLRenderCommandEncoder> renderPass = [self retainDefaultEncoder:commandBuffer];
    [_textureMesh drawMesh:renderPass indexBuffer:inFlight];
    [self releaseDefaultEncoder];
}


- (BOOL)isPipelinePass
{
    return YES;
}


@end
