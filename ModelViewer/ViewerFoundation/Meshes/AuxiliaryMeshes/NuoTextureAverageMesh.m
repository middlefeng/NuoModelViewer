//
//  NuoTextureAverageMesh.m
//  ModelViewer
//
//  Created by Dong on 11/11/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoTextureAverageMesh.h"



@implementation NuoTextureAverageMesh
{
    NSMutableArray<id<MTLTexture>>* _textures;
    NSArray<id<MTLBuffer>>* _texCountBuffer;
}


- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    self = [super initWithDevice:device];
    
    if (self)
    {
        id<MTLBuffer> buffers[kInFlightBufferCount];
        for (size_t i = 0; i < kInFlightBufferCount; ++i)
            buffers[i] = [device newBufferWithLength:sizeof(int)
                                             options:MTLResourceStorageModeManaged];
        _texCountBuffer = [[NSArray alloc] initWithObjects:buffers count:kInFlightBufferCount];
        
        _textures = [NSMutableArray new];
    }
    
    return self;
}



- (void)appendTexture:(id<MTLTexture>)texture
{
    [_textures addObject:texture];
}



- (void)updateUniform:(NSInteger)bufferIndex withTransform:(matrix_float4x4)transform
{
    int textureCount = (int)_textures.count;
    memcpy(_texCountBuffer[bufferIndex].contents, &textureCount, sizeof(int));
}



- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    [self updateUniform:index withTransform:matrix_identity_float4x4];
    
    for (id<MTLTexture> texture in _textures)
    {
        [renderPass setFragmentTexture:texture atIndex:0];
        [renderPass setFragmentBuffer:_texCountBuffer[index] offset:0 atIndex:0];
        [super drawMesh:renderPass indexBuffer:index];
    }
}



@end
