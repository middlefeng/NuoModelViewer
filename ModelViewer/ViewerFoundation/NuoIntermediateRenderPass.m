//
//  NuoNotationRenderer.m
//  ModelViewer
//
//  Created by middleware on 11/6/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "NuoIntermediateRenderPass.h"
#import "NuoTextureMesh.h"


@interface NuoIntermediateRenderPass()

@property (nonatomic, strong) NuoTextureMesh* textureMesh;

@end




@implementation NuoIntermediateRenderPass


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
    
    id<MTLRenderCommandEncoder> renderPass = [self currentRenderPass:commandBuffer];
    [_textureMesh drawMesh:renderPass indexBuffer:inFlight];
}


@end
