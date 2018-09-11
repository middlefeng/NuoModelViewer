//
//  NuoInspectPass.m
//  ModelViewer
//
//  Created by middleware on 9/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoInspectPass.h"
#import "NuoTextureMesh.h"
#import "NuoCheckboardMesh.h"



@implementation NuoInspectPass
{
    NuoCheckboardMesh* _checkboard;
    NuoTextureMesh* _inspect;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                     withSampleCount:(uint)sampleCount
{
    self = [super initWithCommandQueue:commandQueue
                       withPixelFormat:pixelFormat withSampleCount:1];
    
    if (self)
    {
        _inspect = [[NuoTextureMesh alloc] initWithCommandQueue:commandQueue];
        _inspect.sampleCount = sampleCount;
        [_inspect makePipelineAndSampler:pixelFormat withBlendMode:kBlend_Alpha];
        
        _checkboard = [[NuoCheckboardMesh alloc] initWithCommandQueue:commandQueue];
    }
    
    return self;
}



- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    id<MTLRenderCommandEncoder> renderPass = [self retainDefaultEncoder:commandBuffer];
    
    // not call super as the checkboard is the background
    
    [_checkboard drawMesh:renderPass indexBuffer:inFlight];
    
    if (_inspect)
    {
        [_inspect setModelTexture:_inspectedTexture];
        [_inspect drawMesh:renderPass indexBuffer:inFlight];
    }
    
    [self releaseDefaultEncoder];
}

@end
