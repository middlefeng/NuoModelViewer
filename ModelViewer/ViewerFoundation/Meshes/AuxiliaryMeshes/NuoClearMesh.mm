//
//  NuoClearMesh.m
//  ModelViewer
//
//  Created by Dong on 3/10/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoClearMesh.h"
#import "NuoMesh_Extension.h"


struct ClearFragment
{
    vector4 clearColor;
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
    NuoVectorFloat4 color4(clearColor.red, clearColor.green,
                           clearColor.blue, clearColor.alpha);
    struct ClearFragment clearParam;
    clearParam.clearColor = color4._vector;
    
    [NuoMesh updatePrivateBuffer:_clearColorBuffer withCommandQueue:self.commandQueue
                        withData:&clearParam withSize:sizeof(struct ClearFragment)];
}


- (void)makePipelineStateWithPixelFormat:(MTLPixelFormat)pixelFormat
{
    [self makePipelineAndSampler:pixelFormat withFragementShader:@"fragment_clear"
                   withBlendMode:kBlend_None];
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



- (void)drawMesh:(NuoRenderPassEncoder*)renderPass
{
    [renderPass pushParameterState:@"Clear"];
    
    [renderPass setFragmentBuffer:_clearColorBuffer offset:0 atIndex:0];
    [super drawMesh:renderPass];
    
    [renderPass popParameterState];
}


- (void)drawScreenSpace:(NuoRenderPassEncoder*)renderPass
{
    [renderPass pushParameterState:@"Clear Screen Space"];
    
    [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderPass setRenderPipelineState:self.screenSpacePipelineState];
    [renderPass setDepthStencilState:self.depthStencilState];
    
    [renderPass setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [renderPass setFragmentBuffer:_clearColorBuffer offset:0 atIndex:0];
    [renderPass drawWithIndices:self.indexBuffer];
    
    [renderPass popParameterState];
}


@end
