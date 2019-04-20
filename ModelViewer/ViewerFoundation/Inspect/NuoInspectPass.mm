//
//  NuoInspectPass.m
//  ModelViewer
//
//  Created by middleware on 9/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoInspectPass.h"
#import "NuoTextureMesh.h"
#import "NuoCheckerboardMesh.h"



@implementation NuoInspectPass
{
    NuoTextureMesh* _inspect;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                         withProcess:(NSString*)inspectMean
{
    self = [super initWithCommandQueue:commandQueue
                       withPixelFormat:pixelFormat withSampleCount:1];
    
    _inspect = nil;
    
    if (self && inspectMean)
    {
        _inspect = [[NuoTextureMesh alloc] initWithCommandQueue:commandQueue];
        _inspect.sampleCount = 1;
        [_inspect makePipelineAndSampler:pixelFormat withFragementShader:inspectMean withBlendMode:kBlend_Alpha];
    }
    
    return self;
}



- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    if (_inspect)
    {
        _inspect.modelTexture = self.sourceTexture;
        self.sourceTexture = nil;
    }
    
    id<MTLRenderCommandEncoder> renderPass = [self retainDefaultEncoder:commandBuffer];
    
    // super for background checker
    
    [super drawWithCommandBuffer:commandBuffer withInFlightIndex:inFlight];
    
    if (_inspect)
    {
        [_inspect drawMesh:renderPass indexBuffer:inFlight];
    }
    
    [self releaseDefaultEncoder];
}

@end
