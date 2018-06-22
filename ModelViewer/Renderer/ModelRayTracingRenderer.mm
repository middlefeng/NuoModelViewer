//
//  ModelRayTracingRenderer.m
//  ModelViewer
//
//  Created by middleware on 6/22/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "ModelRayTracingRenderer.h"


@implementation ModelRayTracingRenderer
{
    id<MTLComputePipelineState> _shadePipeline;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                     withSampleCount:(uint)sampleCount
{
    self = [super initWithCommandQueue:commandQueue
                       withPixelFormat:pixelFormat withSampleCount:1];
    if (self)
    {
        NSError* error = nil;
        MTLFunctionConstantValues* values = [MTLFunctionConstantValues new];
        id<MTLLibrary> library = [commandQueue.device newDefaultLibrary];
        id<MTLFunction> shadeFunction = [library newFunctionWithName:@"shade_function" constantValues:values error:&error];
        assert(error == nil);
        
        _shadePipeline = [commandQueue.device newComputePipelineStateWithFunction:shadeFunction error:&error];
        assert(error == nil);
    }
    
    return self;
}


- (void)runRayTraceShade:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    if ([self rayIntersect:commandBuffer withInFlightIndex:inFlight])
    {
        [self runRayTraceCompute:_shadePipeline withCommandBuffer:commandBuffer withInFlightIndex:inFlight];
    }
}


@end
