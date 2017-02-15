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
{
    self = [super init];
    if (self)
    {
        self.device = device;
        _textureMesh = [[NuoTextureMesh alloc] initWithDevice:device];
        [_textureMesh makePipelineAndSampler];
    }
    
    return self;
}


- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    [_textureMesh setModelTexture:self.sourceTexture];
    
    MTLRenderPassDescriptor *renderPassDesc = [self.renderTarget currentRenderPassDescriptor];
    id<MTLRenderCommandEncoder> renderPass = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
    [_textureMesh drawMesh:renderPass indexBuffer:inFlight];
    self.lastRenderPass = renderPass;
}


@end
