//
//  NuoRenderPipelinePass.m
//  ModelViewer
//
//  Created by middleware on 1/17/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoRenderPipelinePass.h"
#import "NuoTextureMesh.h"
#import "NuoCheckerboardMesh.h"


@interface NuoRenderPipelinePass()

@property (nonatomic, strong) NuoTextureMesh* textureMesh;
@property (nonatomic, strong) NuoCheckerboardMesh* checkerboardMesh;

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
    if (!_showCheckerboard && !_sourceTexture)
        return;
    
    id<MTLRenderCommandEncoder> renderPass = [self retainDefaultEncoder:commandBuffer];
    
    if (_showCheckerboard)
        [_checkerboardMesh drawMesh:renderPass indexBuffer:inFlight];
    
    if (_sourceTexture)
    {
        [_textureMesh setModelTexture:_sourceTexture];
        [_textureMesh drawMesh:renderPass indexBuffer:inFlight];
    }
    
    [self releaseDefaultEncoder];
}


- (void)setShowCheckerboard:(BOOL)showCheckerboard
{
    _showCheckerboard = showCheckerboard;
    
    if (!_checkerboardMesh)
        _checkerboardMesh = [[NuoCheckerboardMesh alloc] initWithCommandQueue:self.commandQueue];
    
    [_textureMesh makePipelineAndSampler:_textureMesh.pixelFormat
                           withBlendMode:_showCheckerboard ? kBlend_Alpha : kBlend_None];
}


- (BOOL)isPipelinePass
{
    return YES;
}


@end
