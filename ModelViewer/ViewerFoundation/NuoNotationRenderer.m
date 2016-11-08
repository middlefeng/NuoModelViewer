//
//  NuoNotationRenderer.m
//  ModelViewer
//
//  Created by middleware on 11/6/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "NuoNotationRenderer.h"
#import "NuoTextureMesh.h"


@interface NuoNotationRenderer()

@property (nonatomic, strong) NuoTextureMesh* textureMesh;

@end




@implementation NuoNotationRenderer


- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    self = [super init];
    if (self)
    {
        self.device = device;
        _textureMesh = [[NuoTextureMesh alloc] initWithDevice:device];
    }
    
    return self;
}


- (void)drawToTarget:(NuoRenderTarget *)target withCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    [_textureMesh setModelTexture:_sourceTexture];
    [_textureMesh makePipelineAndSampler];
    
    MTLRenderPassDescriptor *renderPassDesc = [target currentRenderPassDescriptor];
    id<MTLRenderCommandEncoder> renderPass = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
    [_textureMesh drawMesh:renderPass];
    
    [renderPass endEncoding];
}


@end
