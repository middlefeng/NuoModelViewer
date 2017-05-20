//
//  NuoMeshCompound.m
//  ModelViewer
//
//  Created by middleware on 5/18/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoMeshCompound.h"


@implementation NuoMeshCompound



- (void)setMeshes:(NSArray<NuoMesh *> *)meshes
{
    _meshes = meshes;
    
    NuoMeshBox* bounding = meshes[0].boundingBox;
    for (size_t i = 1; i < meshes.count; ++i)
        bounding = [bounding unionWith:meshes[i].boundingBox];
    
    self.boundingBox = bounding;
    
    float modelSpan = fmax(bounding.spanZ, bounding.spanX);
    modelSpan = fmax(bounding.spanY, modelSpan);
    _maxSpan = 1.41 * modelSpan;
}



- (void)updateUniform:(NSInteger)bufferIndex withTransform:(matrix_float4x4)transform
{
    for (NuoMesh* item in _meshes)
        [item updateUniform:bufferIndex withTransform:transform];
}


- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)bufferIndex
{
    NSArray* cullModes = _cullEnabled ?
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
