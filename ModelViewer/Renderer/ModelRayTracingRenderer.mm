//
//  ModelRayTracingRenderer.m
//  ModelViewer
//
//  Created by middleware on 6/22/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "ModelRayTracingRenderer.h"
#import "NuoRayTracingUniform.h"

// headers to pass light source info
//
#import "NuoMeshSceneRenderPass.h"
#import "NuoShadowMapRenderer.h"


@implementation ModelRayTracingRenderer
{
    id<MTLComputePipelineState> _shadePipeline;
    
    NSArray<id<MTLBuffer>>* _rayTraceUniform;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                     withSampleCount:(uint)sampleCount
{
    self = [super initWithCommandQueue:commandQueue
                       withPixelFormat:pixelFormat withSampleCount:1];
    if (self)
    {
        NSError* error = nil;
        MTLFunctionConstantValues* values = [MTLFunctionConstantValues new];
        id<MTLLibrary> library = [commandQueue.device newDefaultLibrary];
        id<MTLFunction> shadeFunction = [library newFunctionWithName:@"light_direction_visualize" constantValues:values error:&error];
        assert(error == nil);
        
        _shadePipeline = [commandQueue.device newComputePipelineStateWithFunction:shadeFunction error:&error];
        assert(error == nil);
        
        id<MTLBuffer> buffers[kInFlightBufferCount];
        for (uint i = 0; i < kInFlightBufferCount; ++i)
        {
            buffers[i] = [commandQueue.device newBufferWithLength:sizeof(NuoRayTracingUniforms)
                                                          options:MTLResourceStorageModeManaged];
        }
        _rayTraceUniform = [[NSArray alloc] initWithObjects:buffers count:kInFlightBufferCount];
    }
    
    return self;
}


- (void)updateUniforms:(uint32_t)index
{
    NuoRayTracingUniforms uniforms;
    
    for (uint i = 0; i < 2; ++i)
    {
        const NuoMatrixFloat44& lightDriection = [[_paramsProvider shadowMapRenderer:i] lightDirectionMatrix];
        uniforms.lightSources[i] = lightDriection._m;
        
        
    }
    
    vector_float4 lightVec =  { 0.0, 0.0, 1.0, 0.0 };
    lightVec = matrix_multiply(uniforms.lightSources[0], lightVec);
    
    printf("Vector, %f, %f, %f.\n", lightVec.x, lightVec.y, lightVec.z);
    
    memcpy(_rayTraceUniform[index].contents, &uniforms, sizeof(NuoRayTracingUniforms));
    [_rayTraceUniform[index] didModifyRange:NSMakeRange(0, sizeof(NuoRayTracingUniforms))];
}


- (void)runRayTraceShade:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    [self updateUniforms:inFlight];
    
    if ([self rayIntersect:commandBuffer withInFlightIndex:inFlight])
    {
        [self runRayTraceCompute:_shadePipeline withCommandBuffer:commandBuffer
                   withParameter:@[_rayTraceUniform[inFlight]] withInFlightIndex:inFlight];
    }
}




@end
