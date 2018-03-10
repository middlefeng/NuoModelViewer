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
                                                             options:MTLResourceOptionCPUCacheModeDefault];
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
    memcpy(_clearColorBuffer.contents, &clearParam, sizeof(struct ClearFragment));
}


- (void)makeDepthStencilState:(MTLPixelFormat)pixelFormat sampleCount:(NSUInteger)sampleCount
{
    [self makePipelineAndSampler:pixelFormat withFragementShader:@"fragment_clear"
                 withSampleCount:sampleCount withBlendMode:kBlend_None];
}


- (void)makePipelineScreenSpaceState
{
    
}


@end
