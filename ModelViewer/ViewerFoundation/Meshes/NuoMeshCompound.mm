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
{
    NSUInteger _sampleCount;
}



- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.transformPoise = NuoMatrixFloat44Identity;
        self.transformTranslate = NuoMatrixFloat44Identity;
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
    
    if (!meshes.count)
        return;
    
    NuoBounds bounds = meshes[0].boundsLocal.boundingBox;
    NuoSphere sphere = meshes[0].boundsLocal.boundingSphere;
    for (size_t i = 1; i < meshes.count; ++i)
    {
        bounds = bounds.Union(meshes[i].boundsLocal.boundingBox);
        sphere = sphere.Union(meshes[i].boundsLocal.boundingSphere);
    }
    
    NuoMeshBounds meshBounds = { bounds, sphere };
    self.boundsLocal = meshBounds;
}


- (NuoMeshBounds)worldBounds:(const NuoMatrixFloat44&)transform
{
    if (!_meshes.count)
        return { NuoBounds(), NuoSphere() };
    
    NuoMatrixFloat44 transformLocal = self.transformTranslate * self.transformPoise;
    NuoMatrixFloat44 transformWorld = transform * transformLocal;
    
    NuoMeshBounds meshBounds = [_meshes[0] worldBounds:transformWorld];
    NuoBounds bounds = meshBounds.boundingBox;
    NuoSphere sphere = meshBounds.boundingSphere;
    
    for (size_t i = 1; i < _meshes.count; ++i)
    {
        NuoMeshBounds meshBoundsItem = [_meshes[i] worldBounds:transformWorld];
        
        bounds = bounds.Union(meshBoundsItem.boundingBox);
        sphere = sphere.Union(meshBoundsItem.boundingSphere);
    }
    
    return { bounds, sphere };
}


- (void)setSampleCount:(NSUInteger)sampleCount
{
    _sampleCount = sampleCount;
    
    for (NuoMesh* mesh in _meshes)
        mesh.sampleCount = sampleCount;
}


- (void)setShadowOptionPCSS:(BOOL)shadowOptionPCSS
{
    for (NuoMesh* mesh in _meshes)
        mesh.shadowOptionPCSS = shadowOptionPCSS;
}


- (void)setShadowOptionPCF:(BOOL)shadowOptionPCF
{
    for (NuoMesh* mesh in _meshes)
        mesh.shadowOptionPCF = shadowOptionPCF;
}


- (void)setShadowOptionRayTracing:(BOOL)shadowOptionRayTracing
{
    for (NuoMesh* mesh in _meshes)
        mesh.shadowOptionRayTracing = shadowOptionRayTracing;
}



- (void)makeGPUStates
{
    for (NuoMesh* mesh in _meshes)
        [mesh makeGPUStates];
}



- (VectorBuffer)worldPositionBuffer:(const NuoMatrixFloat44&)transform
{
    VectorBuffer buffer;
    
    const NuoMatrixFloat44 transformLocal = self.transformTranslate * self.transformPoise;
    const NuoMatrixFloat44 transformWorld = transform * transformLocal;
    
    for (NuoMesh* mesh in _meshes)
    {
        VectorBuffer oneBuffer = [mesh worldPositionBuffer:transformWorld];
        buffer.Union(oneBuffer);
    }
    
    return buffer;
}


- (VectorBuffer)worldNormalBuffer:(const NuoMatrixFloat44&)transform
{
    VectorBuffer buffer;
    
    const NuoMatrixFloat44 transformLocal = self.transformTranslate * self.transformPoise;
    const NuoMatrixFloat44 transformWorld = transform * transformLocal;
    
    for (NuoMesh* mesh in _meshes)
    {
        VectorBuffer oneBuffer = [mesh worldNormalBuffer:transformWorld];
        buffer.Union(oneBuffer);
    }
    
    return buffer;
}


- (std::vector<uint32_t>)maskBuffer
{
    std::vector<uint32_t> buffer;
    
    for (NuoMesh* mesh in _meshes)
    {
        NuoMeshCompound* compoundOne = (NuoMeshCompound*)mesh;
        std::vector<uint32_t> oneBuffer = [compoundOne maskBuffer];
        buffer.insert(buffer.end(), oneBuffer.begin(), oneBuffer.end());
    }
    
    return buffer;
}


- (NSUInteger)sampleCount
{
    return _sampleCount;
}



- (void)updateUniform:(NSInteger)bufferIndex withTransform:(const NuoMatrixFloat44&)transform
{
    const NuoMatrixFloat44 transformLocal = self.transformTranslate * self.transformPoise;
    const NuoMatrixFloat44 transformWorld = transform * transformLocal;
    
    for (NuoMesh* item in _meshes)
        [item updateUniform:bufferIndex withTransform:transformWorld];
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
