//
//  NuoRayTracingRenderer.m
//  ModelViewer
//
//  Created by middleware on 6/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoRayTracingRenderer.h"
#import "NuoRayAccelerateStructure.h"

#import <MetalPerformanceShaders/MetalPerformanceShaders.h>



@implementation NuoRayTracingRenderer
{
    NuoRenderPassTarget* _renderTarget;
}



- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                     withSampleCount:(uint)sampleCount
{
    self = [super initWithCommandQueue:commandQueue
                       withPixelFormat:pixelFormat withSampleCount:1];
    
    if (self)
    {
        _renderTarget = [[NuoRenderPassTarget alloc] initWithCommandQueue:commandQueue
                                                          withPixelFormat:MTLPixelFormatRGBA32Float
                                                          withSampleCount:1];
        
        _renderTarget.computeTarget = YES;
        _renderTarget.manageTargetTexture = YES;
        _renderTarget.sharedTargetTexture = NO;
        _renderTarget.name = @"Ray Emit";
    }
    
    return self;
}



- (void)setDrawableSize:(CGSize)drawableSize
{
    [super setDrawableSize:drawableSize];
    [_renderTarget setDrawableSize:drawableSize];
}



- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    //id<MTLRenderCommandEncoder> renderPass = [self retainDefaultEncoder:commandBuffer];
    
    [_rayStructure rayTrace:commandBuffer inFlight:inFlight toTarget:_renderTarget];
    
    [self setSourceTexture:_renderTarget.targetTexture];
    [super drawWithCommandBuffer:commandBuffer withInFlightIndex:inFlight];
    
    //[self releaseDefaultEncoder];
}



@end
