#import "ModelViewerRenderer.h"
#import "ShadowMapRenderer.h"

#import "NuoUniforms.h"

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#import <simd/simd.h>

#include "NuoTypes.h"
#include "NuoMesh.h"
#include "NuoCubeMesh.h"
#include "NuoRenderPassTarget.h"
#include "NuoMathUtilities.h"
#include "NuoModelBase.h"
#include "NuoModelLoader.h"
#include "NuoTableExporter.h"

#include "NuoTextureBase.h"

#include "NuoLua.h"

#import "LightSource.h"

@interface ModelRenderer ()


@property (nonatomic, strong) NSArray<NuoMesh*>* mesh;
@property (nonatomic, strong) NuoCubeMesh* cubeMesh;

@property (strong) NSArray<id<MTLBuffer>>* modelUniformBuffers;
@property (strong) NSArray<id<MTLBuffer>>* lightCastBuffers;
@property (strong) NSArray<id<MTLBuffer>>* lightingUniformBuffers;
@property (strong) id<MTLBuffer> modelCharacterUnfiromBuffer;

@property (nonatomic, readonly) id<MTLSamplerState> shadowMapSamplerState;


@property (strong) NuoModelLoader* modelLoader;

@property (nonatomic, assign) matrix_float4x4 rotationMatrix;


@end



@implementation ModelRenderer
{
    NuoMeshBox* _meshBounding;
    float _meshMaxSpan;
    
    ShadowMapRenderer* _shadowMapRenderer[2];
}



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
        
        _shadowMapRenderer[0] = [[ShadowMapRenderer alloc] initWithDevice:device withName:@"Shadow 0"];
        _shadowMapRenderer[1] = [[ShadowMapRenderer alloc] initWithDevice:device withName:@"Shadow 1"];
        
        _cubeMesh = [[NuoCubeMesh alloc] initWithDevice:device];
        NuoTextureBase* base = [NuoTextureBase getInstance:device];
        _cubeMesh.cubeTexture = [base textureCubeWithImageNamed:@"/Users/middleware/Desktop/test.jpg"];
        
        [_cubeMesh makeDepthStencilState];
        [_cubeMesh makePipelineAndSampler:MTLPixelFormatBGRA8Unorm];
    }

    return self;
}


- (void)setDrawableSize:(CGSize)drawableSize
{
    [super setDrawableSize:drawableSize];
    [_shadowMapRenderer[0] setDrawableSize:drawableSize];
    [_shadowMapRenderer[1] setDrawableSize:drawableSize];
}


- (void)setRenderTarget:(NuoRenderPassTarget *)renderTarget
{
    [super setRenderTarget:renderTarget];
    [_shadowMapRenderer[0].renderTarget setSampleCount:renderTarget.sampleCount];
    [_shadowMapRenderer[1].renderTarget setSampleCount:renderTarget.sampleCount];
}


- (void)loadMesh:(NSString*)path withCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    _modelLoader = [NuoModelLoader new];
    [_modelLoader loadModel:path];
    
    [self createMeshs:commandQueue];
}


- (void)createMeshs:(id<MTLCommandQueue>)commandQueue
{
    _mesh = [_modelLoader createMeshsWithOptions:_modelOptions
                                      withDevice:self.device
                                withCommandQueue:commandQueue];
    
    NuoMeshBox* bounding = _mesh[0].boundingBox;
    for (size_t i = 1; i < _mesh.count; ++i)
        bounding = [bounding unionWith:_mesh[i].boundingBox];
    
    _meshBounding = bounding;
    
    float modelSpan = std::max(bounding.spanZ, bounding.spanX);
    modelSpan = std::max(bounding.spanY, modelSpan);
    _meshMaxSpan = 1.41 * modelSpan;
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
            if (meshItem.smoothTolerance > 0.001 || !meshItem.enabled ||
                meshItem.reverseCommonCullMode || (meshItem.hasUnifiedMaterial && meshItem.unifiedOpacity != 1.0))
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
                
                exporter.StartEntry("smoothConservative");
                exporter.SetEntryValueBool(meshItem.smoothConservative);
                exporter.EndEntry(false);
                
                exporter.StartEntry("cullModeReverse");
                exporter.SetEntryValueBool(meshItem.reverseCommonCullMode);
                exporter.EndEntry(false);
                
                exporter.StartEntry("opacity");
                exporter.SetEntryValueFloat(meshItem.unifiedOpacity);
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
                
                exporter.StartEntry("enableShadow");
                exporter.SetEntryValueBool(light.enableShadow);
                exporter.EndEntry(false);
                
                assert(light.enableShadow == (lightIndex < 2));
                
                if (light.enableShadow)
                {
                    exporter.StartEntry("shadowSoften");
                    exporter.SetEntryValueFloat(light.shadowSoften);
                    exporter.EndEntry(false);
                    
                    exporter.StartEntry("shadowBias");
                    exporter.SetEntryValueFloat(light.shadowBias);
                    exporter.EndEntry(false);
                }
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
                [mesh setReverseCommonCullMode:[lua getFieldAsBool:@"cullModeReverse" fromTable:-1]];
                [mesh setUnifiedOpacity:[lua getFieldAsNumber:@"opacity" fromTable:-1]];
                [mesh setSmoothConservative:[lua getFieldAsBool:@"smoothConservative" fromTable:-1]];
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



- (void)setCubeRotationX:(float)x
{
    _cubeMesh.rotationXDelta = x;
}



- (void)setCubeRotationY:(float)y
{
    _cubeMesh.rotationYDelta = y;
}



- (void)setModelOptions:(NuoMeshOption *)modelOptions
       withCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    _modelOptions = modelOptions;
    
    if (_modelLoader)
    {
        [self createMeshs:commandQueue];
    }
}


- (void)makeResources
{
    id<MTLBuffer> modelBuffers[kInFlightBufferCount];
    id<MTLBuffer> lightingBuffers[kInFlightBufferCount];
    id<MTLBuffer> lightCastModelBuffers[kInFlightBufferCount];
    
    for (size_t i = 0; i < kInFlightBufferCount; ++i)
    {
        modelBuffers[i] = [self.device newBufferWithLength:sizeof(ModelUniforms)
                                                   options:MTLResourceOptionCPUCacheModeDefault];
        lightingBuffers[i] = [self.device newBufferWithLength:sizeof(LightUniform)
                                                      options:MTLResourceOptionCPUCacheModeDefault];
        lightCastModelBuffers[i] = [self.device newBufferWithLength:sizeof(LightVertexUniforms)
                                                        options:MTLResourceOptionCPUCacheModeDefault];
        
    }
    
    _modelUniformBuffers = [[NSArray alloc] initWithObjects:modelBuffers count:kInFlightBufferCount];
    _lightingUniformBuffers = [[NSArray alloc] initWithObjects:lightingBuffers count:kInFlightBufferCount];
    _lightCastBuffers = [[NSArray alloc] initWithObjects:lightCastModelBuffers count:kInFlightBufferCount];
    
    ModelCharacterUniforms modelCharacter;
    modelCharacter.opacity = 1.0f;
    _modelCharacterUnfiromBuffer = [self.device newBufferWithLength:sizeof(ModelCharacterUniforms)
                                                            options:MTLResourceOptionCPUCacheModeDefault];
    memcpy([_modelCharacterUnfiromBuffer contents], &modelCharacter, sizeof(ModelCharacterUniforms));
    
    // create sampler state for shadow map sampling
    MTLSamplerDescriptor *samplerDesc = [MTLSamplerDescriptor new];
    samplerDesc.sAddressMode = MTLSamplerAddressModeClampToEdge;
    samplerDesc.tAddressMode = MTLSamplerAddressModeClampToEdge;
    samplerDesc.minFilter = MTLSamplerMinMagFilterLinear;
    samplerDesc.magFilter = MTLSamplerMinMagFilterLinear;
    samplerDesc.mipFilter = MTLSamplerMipFilterNotMipmapped;
    _shadowMapSamplerState = [self.device newSamplerStateWithDescriptor:samplerDesc];
}

- (void)updateUniformsForView:(matrix_float4x4*)modelMatrixOut withInFlight:(unsigned int)inFlight
{
    //_cubeMesh.rotationXDelta = _rotationXDelta;
    //_cubeMesh.rotationYDelta = _rotationYDelta;
    
    // accumulate delta rotation into matrix
    //
    self.rotationMatrix = matrix_rotation_append(self.rotationMatrix, _rotationXDelta, _rotationYDelta);
    _rotationXDelta = 0;
    _rotationYDelta = 0;
    
    const vector_float3 translationToCenter =
    {
        - _meshBounding.centerX,
        - _meshBounding.centerY,
        - _meshBounding.centerZ
    };
    const matrix_float4x4 modelCenteringMatrix = matrix_translation(translationToCenter);
    const matrix_float4x4 modelMatrix = matrix_multiply(self.rotationMatrix, modelCenteringMatrix);
    
    *modelMatrixOut = modelMatrix;
    
    const float modelNearest = - _meshMaxSpan / 2.0;
    const float bilateralFactor = 1 / 750.0f;
    const float cameraDefaultDistance = (modelNearest - _meshMaxSpan);
    const float cameraDistance = cameraDefaultDistance + _zoom * _meshMaxSpan / 20.0f;
    
    const float doTransX = _transX * cameraDistance * bilateralFactor;
    const float doTransY = _transY * cameraDistance * bilateralFactor;
    
    const vector_float3 cameraTranslation =
    {
        doTransX, doTransY,
        cameraDistance
    };

    const matrix_float4x4 viewMatrix = matrix_translation(cameraTranslation);
    
    const CGSize drawableSize = self.renderTarget.drawableSize;
    const float aspect = drawableSize.width / drawableSize.height;
    const float near = -cameraDistance - _meshMaxSpan / 2.0 + 0.01;
    const float far = near + _meshMaxSpan + 0.02;
    const matrix_float4x4 projectionMatrix = matrix_perspective(aspect, _fieldOfView, near, far);

    ModelUniforms uniforms;
    uniforms.modelViewMatrix = matrix_multiply(viewMatrix, modelMatrix);
    uniforms.modelViewProjectionMatrix = matrix_multiply(projectionMatrix, uniforms.modelViewMatrix);
    uniforms.normalMatrix = matrix_extract_linear(uniforms.modelViewMatrix);

    memcpy([self.modelUniformBuffers[inFlight] contents], &uniforms, sizeof(uniforms));
    
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
        
        if (i < 2)
        {
            lighting.shadowSoften[i] = _lights[i].shadowSoften;
            lighting.shadowBias[i] = _lights[i].shadowBias;
        }
    }
    
    memcpy([self.lightingUniformBuffers[inFlight] contents], &lighting, sizeof(LightUniform));
    
    for (NuoMesh* item in _mesh)
        [item updateUniform:inFlight];
    
    const matrix_float4x4 projectionMatrixForCube = matrix_perspective(aspect, _fieldOfView, 0.3, 2.0);
    [_cubeMesh setProjectionMatrix:projectionMatrixForCube];
    [_cubeMesh updateUniform:inFlight];
}

- (void)predrawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
               withInFlightIndex:(unsigned int)inFlight
{
    matrix_float4x4 modelMatrix;
    [self updateUniformsForView:&modelMatrix withInFlight:inFlight];
    
    // generate shadow map
    //
    for (unsigned int i = 0; i < 2 /* for two light sources only */; ++i)
    {
        _shadowMapRenderer[i].modelMatrix = modelMatrix;
        _shadowMapRenderer[i].mesh = _mesh;
        _shadowMapRenderer[i].lightSource = _lights[i];
        _shadowMapRenderer[i].meshMaxSpan = _meshMaxSpan;
        [_shadowMapRenderer[i] drawWithCommandBuffer:commandBuffer withInFlightIndex:inFlight];
    }
    
    // store the light view point projection for shadow map detection in the scene
    //
    LightVertexUniforms lightUniforms;
    lightUniforms.lightCastMatrix[0] = _shadowMapRenderer[0].lightCastMatrix;
    lightUniforms.lightCastMatrix[1] = _shadowMapRenderer[1].lightCastMatrix;
    memcpy([_lightCastBuffers[inFlight] contents], &lightUniforms, sizeof(lightUniforms));
}

- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    MTLRenderPassDescriptor *passDescriptor = [self.renderTarget currentRenderPassDescriptor];
    if (!passDescriptor)
        return;
    
    // get the target render pass and draw the scene
    //
    id<MTLRenderCommandEncoder> renderPass = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
    
    if (_cubeMesh)
        [_cubeMesh drawMesh:renderPass indexBuffer:inFlight];
    
    [renderPass setVertexBuffer:self.modelUniformBuffers[inFlight] offset:0 atIndex:1];
    [renderPass setVertexBuffer:_lightCastBuffers[inFlight] offset:0 atIndex:2];
    
    [renderPass setFragmentBuffer:self.lightingUniformBuffers[inFlight] offset:0 atIndex:0];
    [renderPass setFragmentBuffer:self.modelCharacterUnfiromBuffer offset:0 atIndex:1];
    [renderPass setFragmentTexture:_shadowMapRenderer[0].renderTarget.targetTexture atIndex:0];
    [renderPass setFragmentTexture:_shadowMapRenderer[1].renderTarget.targetTexture atIndex:1];
    [renderPass setFragmentSamplerState:_shadowMapSamplerState atIndex:0];
    
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
        
        for (NuoMesh* mesh : _mesh)
        {
            if (((renderPassStep == 0) && ![mesh hasTransparency] && ![mesh reverseCommonCullMode]) /* 1/2 pass for opaque */     ||
                ((renderPassStep == 1) && ![mesh hasTransparency] && [mesh reverseCommonCullMode])                                ||
                ((renderPassStep == 2) && [mesh hasTransparency] && [mesh reverseCommonCullMode])  /* 3/4 pass for transparent */ ||
                ((renderPassStep == 3) && [mesh hasTransparency] && ![mesh reverseCommonCullMode]))
                if ([mesh enabled])
                    [mesh drawMesh:renderPass indexBuffer:inFlight];
        }
    }
    
    [renderPass endEncoding];
}

@end
