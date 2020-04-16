//
//  ModelSceneParameters.m
//  ModelViewer
//
//  Created by Dong on 7/26/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "ModelSceneParameters.h"

#import "NuoTypes.h"
#import "NuoCommandBuffer.h"
#import "NuoBufferSwapChain.h"
#import "NuoLightSource.h"

#import "NuoMeshSceneRoot.h"




@implementation ModelSceneParameters
{
    NuoBufferSwapChain* _transUniformBuffers;
    NuoBufferSwapChain* _lightingUniformBuffers;
    NuoBufferSwapChain* _lightCastBuffers;
    id<MTLBuffer> _modelCharacterUnfiromBuffer;
}


- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if (self = [super init])
    {
        _transUniformBuffers = [[NuoBufferSwapChain alloc] initWithDevice:device
                                                           WithBufferSize:sizeof(NuoUniforms)
                                                              withOptions:MTLResourceStorageModeManaged
                                                            withChainSize:kInFlightBufferCount];
        
        _lightingUniformBuffers = [[NuoBufferSwapChain alloc] initWithDevice:device
                                                              WithBufferSize:sizeof(NuoLightUniforms)
                                                                 withOptions:MTLResourceStorageModeManaged
                                                               withChainSize:kInFlightBufferCount];
        
        _lightCastBuffers = [[NuoBufferSwapChain alloc] initWithDevice:device
                                                        WithBufferSize:sizeof(NuoLightVertexUniforms)
                                                           withOptions:MTLResourceStorageModeManaged
                                                         withChainSize:kInFlightBufferCount];
        
        NuoModelCharacterUniforms modelCharacter;
        modelCharacter.opacity = 1.0f;
        _modelCharacterUnfiromBuffer = [device newBufferWithLength:sizeof(NuoModelCharacterUniforms)
                                                           options:MTLResourceStorageModeManaged];
        
        memcpy([_modelCharacterUnfiromBuffer contents], &modelCharacter, sizeof(NuoModelCharacterUniforms));
        [_modelCharacterUnfiromBuffer didModifyRange:NSMakeRange(0, sizeof(NuoModelCharacterUniforms))];
        
        _cullEnabled = YES;
        _fieldOfView = (2 * M_PI) / 8;
    }
    
    return self;
}


- (void)updateUniforms:(NuoCommandBuffer*)commandBuffer
{
    const NuoMatrixFloat44& viewTrans = _viewMatrix;
    
    const CGSize& drawableSize = _drawableSize;
    const float aspect = drawableSize.width / drawableSize.height;
    
    // bounding box transform and determining the near/far
    //
    NuoBounds bounds = [_sceneRoot worldBounds:viewTrans].boundingBox;
    
    float near = -bounds._center.z() - bounds._span.z() / 2.0 + 0.01;
    float far = near + bounds._span.z() + 0.02;
    near = std::max<float>(0.001, near);
    far = std::max<float>(near + 0.001, far);
    
    _projection = NuoMatrixPerspective(aspect, _fieldOfView, near, far);
    
    NuoUniforms uniforms;
    uniforms.viewMatrix = viewTrans._m;
    uniforms.viewMatrixInverse = viewTrans.Inverse()._m;
    uniforms.viewProjectionMatrix = (_projection * viewTrans)._m;
    
    [_transUniformBuffers updateBufferWithInFlight:commandBuffer withContent:&uniforms];
    
    NuoLightUniforms lighting;
    lighting.ambient = _ambient._vector;
    for (unsigned int i = 0; i < 4; ++i)
    {
        const NuoVectorFloat4 lightVector(_lights[i].lightDirection * NuoVectorFloat4(0, 0, 1, 0));
        lighting.lightParams[i].direction = lightVector._vector;
        lighting.lightParams[i].irradiance = _lights[i].lightingIrradiance;
        lighting.lightParams[i].specular = _lights[i].lightingSpecular;
        
        if (i < 2)
        {
            lighting.shadowParams[i].soften = _lights[i].shadowSoften;
            lighting.shadowParams[i].bias = _lights[i].shadowBias;
            lighting.shadowParams[i].occluderRadius = _lights[i].shadowOccluderRadius;
        }
    }
    
    [_lightingUniformBuffers updateBufferWithInFlight:commandBuffer withContent:&lighting];
}


- (void)updateLightCastWithInFlight:(id<NuoRenderInFlight>)inFlight
                        withContent:(NuoLightVertexUniforms*)content
{
    [_lightCastBuffers updateBufferWithInFlight:inFlight withContent:content];
}


#pragma mark -- Protocol Functions

- (BOOL)cullEnabled
{ 
    return _cullEnabled;
}

- (id<MTLTexture>)depthMap
{
    return [_shadowMap depthMap];
}

- (NuoBufferSwapChain*)lightCastBuffers
{
    return _lightCastBuffers;
}

- (NuoBufferSwapChain*)lightingUniformBuffers
{
    return _lightingUniformBuffers;
}

- (id<MTLBuffer>)modelCharacterUnfiromBuffer
{
    return _modelCharacterUnfiromBuffer;
}

- (id<MTLTexture>)shadowMap:(uint)index withMask:(NuoSceneMask)mask
{
    return [_shadowMap shadowMap:index withMask:mask];
}

- (NuoBufferSwapChain*)transUniformBuffers
{
    return _transUniformBuffers;
}

@end
