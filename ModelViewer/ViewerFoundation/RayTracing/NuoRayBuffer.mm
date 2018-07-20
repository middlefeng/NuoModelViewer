//
//  NuoRayBuffer.m
//  ModelViewer
//
//  Created by middleware on 7/20/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoRayBuffer.h"
#import "NuoComputeEncoder.h"
#import "NuoRayTracingUniform.h"



const uint kRayBufferStrid = 36;



@interface NuoRayBuffer()

@property (nonatomic, weak) id<MTLDevice> device;

@end



@implementation NuoRayBuffer
{
    id<MTLComputePipelineState> _pipelineMaskOpaque;
    id<MTLComputePipelineState> _pipelineMaskTranslucent;
}



- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    self = [super init];
    
    if (self)
    {
        _device = device;
        [self setupPipeline];
    }
    
    return self;
}


- (void)setupPipeline
{
    NSError* error = nil;
    
    MTLComputePipelineDescriptor *descriptor = [[MTLComputePipelineDescriptor alloc] init];
    descriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = YES;
    
    id<MTLLibrary> library = [_device newDefaultLibrary];
    MTLFunctionConstantValues* values = [MTLFunctionConstantValues new];
    
    BOOL onTranslucent = NO;
    [values setConstantValue:&onTranslucent type:MTLDataTypeBool atIndex:0];
    descriptor.computeFunction = [library newFunctionWithName:@"ray_set_mask" constantValues:values error:&error];
    assert(error == nil);
    _pipelineMaskOpaque = [_device newComputePipelineStateWithDescriptor:descriptor options:0 reflection:nil error:&error];
    assert(error == nil);
    
    onTranslucent = YES;
    [values setConstantValue:&onTranslucent type:MTLDataTypeBool atIndex:0];
    descriptor.computeFunction = [library newFunctionWithName:@"ray_set_mask" constantValues:values error:&error];
    assert(error == nil);
    _pipelineMaskTranslucent = [_device newComputePipelineStateWithDescriptor:descriptor options:0 reflection:nil error:&error];
    assert(error == nil);
}


- (uint)rayCount
{
    const uint w = (uint)_dimension.width;
    const uint h = (uint)_dimension.height;
    
    return w * h;
}


- (void)setDimension:(CGSize)dimension
{
    _dimension = dimension;
    
    const uint rayCount = [self rayCount];
    const uint rayBufferSize = kRayBufferStrid * rayCount;
    _buffer = [_device newBufferWithLength:rayBufferSize options:MTLResourceStorageModePrivate];
}



- (void)updateRayMask:(uint32_t)rayMask withUniform:(id<MTLBuffer>)uniforms
                                  withCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    id<MTLComputePipelineState> pipeline;
    if (rayMask | kNuoRayMask_Translucent)
        pipeline = _pipelineMaskTranslucent;
    else
        pipeline = _pipelineMaskOpaque;
    
    NuoComputeEncoder* encoder = [[NuoComputeEncoder alloc] initWithCommandBuffer:commandBuffer
                                                                     withPipeline:pipeline
                                                                         withName:@"Ray Mask"];
    
    [encoder setDataSize:_dimension];
    [encoder setBuffer:uniforms offset:0 atIndex:0];
    [encoder setBuffer:_buffer offset:0 atIndex:1];
    [encoder dispatch];
}


@end
