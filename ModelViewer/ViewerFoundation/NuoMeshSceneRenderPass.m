//
//  NuoMeshSceneRenderPass.m
//  ModelViewer
//
//  Created by Dong on 9/29/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoMeshSceneRenderPass.h"
#import "NuoShadowMapRenderer.h"



@implementation NuoMeshSceneRenderPass


- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if ((self = [super init]))
    {
        self.device = device;
        
        // create sampler state for shadow map sampling
        MTLSamplerDescriptor *samplerDesc = [MTLSamplerDescriptor new];
        samplerDesc.sAddressMode = MTLSamplerAddressModeClampToEdge;
        samplerDesc.tAddressMode = MTLSamplerAddressModeClampToEdge;
        samplerDesc.minFilter = MTLSamplerMinMagFilterLinear;
        samplerDesc.magFilter = MTLSamplerMinMagFilterLinear;
        samplerDesc.mipFilter = MTLSamplerMipFilterNotMipmapped;
        samplerDesc.compareFunction = MTLCompareFunctionGreater;
        _shadowMapSamplerState = [device newSamplerStateWithDescriptor:samplerDesc];
    }
    
    return self;
}


- (void)setSceneBuffersTo:(id<MTLRenderCommandEncoder>)renderPass withInFlightIndex:(unsigned int)inFlight
{
    id<NuoMeshSceneParametersProvider> provider = _paramsProvider;
    
    [renderPass setVertexBuffer:[provider transUniformBuffers][inFlight] offset:0 atIndex:1];
    [renderPass setVertexBuffer:[provider lightCastBuffers][inFlight] offset:0 atIndex:2];
    
    [renderPass setFragmentBuffer:[provider lightingUniformBuffers][inFlight] offset:0 atIndex:0];
    [renderPass setFragmentBuffer:[provider modelCharacterUnfiromBuffer] offset:0 atIndex:1];
    [renderPass setFragmentTexture:[provider shadowMapRenderer:0].renderTarget.targetTexture atIndex:0];
    [renderPass setFragmentTexture:[provider shadowMapRenderer:1].renderTarget.targetTexture atIndex:1];
    [renderPass setFragmentSamplerState:_shadowMapSamplerState atIndex:0];
}


@end
