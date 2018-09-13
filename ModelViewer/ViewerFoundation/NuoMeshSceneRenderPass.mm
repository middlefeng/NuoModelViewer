//
//  NuoMeshSceneRenderPass.m
//  ModelViewer
//
//  Created by Dong on 9/29/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoMeshSceneRenderPass.h"
#import "NuoInspectableMaster.h"

@implementation NuoMeshSceneRenderPass


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    if (self = [super init])
    {
        self.commandQueue = commandQueue;
        
        [self createShadowSamplerState];
    }
    
    return self;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat withSampleCount:(uint)sampleCount
{
    if (self = [super initWithCommandQueue:commandQueue
                           withPixelFormat:pixelFormat withSampleCount:sampleCount])
    {
        [self createShadowSamplerState];
    }
    
    return self;
}


- (void)createShadowSamplerState
{
    MTLSamplerDescriptor *samplerDesc = [MTLSamplerDescriptor new];
    samplerDesc.sAddressMode = MTLSamplerAddressModeClampToEdge;
    samplerDesc.tAddressMode = MTLSamplerAddressModeClampToEdge;
    samplerDesc.minFilter = MTLSamplerMinMagFilterLinear;
    samplerDesc.magFilter = MTLSamplerMinMagFilterLinear;
    samplerDesc.mipFilter = MTLSamplerMipFilterNotMipmapped;
    samplerDesc.compareFunction = MTLCompareFunctionGreater;
    _shadowMapSamplerState = [self.commandQueue.device newSamplerStateWithDescriptor:samplerDesc];
}


- (void)setSceneBuffersTo:(id<MTLRenderCommandEncoder>)renderPass withInFlightIndex:(unsigned int)inFlight
{
    id<NuoMeshSceneParametersProvider> provider = _paramsProvider;
    
    [renderPass setVertexBuffer:[provider transUniformBuffers][inFlight] offset:0 atIndex:1];
    [renderPass setVertexBuffer:[provider lightCastBuffers][inFlight] offset:0 atIndex:2];
    
    [renderPass setFragmentBuffer:[provider lightingUniformBuffers][inFlight] offset:0 atIndex:0];
    [renderPass setFragmentBuffer:[provider modelCharacterUnfiromBuffer] offset:0 atIndex:1];
    [renderPass setFragmentTexture:[provider shadowMap:0] atIndex:0];
    [renderPass setFragmentTexture:[provider shadowMap:1] atIndex:1];
    [renderPass setFragmentSamplerState:_shadowMapSamplerState atIndex:0];
    
    NuoInspectableMaster* inspectMaster = [NuoInspectableMaster sharedMaster];
    [inspectMaster updateTexture:[provider shadowMap:0] forName:kInspectable_Shadow];
    [inspectMaster updateTexture:[provider shadowMap:0] forName:kInspectable_ShadowTranslucent];
}


- (void)setDepthMapTo:(id<MTLRenderCommandEncoder>)renderPass
{
    id<MTLTexture> depthMap = [_paramsProvider depthMap];
    if (depthMap)
        [renderPass setFragmentTexture:depthMap atIndex:2];
}


@end
