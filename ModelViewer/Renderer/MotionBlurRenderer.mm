//
//  MotionBlurRenderer.m
//  ModelViewer
//
//  Created by Dong on 11/11/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "MotionBlurRenderer.h"
#import "NuoTextureAverageMesh.h"



@implementation MotionBlurRenderer
{
    id<MTLTexture> _latestSource;
    NuoTextureAccumulator* _accumulator;
    
    CGSize _drawableSize;
}



- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    if (self = [super init])
    {
        self.commandQueue = commandQueue;
        [self resetResources];
    }
    
    return self;
}



- (void)setDrawableSize:(CGSize)drawableSize
{
    [super setDrawableSize:drawableSize];
    
    if (CGSizeEqualToSize(_drawableSize, drawableSize))
        return;
    
    _drawableSize = drawableSize;
    [self resetResources];
}



- (void)resetResources
{
    _accumulator = [[NuoTextureAccumulator alloc] initWithCommandQueue:self.commandQueue];
    [_accumulator makePipelineAndSampler];
}



- (void)setSourceTexture:(id<MTLTexture>)sourceTexture
{
    if (_latestSource == sourceTexture)
        return;
    
    _latestSource = sourceTexture;
}


- (id<MTLTexture>)sourceTexture
{
    return _latestSource;
}


- (void)drawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer
{
    self.renderTarget.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);
    [_accumulator accumulateTexture:_latestSource onTarget:self.renderTarget
                  withCommandBuffer:commandBuffer];
}
    


@end
