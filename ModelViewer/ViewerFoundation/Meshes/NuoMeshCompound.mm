//
//  NuoMeshCompound.m
//  ModelViewer
//
//  Created by middleware on 5/18/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoMeshCompound.h"
#import "NuoMeshBounds.h"


@implementation NuoMeshCompound



- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.transformPoise = matrix_identity_float4x4;
        self.transformTranslate = matrix_identity_float4x4;
        self.enabled = YES;
    }
    
    return self;
}


- (instancetype)cloneForMode:(NuoMeshModeShaderParameter)mode
{
    NuoMeshCompound* meshCompound = [NuoMeshCompound new];
    NSMutableArray<NuoMesh*>* newMeshes = [NSMutableArray new];
    for (NuoMesh* mesh in _meshes)
    {
        NuoMesh* newMesh = [mesh cloneForMode:mode];
        [newMeshes addObject:newMesh];
    }
    
    [meshCompound setMeshes:newMeshes];
    return meshCompound;
}


- (void)setMeshes:(NSArray<NuoMesh*>*)meshes
{
    _meshes = meshes;
    
    NuoBounds bounds = *((NuoBounds*)[meshes[0].bounds boundingBox]);
    for (size_t i = 1; i < meshes.count; ++i)
        bounds = bounds.Union(*((NuoBounds*)[meshes[i].bounds boundingBox]));
    
    NuoMeshBounds* meshBounds = [NuoMeshBounds new];
    *((NuoBounds*)[meshBounds boundingBox]) = bounds;
    
    self.boundsLocal = meshBounds;
}



- (void)updateUniform:(NSInteger)bufferIndex withTransform:(matrix_float4x4)transform
{
    matrix_float4x4 transformLocal = matrix_multiply(self.transformTranslate, self.transformPoise);
    transform = matrix_multiply(transform, transformLocal);
    
    for (NuoMesh* item in _meshes)
        [item updateUniform:bufferIndex withTransform:transform];
}


- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)bufferIndex
{
    NSArray* cullModes = self.cullEnabled ?
                            @[@(MTLCullModeBack), @(MTLCullModeNone)] :
                            @[@(MTLCullModeNone), @(MTLCullModeBack)];
    NSUInteger cullMode = [cullModes[0] unsignedLongValue];
    [renderPass setCullMode:(MTLCullMode)cullMode];
    
    for (uint8 renderPassStep = 0; renderPassStep < 4; ++renderPassStep)
    {
        // reverse the cull mode in pass 1 and 3
        //
        if (renderPassStep == 1 || renderPassStep == 3)
        {
            NSUInteger cullMode = [cullModes[renderPassStep % 3] unsignedLongValue];
            [renderPass setCullMode:(MTLCullMode)cullMode];
        }
        
        for (NuoMesh* mesh in _meshes)
        {
            if (((renderPassStep == 0) && ![mesh hasTransparency] && ![mesh reverseCommonCullMode]) /* 1/2 pass for opaque */ ||
                ((renderPassStep == 1) && ![mesh hasTransparency] && [mesh reverseCommonCullMode])                              ||
                ((renderPassStep == 2) && [mesh hasTransparency] && [mesh reverseCommonCullMode])  /* 3/4 pass for transparent */ ||
                ((renderPassStep == 3) && [mesh hasTransparency] && ![mesh reverseCommonCullMode]))
                if ([mesh enabled])
                    [mesh drawMesh:renderPass indexBuffer:bufferIndex];
        }
    }
}


- (void)drawScreenSpace:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)bufferIndex
{
    NSArray* cullModes = self.cullEnabled ?
    @[@(MTLCullModeBack), @(MTLCullModeNone)] :
    @[@(MTLCullModeNone), @(MTLCullModeBack)];
    NSUInteger cullMode = [cullModes[0] unsignedLongValue];
    [renderPass setCullMode:(MTLCullMode)cullMode];
    
    for (uint8 renderPassStep = 0; renderPassStep < 4; ++renderPassStep)
    {
        // reverse the cull mode in pass 1 and 3
        //
        if (renderPassStep == 1 || renderPassStep == 3)
        {
            NSUInteger cullMode = [cullModes[renderPassStep % 3] unsignedLongValue];
            [renderPass setCullMode:(MTLCullMode)cullMode];
        }
        
        for (NuoMesh* mesh in _meshes)
        {
            if (((renderPassStep == 0) && ![mesh hasTransparency] && ![mesh reverseCommonCullMode]) /* 1/2 pass for opaque */ ||
                ((renderPassStep == 1) && ![mesh hasTransparency] && [mesh reverseCommonCullMode])                              ||
                ((renderPassStep == 2) && [mesh hasTransparency] && [mesh reverseCommonCullMode])  /* 3/4 pass for transparent */ ||
                ((renderPassStep == 3) && [mesh hasTransparency] && ![mesh reverseCommonCullMode]))
                if ([mesh enabled])
                    [mesh drawScreenSpace:renderPass indexBuffer:bufferIndex];
        }
    }
}



- (void)drawShadow:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)bufferIndex
{
    [renderPass setCullMode:MTLCullModeNone];
    
    for (NuoMesh* mesh in _meshes)
    {
        if (![mesh hasTransparency] && [mesh enabled])
            [mesh drawShadow:renderPass indexBuffer:bufferIndex];
    }
}


@end
