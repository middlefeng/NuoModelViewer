#import "ModelViewerRenderer.h"
#import "ModelUniforms.h"

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#import <simd/simd.h>

#include "NuoTypes.h"
#include "NuoMesh.h"
#include "NuoRenderPassTarget.h"
#include "NuoMathUtilities.h"
#include "NuoModelBase.h"
#include "NuoModelLoader.h"

#include "NuoTextureMesh.h"

@interface ModelRenderer ()

@property (strong) NSArray<NuoMesh*>* mesh;

@property (strong) NSArray<id<MTLBuffer>>* uniformBuffers;
@property (strong) NSArray<id<MTLBuffer>>* lightingBuffers;
@property (assign) NSInteger bufferIndex;

@property (strong) NuoModelLoader* modelLoader;

@property (nonatomic, assign) matrix_float4x4 rotationMatrix;

@end

@implementation ModelRenderer

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if ((self = [super init]))
    {
        self.device = device;
        
        [self makeResources];
        
        _modelOptions = [NuoMeshOption new];
        _rotationMatrix = matrix_identity_float4x4;
        
        _cullEnabled = YES;
        _fieldOfView = (2 * M_PI) / 8;
    }

    return self;
}


- (void)loadMesh:(NSString*)path
{
    _modelLoader = [NuoModelLoader new];
    [_modelLoader loadModel:path];
    
    _mesh = [_modelLoader createMeshsWithOptions:_modelOptions
                                      withDevice:self.device];
}


- (void)setModelOptions:(NuoMeshOption *)modelOptions
{
    _modelOptions = modelOptions;
    
    if (_modelLoader)
    {
        _mesh = [_modelLoader createMeshsWithOptions:_modelOptions
                                          withDevice:self.device];
    }
}


- (void)makeResources
{
    id<MTLBuffer> buffers[InFlightBufferCount];
    id<MTLBuffer> lightingBuffers[InFlightBufferCount];
    
    for (size_t i = 0; i < InFlightBufferCount; ++i)
    {
        id<MTLBuffer> uniformBuffer = [self.device newBufferWithLength:sizeof(ModelUniforms)
                                                               options:MTLResourceOptionCPUCacheModeDefault];
        buffers[i] = uniformBuffer;
        
        NSString* label = [NSString stringWithFormat:@"Uniforms %lu", i];
        [uniformBuffer setLabel:label];
        
        id<MTLBuffer> lightingBuffer = [self.device newBufferWithLength:sizeof(LightingUniforms)
                                                                options:MTLResourceOptionCPUCacheModeDefault];
        lightingBuffers[i] = lightingBuffer;
    }
    
    _uniformBuffers = [[NSArray alloc] initWithObjects:buffers[0], buffers[1], buffers[2], nil];
    _lightingBuffers = [[NSArray alloc] initWithObjects:lightingBuffers[0], lightingBuffers[1], lightingBuffers[2], nil];
}

- (void)updateUniformsForView
{
    {
        float scaleFactor = 1;
        const vector_float3 xAxis = { 1, 0, 0 };
        const vector_float3 yAxis = { 0, 1, 0 };
        const matrix_float4x4 xRot = matrix_float4x4_rotation(xAxis, self.rotationXDelta);
        const matrix_float4x4 yRot = matrix_float4x4_rotation(yAxis, self.rotationYDelta);
        const matrix_float4x4 scale = matrix_float4x4_uniform_scale(scaleFactor);
        const matrix_float4x4 rotationMatrix = matrix_multiply(matrix_multiply(xRot, yRot), scale);
        self.rotationMatrix = matrix_multiply(rotationMatrix, self.rotationMatrix);
    }
    
    _rotationXDelta = 0;
    _rotationYDelta = 0;
    
    NuoMeshBox* bounding = _mesh[0].boundingBox;
    for (size_t i = 1; i < _mesh.count; ++i)
        bounding = [bounding unionWith:_mesh[i].boundingBox];
    
    const vector_float3 translationToCenter =
    {
        - bounding.centerX,
        - bounding.centerY,
        - bounding.centerZ
    };
    const matrix_float4x4 modelCenteringMatrix = matrix_float4x4_translation(translationToCenter);
    const matrix_float4x4 modelMatrix = matrix_multiply(self.rotationMatrix, modelCenteringMatrix);
    
    float modelSpan = std::max(bounding.spanZ, bounding.spanX);
    modelSpan = std::max(bounding.spanY, modelSpan);
    
    const float modelNearest = - modelSpan / 2.0;
    const float bilateralFactor = 1 / 750.0f;
    const float cameraDefaultDistance = (modelNearest - modelSpan);
    const float cameraDistance = cameraDefaultDistance + _zoom * modelSpan / 20.0f;
    
    const float doTransX = _transX * cameraDistance * bilateralFactor;
    const float doTransY = _transY * cameraDistance * bilateralFactor;
    
    const vector_float3 cameraTranslation =
    {
        doTransX, doTransY,
        cameraDistance
    };

    const matrix_float4x4 viewMatrix = matrix_float4x4_translation(cameraTranslation);
    
    const CGSize drawableSize = self.renderTarget.drawableSize;
    const float aspect = drawableSize.width / drawableSize.height;
    const float near = -cameraDistance - modelSpan / 2.0 + 0.01;
    const float far = near + modelSpan + 0.02;
    const matrix_float4x4 projectionMatrix = matrix_float4x4_perspective(aspect, _fieldOfView, near, far);

    ModelUniforms uniforms;
    uniforms.modelViewMatrix = matrix_multiply(viewMatrix, modelMatrix);
    uniforms.modelViewProjectionMatrix = matrix_multiply(projectionMatrix, uniforms.modelViewMatrix);
    uniforms.normalMatrix = matrix_float4x4_extract_linear(uniforms.modelViewMatrix);

    memcpy([self.uniformBuffers[self.bufferIndex] contents], &uniforms, sizeof(uniforms));
    
    vector_float4 unitVec = { 0, 0, 1, 0 };
    unitVec = matrix_multiply(unitVec, uniforms.modelViewMatrix);
    
    //NSLog(@"Model Vector: %f, %f, %f, %f.", unitVec.x, unitVec.y, unitVec.z, unitVec.w);
    
    LightingUniforms lighting;
    {
        vector_float4 lightVector { 0, 0, 1, 0 };
        const vector_float3 xAxis = { 1, 0, 0 };
        const vector_float3 yAxis = { 0, 1, 0 };
        const matrix_float4x4 xRot = matrix_float4x4_rotation(xAxis, self.lightingRotationX);
        const matrix_float4x4 yRot = matrix_float4x4_rotation(yAxis, self.lightingRotationY);
        const matrix_float4x4 rotationMatrix = matrix_multiply(xRot, yRot);
        
        lightVector = matrix_multiply(rotationMatrix, lightVector);
        lighting.lightVector = { lightVector.x, lightVector.y, lightVector.z, 0.0 };
        
        //NSLog(@"Light Vector: %f, %f, %f, %f.", lightVector.x, lightVector.y, lightVector.z, lightVector.w);
    }
    memcpy([self.lightingBuffers[self.bufferIndex] contents], &lighting, sizeof(LightingUniforms));
}

- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    MTLRenderPassDescriptor *passDescriptor = [self.renderTarget currentRenderPassDescriptor];
    if (!passDescriptor)
        return;
    
    [self updateUniformsForView];

    id<MTLRenderCommandEncoder> renderPass = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
    
    [renderPass setVertexBuffer:self.uniformBuffers[self.bufferIndex] offset:0 atIndex:1];
    [renderPass setVertexBuffer:self.lightingBuffers[self.bufferIndex] offset:0 atIndex:2];
    
    if (_cullEnabled)
        [renderPass setCullMode:MTLCullModeBack];
    else
        [renderPass setCullMode:MTLCullModeNone];

    for (uint8 renderPassStep = 0; renderPassStep < 2; ++renderPassStep)
    {
        for (NuoMesh* mesh : _mesh)
        {
            if (((renderPassStep == 0) && ![mesh hasTransparency]) /* first pass for opaque */ ||
                ((renderPassStep == 1) && [mesh hasTransparency])  /* second pass for transparent */)
                [mesh drawMesh:renderPass];
        }
    }
    
    [renderPass endEncoding];
    
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer) {
        self.bufferIndex = (self.bufferIndex + 1) % InFlightBufferCount;
    }];
}

@end
