//
//  NuoBackdropMesh.m
//  ModelViewer
//
//  Created by Dong on 10/21/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoBackdropMesh.h"



@implementation NuoBackdropMesh
{
    id<MTLTexture> _backdropTex;
    NSArray<id<MTLBuffer>>* _backdropTransformBuffers;
}


- (instancetype)initWithDevice:(id<MTLDevice>)device withBackdrop:(id<MTLTexture>)backdrop
{
    NSUInteger backDropW = [backdrop width];
    NSUInteger backDropH = [backdrop height];
    
    CGFloat normalizedW = 1.0;
    CGFloat normalizedH = 1.0;
    
    CGFloat aspectRatio = ((float)backDropW) / ((float)backDropH);
    if (aspectRatio > 1.0)
        normalizedW = normalizedH * aspectRatio;
    else
        normalizedH = normalizedW / aspectRatio;
    
    float vertices[] =
    {
        -normalizedW, normalizedH,  0, 1.0,    0, 0, 0, 0,
        -normalizedW, -normalizedH, 0, 1.0,    0, 1, 0, 0,
        normalizedW, -normalizedH,  0, 1.0,    1, 1, 0, 0,
        normalizedW, normalizedH,   0, 1.0,    1, 0, 0, 0,
    };
    
    uint32_t indices[] =
    {
        0, 1, 2,
        2, 3, 0
    };
    
    self = [super initWithDevice:device
              withVerticesBuffer:(void*)vertices withLength:(size_t)sizeof(vertices)
                     withIndices:(void*)indices withLength:(size_t)sizeof(indices)];
    
    if (self)
    {
        _backdropTex = backdrop;
        
        id<MTLBuffer> matrix[kInFlightBufferCount];
        for (uint i = 0; i < kInFlightBufferCount; ++i)
        {
            matrix[i] = [device newBufferWithLength:sizeof(NuoUniforms)
                                            options:MTLResourceOptionCPUCacheModeDefault];
        }
        _backdropTransformBuffers = [[NSArray alloc] initWithObjects:matrix count:kInFlightBufferCount];
    }
    
    return self;
}


@end
