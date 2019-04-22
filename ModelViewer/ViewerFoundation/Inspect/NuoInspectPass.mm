//
//  NuoInspectPass.m
//  ModelViewer
//
//  Created by middleware on 9/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoInspectPass.h"
#import "NuoTextureMesh.h"



@implementation NuoInspectPass
{
    NuoTextureMesh* _inspect;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                         withProcess:(NSString*)inspectMean
{
    self = [super initWithCommandQueue:commandQueue];
    
    if (self)
    {
        _inspect = [[NuoTextureMesh alloc] initWithCommandQueue:commandQueue];
        _inspect.sampleCount = 1;
        
        if (inspectMean)
            [_inspect makePipelineAndSampler:pixelFormat withFragementShader:inspectMean withBlendMode:kBlend_Alpha];
        else
            [_inspect makePipelineAndSampler:pixelFormat withBlendMode:kBlend_Alpha];
    }
    
    return self;
}



- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    id<MTLRenderCommandEncoder> renderPass = [self retainDefaultEncoder:commandBuffer];
    
    // super for background checker
    
    [super drawWithCommandBuffer:commandBuffer withInFlightIndex:inFlight];
    
    [_inspect setModelTexture:self.sourceTexture];
    [_inspect drawMesh:renderPass indexBuffer:inFlight];
    
    [self releaseDefaultEncoder];
}

@end
