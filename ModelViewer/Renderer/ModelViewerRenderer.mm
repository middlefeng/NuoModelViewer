#import "ModelViewerRenderer.h"
#import "NuoUniforms.h"

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

#include "NuoTypes.h"
#include "NuoMesh.h"
#include "NuoRenderPassTarget.h"
#include "NuoMathUtilities.h"
#include "NuoModelBase.h"
#include "NuoModelLoader.h"
#include "NuoTableExporter.h"

#include "NuoLua.h"

#import "LightSource.h"

@interface ModelRenderer ()


@property (nonatomic, strong) NSArray<NuoMesh*>* mesh;
@property (strong) NSArray<id<MTLBuffer>>* modelUniformBuffers;
@property (strong) NSArray<id<MTLBuffer>>* lightingUniformBuffers;
@property (strong) id<MTLBuffer> modelCharacterUnfiromBuffer;

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


- (matrix_float4x4)rotationMatrix
{
    return _rotationMatrix;
}


- (void)loadMesh:(NSString*)path
{
    _modelLoader = [NuoModelLoader new];
    [_modelLoader loadModel:path];
    
    _mesh = [_modelLoader createMeshsWithOptions:_modelOptions
                                      withDevice:self.device];
}


- (NSArray<NuoMesh*>*)mesh
{
    return _mesh;
}


- (NSString*)exportSceneAsString:(CGSize)canvasSize
{
    NuoTableExporter exporter;
    
    exporter.StartTable();
    
    {
        exporter.StartEntry("canvas");
        exporter.StartTable();
        
        {
            exporter.StartEntry("width");
            exporter.SetEntryValueFloat(canvasSize.width);
            exporter.EndEntry(false);
            
            exporter.StartEntry("height");
            exporter.SetEntryValueFloat(canvasSize.height);
            exporter.EndEntry(false);
        }
        
        exporter.EndTable();
        exporter.EndEntry(true);
    }
    
    {
        exporter.StartEntry("rotationMatrix");
        exporter.StartTable();
        
        {
            for (unsigned char col = 0; col < 4; ++ col)
            {
                exporter.StartArrayIndex(col);
                exporter.StartTable();
                
                vector_float4 colomn = _rotationMatrix.columns[col];
                
                for (unsigned char row = 0; row < 4; ++ row)
                {
                    exporter.StartArrayIndex(row);
                    exporter.SetEntryValueFloat(colomn[row]);
                    exporter.EndEntry(false);
                }
                
                exporter.EndTable();
                exporter.EndEntry(false);
            }
        }
        
        exporter.EndTable();
        exporter.EndEntry(true);
    }
    
    {
        exporter.StartEntry("view");
        exporter.StartTable();
        
        {
            exporter.StartEntry("zoom");
            exporter.SetEntryValueFloat(_zoom);
            exporter.EndEntry(false);
            
            exporter.StartEntry("transX");
            exporter.SetEntryValueFloat(_transX);
            exporter.EndEntry(false);
            
            exporter.StartEntry("transY");
            exporter.SetEntryValueFloat(_transY);
            exporter.EndEntry(false);
            
            exporter.StartEntry("FOV");
            exporter.SetEntryValueFloat(_fieldOfView);
            exporter.EndEntry(false);
        }
        
        exporter.EndTable();
        exporter.EndEntry(true);
        
        exporter.StartEntry("models");
        exporter.StartTable();
        
        size_t index = 0;
        
        for (NuoMesh* meshItem : _mesh)
        {
            if (meshItem.smoothTolerance > 0.001 || !meshItem.enabled)
            {
                exporter.StartArrayIndex(++index);
                exporter.StartTable();
                
                exporter.StartEntry("name");
                exporter.SetEntryValueString(meshItem.modelName.UTF8String);
                exporter.EndEntry(false);
                
                exporter.StartEntry("enabled");
                exporter.SetEntryValueBool(meshItem.enabled);
                exporter.EndEntry(false);
                
                exporter.StartEntry("smooth");
                exporter.SetEntryValueFloat(meshItem.smoothTolerance);
                exporter.EndEntry(false);
                
                exporter.EndTable();
                exporter.EndEntry(true);
            }
        }

        exporter.EndTable();
        exporter.EndEntry(true);
        
        exporter.StartEntry("lights");
        exporter.StartTable();
        
        for (unsigned char lightIndex = 0; lightIndex < _lights.count; ++lightIndex)
        {
            exporter.StartArrayIndex(lightIndex);
            exporter.StartTable();
            
            LightSource* light = _lights[lightIndex];
            
            {
                exporter.StartEntry("rotateX");
                exporter.SetEntryValueFloat(light.lightingRotationX);
                exporter.EndEntry(false);
                
                exporter.StartEntry("rotateY");
                exporter.SetEntryValueFloat(light.lightingRotationY);
                exporter.EndEntry(false);
                
                exporter.StartEntry("density");
                exporter.SetEntryValueFloat(light.lightingDensity);
                exporter.EndEntry(false);
                
                exporter.StartEntry("spacular");
                exporter.SetEntryValueFloat(light.lightingSpacular);
                exporter.EndEntry(false);
            }
            
            exporter.EndTable();
            exporter.EndEntry(true);
        }
        
        {
            exporter.StartEntry("ambient");
            exporter.SetEntryValueFloat(_ambientDensity);
            exporter.EndEntry(true);
        }
        
        exporter.EndTable();
        exporter.EndEntry(true);
    }
    
    exporter.EndTable();
    
    return [[NSString alloc] initWithUTF8String:exporter.GetResult().c_str()];
}


- (void)importScene:(NuoLua*)lua
{
    [lua getField:@"rotationMatrix" fromTable:-1];
    _rotationMatrix = [lua getMatrixFromTable:-1];
    [lua removeField];
    
    [lua getField:@"view" fromTable:-1];
    _zoom = [lua getFieldAsNumber:@"zoom" fromTable:-1];
    _transX = [lua getFieldAsNumber:@"transX" fromTable:-1];
    _transY = [lua getFieldAsNumber:@"transY" fromTable:-1];
    _fieldOfView = [lua getFieldAsNumber:@"FOV" fromTable:-1];
    [lua removeField];
    
    [lua getField:@"models" fromTable:-1];
    
    size_t length = [lua getArraySize:-1];
    size_t passedModel = 0;
    
    for (size_t i = 0; i < length; ++i)
    {
        [lua getItem:(int)(i + 1) fromTable:-1];
        NSString* name = [lua getFieldAsString:@"name" fromTable:-1];
        for (size_t i = passedModel; i < _mesh.count; ++i)
        {
            NuoMesh* mesh = _mesh[i];
            
            if ([mesh.modelName isEqualToString:name])
            {
                [mesh setEnabled:[lua getFieldAsBool:@"enabled" fromTable:-1]];
                [mesh smoothWithTolerance:[lua getFieldAsNumber:@"smooth" fromTable:-1]];
                
                passedModel = ++i;
                break;
            }
        }
        [lua removeField];
    }
    [lua removeField];
    
    [lua getField:@"lights" fromTable:-1];
    _ambientDensity = [lua getFieldAsNumber:@"ambient" fromTable:-1];
    [lua removeField];
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
    id<MTLBuffer> modelBuffers[kInFlightBufferCount];
    id<MTLBuffer> lightingBuffers[kInFlightBufferCount];
    
    for (size_t i = 0; i < kInFlightBufferCount; ++i)
    {
        modelBuffers[i] = [self.device newBufferWithLength:sizeof(ModelUniforms)
                                                   options:MTLResourceOptionCPUCacheModeDefault];
        lightingBuffers[i] = [self.device newBufferWithLength:sizeof(LightUniform)
                                                      options:MTLResourceOptionCPUCacheModeDefault];
    }
    
    _modelUniformBuffers = [[NSArray alloc] initWithObjects:modelBuffers[0], modelBuffers[1], modelBuffers[2], nil];
    _lightingUniformBuffers = [[NSArray alloc] initWithObjects:lightingBuffers[0],
                                                               lightingBuffers[1],
                                                               lightingBuffers[2], nil];
    
    ModelCharacterUniforms modelCharacter;
    modelCharacter.opacity = 1.0f;
    _modelCharacterUnfiromBuffer = [self.device newBufferWithLength:sizeof(ModelCharacterUniforms)
                                                            options:MTLResourceOptionCPUCacheModeDefault];
    memcpy([_modelCharacterUnfiromBuffer contents], &modelCharacter, sizeof(ModelCharacterUniforms));
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
    modelSpan = 1.41 * modelSpan;
    
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

    memcpy([self.modelUniformBuffers[self.bufferIndex] contents], &uniforms, sizeof(uniforms));
    
    LightUniform lighting;
    lighting.ambientDensity = _ambientDensity;
    for (unsigned int i = 0; i < 4; ++i)
    {
        const matrix_float4x4 rotationMatrix = matrix_rotate(_lights[i].lightingRotationX,
                                                             _lights[i].lightingRotationY);
        
        vector_float4 lightVector { 0, 0, 1, 0 };
        lightVector = matrix_multiply(rotationMatrix, lightVector);
        lighting.direction[i] = { lightVector.x, lightVector.y, lightVector.z, 0.0 };
        lighting.density[i] = _lights[i].lightingDensity;
        lighting.spacular[i] = _lights[i].lightingSpacular;
    }
    
    memcpy([self.lightingUniformBuffers[self.bufferIndex] contents], &lighting, sizeof(LightUniform));
}

- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    MTLRenderPassDescriptor *passDescriptor = [self.renderTarget currentRenderPassDescriptor];
    if (!passDescriptor)
        return;
    
    [self updateUniformsForView];

    id<MTLRenderCommandEncoder> renderPass = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
    
    [renderPass setVertexBuffer:self.modelUniformBuffers[self.bufferIndex] offset:0 atIndex:1];
    [renderPass setFragmentBuffer:self.lightingUniformBuffers[self.bufferIndex] offset:0 atIndex:0];
    [renderPass setFragmentBuffer:self.modelCharacterUnfiromBuffer offset:0 atIndex:1];
    
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
                if ([mesh enabled])
                    [mesh drawMesh:renderPass];
        }
    }
    
    [renderPass endEncoding];
}

@end
