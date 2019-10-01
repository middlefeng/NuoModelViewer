
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

#import "NuoShaderLibrary.h"
#import "NuoRenderPassEncoder.h"
#import "NuoBufferSwapChain.h"






@implementation NuoMesh
{
    BOOL _hasTransparency;
    std::shared_ptr<NuoModelBase> _rawModel;
    
    NuoMeshModeShaderParameter _meshMode;
    NuoShaderLibrary* _library;
    
    NuoMatrixFloat44 _globalBufferCachedTrans;
}




@synthesize indexBuffer = _indexBuffer;
@synthesize vertexBuffer = _vertexBuffer;



- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _transformPoise = NuoMatrixFloat44Identity;
        _transformTranslate = NuoMatrixFloat44Identity;
        _sampleCount = kSampleCount;
        _meshMode = kMeshMode_Normal;
        
        memset(&_globalBufferCachedTrans, 0, sizeof(NuoMatrixFloat44));
    }
    
    return self;
}



- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                  withVerticesBuffer:(void*)buffer withLength:(size_t)length
                         withIndices:(void*)indices withLength:(size_t)indicesLength
{
    if ((self = [super init]))
    {
        id<MTLDevice> device = commandQueue.device;
        _vertexBuffer = [device newBufferWithLength:length
                                            options:MTLResourceStorageModePrivate];
        _indexBuffer = [device newBufferWithLength:indicesLength
                                            options:MTLResourceStorageModePrivate];
            
        _commandQueue = commandQueue;
        _enabled = true;
        
        [self updateVerticesBuffer:buffer withLength:length withIndices:indices withLength:indicesLength];
        
        _smoothTolerance = 0.0f;
        _smoothConservative = YES;
        
        _shadowOptionPCSS = YES;
        _shadowOptionPCF = YES;
        _shadowOptionRayTracing = NO;
        
        _rotation = NuoMeshRotation();
        
        _transformBuffers = [[NuoBufferSwapChain alloc] initWithDevice:device
                                                        WithBufferSize:sizeof(NuoMeshUniforms)
                                                           withOptions:MTLResourceStorageModeManaged
                                                         withChainSize:kInFlightBufferCount];
        
        _transformPoise = NuoMatrixFloat44Identity;
        _transformTranslate = NuoMatrixFloat44Identity;
        _sampleCount = kSampleCount;
        
        memset(&_globalBufferCachedTrans, 0, sizeof(NuoMatrixFloat44));
    }
    
    return self;
}



- (instancetype)cloneForMode:(NuoMeshModeShaderParameter)mode
{
    NuoMesh* mesh = [NuoMesh new];
    [mesh shareResourcesFrom:self];
    
    [mesh makePipelineShadowState];
    [mesh makePipelineState];
    [mesh makeDepthStencilState];
    
    return mesh;
}


- (void)updateVerticesBuffer:(void*)buffer withLength:(size_t)length
                 withIndices:(void*)indices withLength:(size_t)indicesLength
{
    @autoreleasepool
    {
        id<MTLBuffer> vertexBuffer = [self.device newBufferWithBytes:buffer
                                                              length:length
                                                             options:MTLResourceStorageModeShared];

        id<MTLBuffer> indexBuffer = [self.device newBufferWithBytes:indices
                                                             length:indicesLength
                                                            options:MTLResourceStorageModeShared];
        
        id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
        id<MTLBlitCommandEncoder> encoder = [commandBuffer blitCommandEncoder];
        [encoder copyFromBuffer:vertexBuffer sourceOffset:0 toBuffer:_vertexBuffer destinationOffset:0 size:length];
        [encoder copyFromBuffer:indexBuffer sourceOffset:0 toBuffer:_indexBuffer destinationOffset:0 size:indicesLength];
        [encoder endEncoding];
        [commandBuffer commit];
    }
}


- (NuoMatrixFloat44)meshTransform
{
    return _rotation.RotationMatrix() * _transformTranslate * _transformPoise;
}


- (void)cacheTransform:(const NuoMatrixFloat44&)transform
{
    const NuoMatrixFloat44 transformWorld = transform * self.meshTransform;
    _globalBufferCachedTrans = transformWorld;
}


- (void)shareResourcesFrom:(NuoMesh*)mesh
{
    _commandQueue = mesh.commandQueue;
    _vertexBuffer = mesh.vertexBuffer;
    _indexBuffer = mesh.indexBuffer;
    _transformBuffers = mesh.transformBuffers;
    _enabled = mesh.enabled;
    _cullEnabled = mesh.cullEnabled;
    
    _shadowOptionPCSS = mesh.shadowOptionPCSS;
    _shadowOptionPCF = mesh.shadowOptionPCF;
    
    [self setBoundsLocal:mesh.boundsLocal];
}



- (NuoMeshBounds)worldBounds:(const NuoMatrixFloat44&)transform
{
    const NuoBounds& boundsLocal = _boundsLocal.boundingBox;
    const NuoSphere& sphereLocal = _boundsLocal.boundingSphere;
    
    const NuoMatrixFloat44 transformWorld = transform * self.meshTransform;
    
    NuoMeshBounds worldMeshBounds =
    {
        boundsLocal.Transform(transformWorld),
        sphereLocal.Transform(transformWorld)
    };
    
    return worldMeshBounds;
}



- (void)setBoundsLocal:(NuoMeshBounds)boundsLocal
{
    _boundsLocal = boundsLocal;
    
    // calculate the sphere from box if the former is not calculated.
    // some subclass might do this by itself (such as compound mesh)
    //
    if (_boundsLocal.boundingSphere._radius == 0.)
    {
        _boundsLocal.boundingSphere = _boundsLocal.boundingBox.Sphere();
    }
}



- (void)setTransformTranslate:(const NuoMatrixFloat44)transformTranslate
{
    _transformTranslate = transformTranslate;
}



- (void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    _globalBufferCachedTrans = NuoMatrixFloat44Identity;
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
    
    [self updateVerticesBuffer:clonedModel->Ptr() withLength:clonedModel->Length()
                   withIndices:clonedModel->IndicesPtr() withLength:clonedModel->IndicesLength()];
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


- (id<MTLDevice>)device
{
    return _commandQueue.device;
}


- (id<MTLLibrary>)library
{
    if (!_library)
    {
        _library = [NuoShaderLibrary defaultLibraryWithDevice:_commandQueue.device];
    }
    
    return _library.library;
}



- (void)setUnifiedOpacity:(float)unifiedOpacity
{
    const std::shared_ptr<NuoMaterial>& material = _rawModel->GetUnifiedMaterial();
    if (!material)
        return;
    
    material.get()->dissolve = unifiedOpacity;
    
    _rawModel->UpdateBufferWithUnifiedMaterial();
    [self updateVerticesBuffer:_rawModel->Ptr() withLength:_rawModel->Length()
                   withIndices:_rawModel->IndicesPtr() withLength:_rawModel->IndicesLength()];

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



- (void)setRawModel:(const PNuoModelBase&)model
{
    _rawModel = model;
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


- (void)appendWorldBuffers:(const NuoMatrixFloat44&)transform toBuffers:(NuoGlobalBuffers*)buffers
{
    const NuoMatrixFloat44 transformWorld = transform * self.meshTransform;
    
    [self cacheTransform:transform];
    
    std::shared_ptr<NuoModelBase> clonedModel = _rawModel;
    
    if (_smoothTolerance > 0.001)
    {
        clonedModel = _rawModel->Clone();
        clonedModel->SmoothSurface(_smoothTolerance, _smoothConservative);
    }
    
    NuoGlobalBuffers buffer = clonedModel->GetGlobalBuffers();
    buffer.TransformPosition(transformWorld);
    buffer.TransformVector(NuoMatrixExtractLinear(transformWorld));
    
    buffers->Union(buffer);
}


- (BOOL)isCachedTransformValid:(const NuoMatrixFloat44 &)transform
{
    const NuoMatrixFloat44 transformWorld = transform * self.meshTransform;
    return (_globalBufferCachedTrans == transformWorld);
}


- (void)setSampleCount:(NSUInteger)sampleCount
{
    if (_sampleCount != sampleCount)
    {
        _sampleCount = sampleCount;
        [self makeGPUStates];
    }
}


- (void)setMeshMode:(NuoMeshModeShaderParameter)mode
{
    _meshMode = mode;
    
    if (_meshMode != kMeshMode_Normal)
    {
        _cullEnabled = NO;
        _reverseCommonCullMode = NO;
    }
}



- (NuoMeshModeShaderParameter)meshMode
{
    return _meshMode;
}


- (void)setupCommonPipelineFunctionConstants:(MTLFunctionConstantValues*)constants
{
    BOOL pcss = self.shadowOptionPCSS;
    BOOL pcf = self.shadowOptionPCF;
    BOOL rayTracing = self.shadowOptionRayTracing;
    NuoMeshModeShaderParameter meshMode = self.meshMode;
    
    [constants setConstantValue:&pcss type:MTLDataTypeBool atIndex:4];
    [constants setConstantValue:&pcf type:MTLDataTypeBool atIndex:5];
    [constants setConstantValue:&rayTracing type:MTLDataTypeBool atIndex:7];
    [constants setConstantValue:&meshMode type:MTLDataTypeInt atIndex:6];
}


- (MTLRenderPipelineDescriptor*)makePipelineStateDescriptor
{
    id<MTLLibrary> library = [self library];
    
    NSString* vertexFunc = _shadowPipelineState ? @"vertex_project_shadow" : @"vertex_project";
    NSString* fragmnFunc = _shadowPipelineState ? @"fragment_light_shadow" : @"fragment_light";
    
    // there is material and color, not only shadow overlay
    //
    BOOL shadowOverlay = NO;
    int meshMode = kMeshMode_Normal;
    
    BOOL pcss = self.shadowOptionPCSS;
    BOOL pcf = self.shadowOptionPCF;
    BOOL rayTracing = self.shadowOptionRayTracing;
    BOOL physicallyBased = NO;
    
    MTLFunctionConstantValues* funcConstant = [MTLFunctionConstantValues new];
    [funcConstant setConstantValue:&physicallyBased type:MTLDataTypeBool atIndex:2];
    [funcConstant setConstantValue:&shadowOverlay type:MTLDataTypeBool atIndex:3];
    [funcConstant setConstantValue:&pcss type:MTLDataTypeBool atIndex:4];
    [funcConstant setConstantValue:&pcf type:MTLDataTypeBool atIndex:5];
    [funcConstant setConstantValue:&meshMode type:MTLDataTypeInt atIndex:6];
    [funcConstant setConstantValue:&rayTracing type:MTLDataTypeBool atIndex:7];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:vertexFunc];
    pipelineDescriptor.fragmentFunction = [library newFunctionWithName:fragmnFunc
                                                        constantValues:funcConstant
                                                                 error:nil];
    pipelineDescriptor.sampleCount = _sampleCount;
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
    MTLRenderPipelineColorAttachmentDescriptor* colorAttachment = pipelineDescriptor.colorAttachments[0];
    [self applyTransmissionBlending:colorAttachment];
    
    return pipelineDescriptor;
}

- (void)applyTransmissionBlending:(MTLRenderPipelineColorAttachmentDescriptor*)colorAttachment
{
    colorAttachment.blendingEnabled = YES;
    colorAttachment.rgbBlendOperation = MTLBlendOperationAdd;
    colorAttachment.alphaBlendOperation = MTLBlendOperationAdd;
    
    // the source blend factor is set to 1.0 because the engergy of front-surface reflection and
    // back-surface going-through should be simply added
    //
    // note that when non-1.0 constant is used (like source-alpha which was mistakenly used), compensations
    // like up-scaling the reflectance factor in shader won't always work, because some target is normalized
    // to [0, 1.0] in prior of the blending.
    //
    colorAttachment.sourceRGBBlendFactor = MTLBlendFactorOne;
    
    // the going-through ratio of the front-surface is considered as its opacity
    //
    colorAttachment.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    colorAttachment.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
}

- (void)makePipelineState
{
    [self makePipelineState:[self makePipelineStateDescriptor]];
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
    id<MTLLibrary> library = [self library];
    
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
    id<MTLLibrary> library = [self library];
    
    MTLRenderPipelineDescriptor *shadowPipelineDescriptor = [MTLRenderPipelineDescriptor new];
    shadowPipelineDescriptor.vertexFunction = [library newFunctionWithName:vertexShadowShader];
    shadowPipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"depth_simple"];
    shadowPipelineDescriptor.sampleCount = 1 /*kSampleCount*/;
    shadowPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatR32Float;
    shadowPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
    NSError *error = nil;
    _shadowPipelineState = [self.device newRenderPipelineStateWithDescriptor:shadowPipelineDescriptor
                                                                       error:&error];
}

- (void)makePipelineShadowState
{
    return [self makePipelineShadowState:@"vertex_simple"];
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
    [self makePipelineState];
    [self makeDepthStencilState];
}


- (std::vector<NuoRayMask>)maskBuffer
{
    NuoRayMask mask = kNuoRayMask_Disabled;
    if (_enabled)
    {
        mask = self.hasTransparency ? kNuoRayMask_Translucent :
                                      kNuoRayMask_Opaque;
    }
    
    const size_t indicesNumber = _rawModel->GetIndicesNumber();
    const size_t bufferSize = indicesNumber / 3;
    
    std::vector<NuoRayMask> oneBuffer;
    oneBuffer.resize(bufferSize);
    std::fill(oneBuffer.begin(), oneBuffer.end(), mask);
    
    for (size_t i = 0; i < bufferSize; ++i)
    {
        NuoMaterial material = _rawModel->GetMaterial(i);
        if (material.id != -1 && material.illum == 0)
            oneBuffer[i] = kNuoRayMask_Illuminating;
    }
    
    return oneBuffer;
}



- (void)updateUniform:(id<NuoRenderInFlight>)inFlight withTransform:(const NuoMatrixFloat44&)transform
{
    NuoMatrixFloat44 transformWorld = transform * self.meshTransform;
    
    NuoMeshUniforms uniforms;
    uniforms.transform = transformWorld._m;
    uniforms.normalTransform = NuoMatrixExtractLinear(transformWorld)._m;
    
    [_transformBuffers updateBufferWithInFlight:inFlight withContent:&uniforms];
}



- (void)drawMesh:(NuoRenderPassEncoder*)renderPass
{
    [renderPass pushParameterState:@"NuoMesh"];
    
    [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderPass setRenderPipelineState:_renderPipelineState];
    [renderPass setDepthStencilState:_depthStencilState];
    
    uint rotationIndex = _shadowPipelineState ? 3 : 2;
    
    [renderPass setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
    [renderPass setVertexBufferSwapChain:_transformBuffers offset:0 atIndex:rotationIndex];
    [renderPass drawWithIndices:_indexBuffer];
    
    [renderPass popParameterState];
}


- (void)drawScreenSpace:(NuoRenderPassEncoder*)renderPass
{
    [renderPass pushParameterState:@"Mesh Screen Space"];
    
    [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderPass setRenderPipelineState:_screenSpacePipelineState];
    [renderPass setDepthStencilState:_depthStencilState];
    
    uint rotationIndex = _shadowPipelineState ? 3 : 2;
    
    [renderPass setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
    [renderPass setVertexBufferSwapChain:_transformBuffers offset:0 atIndex:rotationIndex];
    [renderPass drawWithIndices:_indexBuffer];
    
    [renderPass popParameterState];
}


- (void)drawShadow:(NuoRenderPassEncoder*)renderPass
{
    if (_shadowPipelineState)
    {
        [renderPass pushParameterState:@"Mesh Shadow"];
        
        [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
        [renderPass setRenderPipelineState:_shadowPipelineState];
        [renderPass setDepthStencilState:_depthStencilState];
        
        [renderPass setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
        [renderPass setVertexBufferSwapChain:_transformBuffers offset:0 atIndex:2];
        [renderPass drawWithIndices:_indexBuffer];
        
        [renderPass popParameterState];
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
    const NuoBounds& bounds = _boundsLocal.boundingBox;
    _transformPoise = NuoMatrixTranslation(- bounds._center);
}


+ (void)updatePrivateBuffer:(id<MTLBuffer>)buffer
           withCommandQueue:(id<MTLCommandQueue>)commandQueue
                   withData:(void*)data withSize:(size_t)size
{
    id<MTLBuffer> sharedBuffer = [commandQueue.device newBufferWithLength:size
                                                            options:MTLResourceStorageModeShared];
    memcpy(sharedBuffer.contents, data, size);
    
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    id<MTLBlitCommandEncoder> encoder = [commandBuffer blitCommandEncoder];
    
    [encoder copyFromBuffer:sharedBuffer sourceOffset:0
                   toBuffer:buffer destinationOffset:0
                       size:size];
    
    [encoder endEncoding];
    [commandBuffer commit];
}


@end





NuoMesh* CreateMesh(const NuoModelOption& options,
                    id<MTLCommandQueue> commandQueue,
                    const std::shared_ptr<NuoModelBase> model)
{
    NuoMesh* resultMesh = nil;
    bool textured = options._textured && !model->GetTexturePathDiffuse().empty();
    
    if (!textured && !options._basicMaterialized)
    {
        NuoMesh* mesh = [[NuoMesh alloc] initWithCommandQueue:commandQueue
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
        
        NuoMeshTextured* mesh = [[NuoMeshTextured alloc] initWithCommandQueue:commandQueue
                                                     withVerticesBuffer:model->Ptr()
                                                             withLength:model->Length()
                                                            withIndices:model->IndicesPtr()
                                                             withLength:model->IndicesLength()];
        
        [mesh makeTexture:modelTexturePath checkTransparency:checkTransparency];
        
        resultMesh = mesh;
    }
    else if (textured && options._basicMaterialized)
    {
        NSString* modelTexturePath = [NSString stringWithUTF8String:model->GetTexturePathDiffuse().c_str()];
        BOOL embeddedAlpha = options._textureEmbedMaterialTransparency;
        
        NuoMeshTexMatieraled* mesh = [[NuoMeshTexMatieraled alloc] initWithCommandQueue:commandQueue
                                                                     withVerticesBuffer:model->Ptr()
                                                                             withLength:model->Length()
                                                                            withIndices:model->IndicesPtr()
                                                                             withLength:model->IndicesLength()];
        
        [mesh makeTexture:modelTexturePath checkTransparency:embeddedAlpha];
        
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
        NuoMeshMatieraled* mesh = [[NuoMeshMatieraled alloc] initWithCommandQueue:commandQueue
                                                               withVerticesBuffer:model->Ptr()
                                                                       withLength:model->Length()
                                                                      withIndices:model->IndicesPtr()
                                                                       withLength:model->IndicesLength()];
        
        [mesh setTransparency:model->HasTransparent()];
        [mesh setPhysicallyReflection:options._physicallyReflection];
        
        resultMesh = mesh;
    }
    
    [resultMesh setRawModel:model];
    [resultMesh makeGPUStates];
    return resultMesh;
}


