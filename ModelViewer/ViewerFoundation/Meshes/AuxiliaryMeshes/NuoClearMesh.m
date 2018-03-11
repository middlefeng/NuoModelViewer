//
//  NuoClearMesh.m
//  ModelViewer
//
//  Created by Dong on 3/10/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoClearMesh.h"


struct ClearFragment
{
    vector_float4 clearColor;
};



@implementation NuoClearMesh
{
    id<MTLBuffer> _clearColorBuffer;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super initWithCommandQueue:commandQueue];
    
    if (self)
    {
        _clearColorBuffer = [commandQueue.device newBufferWithLength:sizeof(struct ClearFragment)
                                                             options:MTLResourceStorageModePrivate];
    }
    
    return self;
}


- (void)setClearColor:(MTLClearColor)clearColor
{
    _clearColor = clearColor;
    vector_float4 color4 = { (float)clearColor.red, (float)clearColor.green,
                             (float)clearColor.blue, (float)clearColor.alpha };
    struct ClearFragment clearParam;
    clearParam.clearColor = color4;
    
    id<MTLBuffer> buffer = [self.commandQueue.device newBufferWithLength:sizeof(struct ClearFragment)
                                                                 options:MTLResourceStorageModeShared];
    memcpy(buffer.contents, &clearParam, sizeof(struct ClearFragment));
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    id<MTLBlitCommandEncoder> encoder = [commandBuffer blitCommandEncoder];
    
    [encoder copyFromBuffer:buffer sourceOffset:0
                   toBuffer:_clearColorBuffer destinationOffset:0
                       size:sizeof(struct ClearFragment)];
    
    [encoder endEncoding];
    [commandBuffer commit];
}


- (void)makePipelineState:(MTLPixelFormat)pixelFormat sampleCount:(NSUInteger)sampleCount
{
    [self makePipelineAndSampler:pixelFormat withFragementShader:@"fragment_clear"
                 withSampleCount:sampleCount withBlendMode:kBlend_None];
}


- (void)makePipelineScreenSpaceState
{
    [self makePipelineScreenSpaceStateWithVertexShader:@"texture_project"
                                    withFragemtnShader:@"fragement_clear_screen_space"];
    
    MTLDepthStencilDescriptor *depthStencilDescriptor = [MTLDepthStencilDescriptor new];
    depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionAlways;
    depthStencilDescriptor.depthWriteEnabled = NO;
    
    self.depthStencilState = [self.device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
}



- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    [renderPass setFragmentBuffer:_clearColorBuffer offset:0 atIndex:0];
    [super drawMesh:renderPass indexBuffer:index];
}


- (void)drawScreenSpace:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderPass setRenderPipelineState:self.screenSpacePipelineState];
    [renderPass setDepthStencilState:self.depthStencilState];
    
    [renderPass setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [renderPass setFragmentBuffer:_clearColorBuffer offset:0 atIndex:0];
    [renderPass drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                           indexCount:[self.indexBuffer length] / sizeof(uint32_t)
                            indexType:MTLIndexTypeUInt32
                          indexBuffer:self.indexBuffer
                    indexBufferOffset:0];
}


@end
