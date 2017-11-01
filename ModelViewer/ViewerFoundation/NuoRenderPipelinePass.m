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


- (instancetype)initWithDevice:(id<MTLDevice>)device
               withPixelFormat:(MTLPixelFormat)pixelFormat
               withSampleCount:(uint)sampleCount
{
    self = [super init];
    if (self)
    {
        self.device = device;
        _textureMesh = [[NuoTextureMesh alloc] initWithDevice:device];
        [_textureMesh makePipelineAndSampler:pixelFormat withSampleCount:sampleCount];
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
