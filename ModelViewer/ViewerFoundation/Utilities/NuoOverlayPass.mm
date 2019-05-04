//
//  NuoOverlayPass.m
//  ModelViewer
//
//  Created by middleware on 8/7/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoOverlayPass.h"
#import "NuoTextureMesh.h"



@implementation NuoOverlayPass
{
     NuoTextureMesh* _overlayMesh;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                     withSampleCount:(uint)sampleCount
{
    self = [super initWithCommandQueue:commandQueue
                       withPixelFormat:pixelFormat withSampleCount:1];
    
    if (self)
    {
        _overlayMesh = [[NuoTextureMesh alloc] initWithCommandQueue:commandQueue];
        _overlayMesh.sampleCount = sampleCount;
        [_overlayMesh makePipelineAndSampler:pixelFormat withBlendMode:kBlend_Alpha];
    }
    
    return self;
}



- (void)drawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer
{
    NuoRenderPassEncoder* renderPass = [self retainDefaultEncoder:commandBuffer];
    
    [super drawWithCommandBuffer:commandBuffer];
    
    if (_overlay)
    {
        [_overlayMesh setModelTexture:_overlay];
        [_overlayMesh drawMesh:renderPass];
    }
    
    [self releaseDefaultEncoder];
}



@end
