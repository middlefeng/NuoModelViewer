
#import "NuoMesh.h"
#import "NuoMeshBounds.h"

#include "tiny_obj_loader.h"

#include "NuoModelBase.h"
#include "NuoTypes.h"
#include "NuoMaterial.h"

#import <Cocoa/Cocoa.h>
#import "NuoMeshTextured.h"
#import "NuoMeshTexMatieraled.h"
#import "NuoMeshUniform.h"
#import "NuoMathUtilities.h"



const BOOL kShadowPCSS = YES;
const BOOL kShadowPCF = YES;




@implementation NuoMesh
{
    BOOL _hasTransparency;
    std::shared_ptr<NuoModelBase> _rawModel;
}




@synthesize indexBuffer = _indexBuffer;
@synthesize vertexBuffer = _vertexBuffer;



- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _transformPoise = matrix_identity_float4x4;
        _transformTranslate = matrix_identity_float4x4;
        _sampleCount = kSampleCount;
    }
    
    return self;
}



- (instancetype)initWithDevice:(id<MTLDevice>)device
            withVerticesBuffer:(void*)buffer withLength:(size_t)length
                   withIndices:(void*)indices withLength:(size_t)indicesLength
{
    if ((self = [super init]))
    {
        _vertexBuffer = [device newBufferWithBytes:buffer
                                            length:length
                                           options:MTLResourceOptionCPUCacheModeDefault];
        
        _indexBuffer = [device newBufferWithBytes:indices
                                           length:indicesLength
                                          options:MTLResourceOptionCPUCacheModeDefault];
        _device = device;
        _enabled = true;
        
        _smoothTolerance = 0.0f;
        _smoothConservative = YES;
        
        _rotation = [[NuoMeshRotation alloc] init];
        
        {
            id<MTLBuffer> buffers[kInFlightBufferCount];
            for (unsigned int i = 0; i < kInFlightBufferCount; ++i)
            {
                buffers[i] = [device newBufferWithLength:sizeof(NuoMeshUniforms)
                                                 options:MTLResourceOptionCPUCacheModeDefault];
            }
            _transformBuffers = [[NSArray alloc] initWithObjects:buffers count:kInFlightBufferCount];
        }
        
        _transformPoise = matrix_identity_float4x4;
        _transformTranslate = matrix_identity_float4x4;
        _sampleCount = kSampleCount;
    }
    
    return self;
}



- (instancetype)cloneForMode:(NuoMeshModeShaderParameter)mode
{
    return self;
}


- (void)shareResourcesFrom:(NuoMesh*)mesh
{
    _device = mesh.device;
    _vertexBuffer = mesh.vertexBuffer;
    _indexBuffer = mesh.indexBuffer;
    _transformBuffers = mesh.transformBuffers;
    _enabled = mesh.enabled;
    
    [self setBoundsLocal:mesh.boundsLocal];
}



- (void)updateBounds
{
    matrix_float4x4 transform = matrix_multiply(_transformTranslate, _transformPoise);
    
    if (!_boundsLocal)
        return;
    
    NuoBounds localBounds = *((NuoBounds*)[_boundsLocal boundingBox]);
    NuoSphere localSphere = *((NuoSphere*)[_boundsLocal boundingSphere]);
    
    if (!_bounds)
        _bounds = [NuoMeshBounds new];
    
    NuoBounds* boundsProperty = (NuoBounds*)[_bounds boundingBox];
    NuoSphere* sphereProperty = (NuoSphere*)[_bounds boundingSphere];
    *boundsProperty = localBounds.Transform(transform);
    *sphereProperty = localSphere.Transform(transform);
}



- (void)setBoundsLocal:(NuoMeshBounds*)boundsLocal
{
    _boundsLocal = boundsLocal;
    
    // calculate the sphere from box if the former is not calculated.
    // some subclass might do this by itself (such as compound mesh)
    //
    if (_boundsLocal.boundingSphere->_radius == 0.)
    {
        NuoBounds* localBounds = ((NuoBounds*)[_boundsLocal boundingBox]);
        NuoSphere* localSphere = ((NuoSphere*)[_boundsLocal boundingSphere]);
        *localSphere = localBounds->Sphere();
    }
    
    [self updateBounds];
}



- (void)setTransformTranslate:(matrix_float4x4)transformTranslate
{
    _transformTranslate = transformTranslate;
    [self updateBounds];
}



- (void)smoothWithTolerance:(float)tolerance
{
    _smoothTolerance = tolerance;
    
    std::shared_ptr<NuoModelBase> clonedModel = _rawModel;
    
    if (_smoothTolerance > 0.001)
    {
        clonedModel = _rawModel->Clone();
        clonedModel->SmoothSurface(tolerance, _smoothConservative);
    }
    
    _vertexBuffer = [_device newBufferWithBytes:clonedModel->Ptr()
                                         length:clonedModel->Length()
                                        options:MTLResourceOptionCPUCacheModeDefault];
    
    _indexBuffer = [_device newBufferWithBytes:clonedModel->IndicesPtr()
                                        length:clonedModel->IndicesLength()
                                       options:MTLResourceOptionCPUCacheModeDefault];
}


- (void)setSmoothConservative:(BOOL)smoothConservative
{
    _smoothConservative = smoothConservative;
    [self smoothWithTolerance:_smoothTolerance];
}



- (BOOL)hasUnifiedMaterial
{
    const std::shared_ptr<NuoMaterial>& material = _rawModel->GetUnifiedMaterial();
    return material != nullptr;
}



- (void)setUnifiedOpacity:(float)unifiedOpacity
{
    const std::shared_ptr<NuoMaterial>& material = _rawModel->GetUnifiedMaterial();
    if (!material)
        return;
    
    material.get()->dissolve = unifiedOpacity;
    
    _rawModel->UpdateBufferWithUnifiedMaterial();
    _vertexBuffer = [_device newBufferWithBytes:_rawModel->Ptr()
                                         length:_rawModel->Length()
                                        options:MTLResourceOptionCPUCacheModeDefault];
    
    _indexBuffer = [_device newBufferWithBytes:_rawModel->IndicesPtr()
                                        length:_rawModel->IndicesLength()
                                       options:MTLResourceOptionCPUCacheModeDefault];

    BOOL wasTrans = _hasTransparency;
    _hasTransparency = (unifiedOpacity < 0.99999);
    
    if (wasTrans != _hasTransparency)
        [self makeDepthStencilState];
}



- (float)unifiedOpacity
{
    const std::shared_ptr<NuoMaterial>& material = _rawModel->GetUnifiedMaterial();
    return material->dissolve;
}



- (void)setRawModel:(void*)model
{
    _rawModel = ((NuoModelBase*)model)->shared_from_this();
}


- (NSString*)modelName
{
    if (_rawModel)
    {
        NSString* name = [[NSString alloc] initWithUTF8String:_rawModel->GetName().c_str()];
        return name;
    }
    
    return nil;
}


- (void)setSampleCount:(NSUInteger)sampleCount
{
    if (_sampleCount != sampleCount)
    {
        _sampleCount = sampleCount;
        [self makeGPUStates];
    }
}


- (MTLRenderPipelineDescriptor*)makePipelineStateDescriptor
{
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    
    NSString* vertexFunc = _shadowPipelineState ? @"vertex_project_shadow" : @"vertex_project";
    NSString* fragmnFunc = _shadowPipelineState ? @"fragment_light_shadow" : @"fragment_light";
    
    // there is material and color, not only shadow overlay
    //
    BOOL shadowOverlay = NO;
    int meshMode = kMeshMode_Normal;
    MTLFunctionConstantValues* funcConstant = [MTLFunctionConstantValues new];
    [funcConstant setConstantValue:&shadowOverlay type:MTLDataTypeBool atIndex:3];
    [funcConstant setConstantValue:&kShadowPCSS type:MTLDataTypeBool atIndex:4];
    [funcConstant setConstantValue:&kShadowPCF type:MTLDataTypeBool atIndex:5];
    [funcConstant setConstantValue:&meshMode type:MTLDataTypeInt atIndex:6];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:vertexFunc];
    pipelineDescriptor.fragmentFunction = [library newFunctionWithName:fragmnFunc
                                                        constantValues:funcConstant
                                                                 error:nil];
    pipelineDescriptor.sampleCount = _sampleCount;
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
    MTLRenderPipelineColorAttachmentDescriptor* colorAttachment = pipelineDescriptor.colorAttachments[0];
    colorAttachment.blendingEnabled = YES;
    colorAttachment.rgbBlendOperation = MTLBlendOperationAdd;
    colorAttachment.alphaBlendOperation = MTLBlendOperationAdd;
    colorAttachment.sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    colorAttachment.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    colorAttachment.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    
    return pipelineDescriptor;
}

- (void)makePipelineState:(MTLRenderPipelineDescriptor*)pipelineDescriptor
{
    NSError *error = nil;
    _renderPipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor
                                                                       error:&error];
}

- (void)makePipelineScreenSpaceStateWithVertexShader:(NSString*)vertexShader
                                  withFragemtnShader:(NSString*)fragmentShader
{
    MTLFunctionConstantValues* constants = [MTLFunctionConstantValues new];
    BOOL shadowOverlay = NO;
    [constants setConstantValue:&shadowOverlay type:MTLDataTypeBool atIndex:3];
    
    [self makePipelineScreenSpaceStateWithVertexShader:vertexShader
                                    withFragemtnShader:fragmentShader
                                         withConstants:constants];
}

- (void)makePipelineScreenSpaceStateWithVertexShader:(NSString*)vertexShader
                                  withFragemtnShader:(NSString*)fragmentShader
                                       withConstants:(MTLFunctionConstantValues*)constants
{
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    
    MTLRenderPipelineDescriptor *screenSpacePipelineDescriptor = [MTLRenderPipelineDescriptor new];
    screenSpacePipelineDescriptor.vertexFunction = [library newFunctionWithName:vertexShader];
    screenSpacePipelineDescriptor.fragmentFunction = [library newFunctionWithName:fragmentShader constantValues:constants error:nil];
    screenSpacePipelineDescriptor.sampleCount = _sampleCount;
    
    // blending is turned OFF for all attachments, see comments to "FragementScreenSpace"
    //
    screenSpacePipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA16Float;
    screenSpacePipelineDescriptor.colorAttachments[1].pixelFormat = MTLPixelFormatRGBA16Float;
    screenSpacePipelineDescriptor.colorAttachments[2].pixelFormat = MTLPixelFormatRGBA16Float;
    screenSpacePipelineDescriptor.colorAttachments[3].pixelFormat = MTLPixelFormatR8Unorm;
    
    screenSpacePipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
    NSError *error = nil;
    _screenSpacePipelineState = [self.device newRenderPipelineStateWithDescriptor:screenSpacePipelineDescriptor
                                                                            error:&error];
}

- (void)makePipelineScreenSpaceState
{
    [self makePipelineScreenSpaceStateWithVertexShader:@"vertex_project_screen_space"
                                    withFragemtnShader:@"fragement_screen_space"];
}
    
- (void)makePipelineShadowState:(NSString*)vertexShadowShader
{
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    
    MTLRenderPipelineDescriptor *shadowPipelineDescriptor = [MTLRenderPipelineDescriptor new];
    shadowPipelineDescriptor.vertexFunction = [library newFunctionWithName:vertexShadowShader];
    shadowPipelineDescriptor.fragmentFunction = nil;
    shadowPipelineDescriptor.sampleCount = 1 /*kSampleCount*/;
    shadowPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatInvalid;
    shadowPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
    NSError *error = nil;
    _shadowPipelineState = [self.device newRenderPipelineStateWithDescriptor:shadowPipelineDescriptor
                                                                       error:&error];
}

- (void)makePipelineShadowState
{
    return [self makePipelineShadowState:@"vertex_shadow"];
}

- (void)makeDepthStencilState
{
    MTLDepthStencilDescriptor *depthStencilDescriptor = [MTLDepthStencilDescriptor new];
    depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
    
    if (self.hasTransparency)
        depthStencilDescriptor.depthWriteEnabled = NO;
    else
        depthStencilDescriptor.depthWriteEnabled = YES;
    
    _depthStencilState = [self.device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
}

- (void)makeGPUStates
{
    [self makePipelineScreenSpaceState];
    [self makePipelineShadowState];
    [self makePipelineState:[self makePipelineStateDescriptor]];
    [self makeDepthStencilState];
}



- (void)updateUniform:(NSInteger)bufferIndex withTransform:(matrix_float4x4)transform
{
    matrix_float4x4 localTransform = matrix_multiply(_transformTranslate, _transformPoise);
    if (_rotation)
        localTransform = matrix_multiply(localTransform, _rotation.rotationMatrix);
    transform = matrix_multiply(transform, localTransform);
    
    NuoMeshUniforms uniforms;
    uniforms.transform = transform;
    uniforms.normalTransform = matrix_extract_linear(uniforms.transform);
    memcpy([_transformBuffers[bufferIndex] contents], &uniforms, sizeof(uniforms));
}



- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderPass setRenderPipelineState:_renderPipelineState];
    [renderPass setDepthStencilState:_depthStencilState];
    
    NSUInteger rotationIndex = _shadowPipelineState ? 3 : 2;
    
    [renderPass setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
    [renderPass setVertexBuffer:_transformBuffers[index] offset:0 atIndex:rotationIndex];
    [renderPass drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                           indexCount:[_indexBuffer length] / sizeof(uint32_t)
                            indexType:MTLIndexTypeUInt32
                          indexBuffer:_indexBuffer
                    indexBufferOffset:0];
}


- (void)drawScreenSpace:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderPass setRenderPipelineState:_screenSpacePipelineState];
    [renderPass setDepthStencilState:_depthStencilState];
    
    NSUInteger rotationIndex = _shadowPipelineState ? 3 : 2;
    
    [renderPass setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
    [renderPass setVertexBuffer:_transformBuffers[index] offset:0 atIndex:rotationIndex];
    [renderPass drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                           indexCount:[_indexBuffer length] / sizeof(uint32_t)
                            indexType:MTLIndexTypeUInt32
                          indexBuffer:_indexBuffer
                    indexBufferOffset:0];
}


- (void)drawShadow:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    if (_shadowPipelineState)
    {
        [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
        [renderPass setRenderPipelineState:_shadowPipelineState];
        [renderPass setDepthStencilState:_depthStencilState];
        
        [renderPass setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
        [renderPass setVertexBuffer:_transformBuffers[index] offset:0 atIndex:2];
        [renderPass drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                               indexCount:[_indexBuffer length] / sizeof(uint32_t)
                                indexType:MTLIndexTypeUInt32
                              indexBuffer:_indexBuffer
                        indexBufferOffset:0];
    }
}


- (BOOL)hasTransparency
{
    return _hasTransparency;
}


- (void)setTransparency:(BOOL)transparent
{
    _hasTransparency = transparent;
}



- (void)centerMesh
{
    NuoBoundsBase* bounds = [_boundsLocal boundingBox];
    const vector_float3 translationToCenter =
    {
        - bounds->_center.x,
        - bounds->_center.y,
        - bounds->_center.z
    };
    const matrix_float4x4 modelCenteringMatrix = matrix_translation(translationToCenter);
    _transformPoise = modelCenteringMatrix;
    
    [self updateBounds];
}


@end





NuoMesh* CreateMesh(const NuoModelOption& options,
                    id<MTLDevice> device, id<MTLCommandQueue> commandQueue,
                    const std::shared_ptr<NuoModelBase> model)
{
    NuoMesh* resultMesh = nil;
    bool textured = options._textured && !model->GetTexturePathDiffuse().empty();
    
    if (!textured && !options._basicMaterialized)
    {
        NuoMesh* mesh = [[NuoMesh alloc] initWithDevice:device
                                     withVerticesBuffer:model->Ptr()
                                             withLength:model->Length()
                                            withIndices:model->IndicesPtr()
                                             withLength:model->IndicesLength()];
        
        resultMesh = mesh;
    }
    else if (textured && !options._basicMaterialized)
    {
        NSString* modelTexturePath = [NSString stringWithUTF8String:model->GetTexturePathDiffuse().c_str()];
        BOOL checkTransparency = options._textureEmbedMaterialTransparency;
        
        NuoMeshTextured* mesh = [[NuoMeshTextured alloc] initWithDevice:device
                                                     withVerticesBuffer:model->Ptr()
                                                             withLength:model->Length()
                                                            withIndices:model->IndicesPtr()
                                                             withLength:model->IndicesLength()];
        
        [mesh makeTexture:modelTexturePath checkTransparency:checkTransparency withCommandQueue:commandQueue];
        
        resultMesh = mesh;
    }
    else if (textured && options._basicMaterialized)
    {
        NSString* modelTexturePath = [NSString stringWithUTF8String:model->GetTexturePathDiffuse().c_str()];
        BOOL embeddedAlpha = options._textureEmbedMaterialTransparency;
        
        NuoMeshTexMatieraled* mesh = [[NuoMeshTexMatieraled alloc] initWithDevice:device
                                         withVerticesBuffer:model->Ptr()
                                                 withLength:model->Length()
                                                withIndices:model->IndicesPtr()
                                                 withLength:model->IndicesLength()];
        
        [mesh makeTexture:modelTexturePath checkTransparency:embeddedAlpha withCommandQueue:commandQueue];
        
        NSString* modelTexturePathOpacity = [NSString stringWithUTF8String:model->GetTexturePathOpacity().c_str()];
        if ([modelTexturePathOpacity isEqualToString:@""])
            modelTexturePathOpacity = nil;
        if (modelTexturePathOpacity)
            [mesh makeTextureOpacity:modelTexturePathOpacity withCommandQueue:commandQueue];
        
        NSString* modelTexturePathBump = [NSString stringWithUTF8String:model->GetTexturePathBump().c_str()];
        if ([modelTexturePathBump isEqualToString:@""])
            modelTexturePathBump = nil;
        if (modelTexturePathBump)
            [mesh makeTextureBump:modelTexturePathBump withCommandQueue:commandQueue];
        
        if (model->HasTransparent() || modelTexturePathOpacity)
            [mesh setTransparency:YES];
        else if (!embeddedAlpha)
            [mesh setTransparency:NO];
        
        [mesh setIgnoreTexutreAlpha:!embeddedAlpha];
        [mesh setPhysicallyReflection:options._physicallyReflection];
        
        resultMesh = mesh;
    }
    else if (!textured && options._basicMaterialized)
    {
        NuoMeshMatieraled* mesh = [[NuoMeshMatieraled alloc] initWithDevice:device
                                                         withVerticesBuffer:model->Ptr()
                                                                 withLength:model->Length()
                                                                withIndices:model->IndicesPtr()
                                                                 withLength:model->IndicesLength()];
        
        [mesh setTransparency:model->HasTransparent()];
        [mesh setPhysicallyReflection:options._physicallyReflection];
        
        resultMesh = mesh;
    }
    
    [resultMesh setRawModel:model.get()];
    [resultMesh makeGPUStates];
    return resultMesh;
}


