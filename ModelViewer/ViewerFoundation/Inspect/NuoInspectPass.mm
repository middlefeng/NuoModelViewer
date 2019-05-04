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
                         withProcess:(NSString*)inspectMean
{
    self = [super initWithCommandQueue:commandQueue
                       withPixelFormat:pixelFormat withSampleCount:1];
    
    if (self)
    {
        _inspect = [[NuoTextureMesh alloc] initWithCommandQueue:commandQueue];
        _inspect.sampleCount = 1;
        
        if (inspectMean)
            [_inspect makePipelineAndSampler:pixelFormat withFragementShader:inspectMean withBlendMode:kBlend_Alpha];
        else
            [_inspect makePipelineAndSampler:pixelFormat withBlendMode:kBlend_Alpha];
        
        _checkboard = [[NuoCheckboardMesh alloc] initWithCommandQueue:commandQueue];
    }
    
    return self;
}



- (void)drawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer
{
    NuoRenderPassEncoder* renderPass = [self retainDefaultEncoder:commandBuffer];
    
    // not call super as the checkboard is the background
    
    [_checkboard drawMesh:renderPass];
    
    if (_inspect)
    {
        [_inspect setModelTexture:_inspectedTexture];
        [_inspect drawMesh:renderPass];
    }
    
    [self releaseDefaultEncoder];
}

@end
