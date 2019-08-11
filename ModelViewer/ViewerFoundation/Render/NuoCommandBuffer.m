//
//  NuoCommandBuffer.m
//  ModelViewer
//
//  Created by Dong on 5/3/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "NuoCommandBuffer.h"

#import "NuoComputeEncoder.h"
#import "NuoRenderPassEncoder.h"



@interface NuoComputeEncoder()

- (instancetype)initWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                             withName:(NSString*)name;


@end


@interface NuoRenderPassEncoder()

- (instancetype)initWithEncoder:(id<MTLRenderCommandEncoder>)encoder
              withInFlightIndex:(uint)inFlight;


@end




@implementation NuoCommandBuffer
{
    id<MTLCommandBuffer> _commandBuffer;
    uint _inFlight;
}



- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                        withInFlight:(uint)inFlight
{
    self = [super init];
    
    if (self)
    {
        _commandBuffer = [commandQueue commandBuffer];
        _inFlight = inFlight;
    }
    
    return self;
}


- (uint)inFlight
{
    return _inFlight;
}


- (id<MTLCommandQueue>)commandQueue
{
    return _commandBuffer.commandQueue;
}


- (id<MTLCommandBuffer>)commandBuffer
{
    return _commandBuffer;
}


- (void)synchronizeResource:(id<MTLResource>)resource
{
    id<MTLBlitCommandEncoder> encoder = [_commandBuffer blitCommandEncoder];
    [encoder synchronizeResource:resource];
    [encoder endEncoding];
}


- (void)copyFromTexture:(id<MTLTexture>)src toTexture:(id<MTLTexture>)dst
{
    MTLOrigin origin = {0, 0, 0};
    MTLSize size = {src.width, src.height, 1};
    id<MTLBlitCommandEncoder> encoder = [_commandBuffer blitCommandEncoder];
    [encoder copyFromTexture:src sourceSlice:0 sourceLevel:0 sourceOrigin:origin sourceSize:size
                   toTexture:dst destinationSlice:0 destinationLevel:0 destinationOrigin:origin];
    
    [encoder endEncoding];
}


- (void)copyFromBuffer:(id<MTLBuffer>)src toBuffer:(id<MTLBuffer>)dst
{
    id<MTLBlitCommandEncoder> encoder = [_commandBuffer blitCommandEncoder];
    [encoder copyFromBuffer:src sourceOffset:0 toBuffer:dst destinationOffset:0 size:src.length];
    [encoder endEncoding];
}


- (NuoRenderPassEncoder*)renderCommandEncoderWithDescriptor:(MTLRenderPassDescriptor*)descriptor
{
    id<MTLRenderCommandEncoder> encoder = [_commandBuffer renderCommandEncoderWithDescriptor:descriptor];
    return [[NuoRenderPassEncoder alloc] initWithEncoder:encoder withInFlightIndex:_inFlight];
}


- (void)addCompletedHandler:(MTLCommandBufferHandler)block
{
    [_commandBuffer addCompletedHandler:block];
}



- (void)commit
{
    [_commandBuffer commit];
}


- (void)presentDrawable:(id<MTLDrawable>)drawable
{
    [_commandBuffer presentDrawable:drawable];
}


- (NuoComputeEncoder*)computeEncoderWithName:(NSString*)name
{
    return [[NuoComputeEncoder alloc] initWithCommandBuffer:_commandBuffer
                                                   withName:name];
}


@end
