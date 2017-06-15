#import "ModelViewerRenderer.h"

#import "NuoUniforms.h"

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#import <simd/simd.h>

#include "NuoTypes.h"
#include "NuoMeshCompound.h"
#include "NuoBoardMesh.h"
#include "NuoCubeMesh.h"
#include "NuoRenderPassTarget.h"
#include "NuoMathUtilities.h"
#include "NuoModelBase.h"
#include "NuoModelLoader.h"
#include "NuoTableExporter.h"

#include "NuoLua.h"

#import "NuoLightSource.h"
#import "NuoShadowMapRenderer.h"

@interface ModelRenderer ()


@property (nonatomic, weak) NuoMeshCompound* mainModelMesh;
@property (nonatomic, strong) NSMutableArray<NuoBoardMesh*>* boardMeshes;

@property (nonatomic, weak) NuoMesh* selectedMesh;
@property (nonatomic, strong) NSMutableArray<NuoMesh*>* meshes;

@property (assign) matrix_float4x4 projection;
@property (strong) NSArray<id<MTLBuffer>>* transUniformBuffers;
@property (strong) NSArray<id<MTLBuffer>>* lightCastBuffers;
@property (strong) NSArray<id<MTLBuffer>>* lightingUniformBuffers;
@property (strong) id<MTLBuffer> modelCharacterUnfiromBuffer;

@property (nonatomic, readonly) id<MTLSamplerState> shadowMapSamplerState;


@property (strong) NuoModelLoader* modelLoader;


@end



@implementation ModelRenderer
{
    NuoShadowMapRenderer* _shadowMapRenderer[2];
}



- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if ((self = [super init]))
    {
        self.device = device;
        
        [self makeResources];
        
        _modelOptions = [NuoMeshOption new];
        _cullEnabled = YES;
        _fieldOfView = (2 * M_PI) / 8;
        
        _shadowMapRenderer[0] = [[NuoShadowMapRenderer alloc] initWithDevice:device withName:@"Shadow 0"];
        _shadowMapRenderer[1] = [[NuoShadowMapRenderer alloc] initWithDevice:device withName:@"Shadow 1"];
        
        _meshes = [NSMutableArray new];
        _boardMeshes = [NSMutableArray new];
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

    [_mainModelMesh centerMesh];
    
    // move model from camera for a default distance (3 times of r)
    //
    float radius = _mainModelMesh.boundingSphere.radius;
    const float defaultDistance = - 3.0 * radius;
    const vector_float3 defaultDistanceVec = { 0, 0, defaultDistance };
    [_mainModelMesh setTransformTranslate:matrix_translation(defaultDistanceVec)];
}


- (void)createMeshs:(id<MTLCommandQueue>)commandQueue
{
    NuoMeshCompound* mesh = [_modelLoader createMeshsWithOptions:_modelOptions
                                                      withDevice:self.device
                                                withCommandQueue:commandQueue];

    // put the main model at the end of the draw queue,
    // for now it is the only one has transparency
    //
    
    BOOL haveReplaced = NO;
    for (NSUInteger i = 0; i < _meshes.count; ++i)
    {
        if (_meshes[i] == _mainModelMesh)
        {
            _meshes[i] = mesh;
            haveReplaced = YES;
        }
    }
    
    if (!haveReplaced)
        [_meshes addObject:mesh];
    
    _mainModelMesh = mesh;
    _selectedMesh = mesh;
}


- (NuoBoardMesh*)createBoard:(CGSize)size
{
    std::shared_ptr<NuoModelBoard> modelBoard(new NuoModelBoard(size.width, size.height, 0.001));
    modelBoard->CreateBuffer();
    NuoBoardMesh* boardMesh = CreateBoardMesh(self.device, modelBoard, [_modelOptions basicMaterialized]);
    
    float radius = boardMesh.boundingSphere.radius;
    const float defaultDistance = - 3.0 * radius;
    const vector_float3 defaultDistanceVec = { 0, 0, defaultDistance };
    [boardMesh setTransformTranslate:matrix_translation(defaultDistanceVec)];
    [_boardMeshes addObject:boardMesh];
    
    // boards are all opaque so they are drawn first
    //
    [_meshes insertObject:boardMesh atIndex:0];
    
    return boardMesh;
}



- (void)removeAllBoards
{
    for (NuoMesh* mesh in _boardMeshes)
        [_meshes removeObject:mesh];

    [_boardMeshes removeAllObjects];
}


- (NuoMeshCompound*)mainModelMesh
{
    return _mainModelMesh;
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
        exporter.SetMatrix(_mainModelMesh.transformPoise);
        exporter.EndEntry(true);
    }
    
    {
        exporter.StartEntry("translationMatrix");
        exporter.SetMatrix(_mainModelMesh.transformTranslate);
        exporter.EndEntry(true);
    }
    
    {
        exporter.StartEntry("boards");
        exporter.StartTable();
        
        size_t meshIndex = 0;
        
        for (NuoBoardMesh* boardMesh in _boardMeshes)
        {
            exporter.StartArrayIndex(++meshIndex);
            exporter.StartTable();
            
            {
                exporter.StartEntry("dimensions");
                exporter.StartTable();
                {
                    NuoCoord* dimension = boardMesh.dimensions;
                    exporter.StartEntry("width");
                    exporter.SetEntryValueFloat(dimension.x);
                    exporter.EndEntry(false);
                    exporter.StartEntry("height");
                    exporter.SetEntryValueFloat(dimension.y);
                    exporter.EndEntry(false);
                    exporter.StartEntry("thickness");
                    exporter.SetEntryValueFloat(dimension.z);
                    exporter.EndEntry(false);
                }
                exporter.EndTable();
                exporter.EndEntry(true);
                
                exporter.StartEntry("translationMatrix");
                exporter.SetMatrix(boardMesh.transformTranslate);
                exporter.EndEntry(true);
                
                exporter.StartEntry("rotationMatrix");
                exporter.SetMatrix(boardMesh.transformPoise);
                exporter.EndEntry(true);
            }
            
            exporter.EndTable();
            exporter.EndEntry(true);
        }
        
        exporter.EndTable();
        exporter.EndEntry(true);
    }
    
    {
        exporter.StartEntry("view");
        exporter.StartTable();
        
        {
            exporter.StartEntry("FOV");
            exporter.SetEntryValueFloat(_fieldOfView);
            exporter.EndEntry(false);
        }
        
        exporter.EndTable();
        exporter.EndEntry(true);
        
        exporter.StartEntry("models");
        exporter.StartTable();
        
        size_t index = 0;
        
        for (NuoMesh* meshItem in _mainModelMesh.meshes)
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
            
            NuoLightSource* light = _lights[lightIndex];
            
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
    [_mainModelMesh setTransformPoise:[lua getMatrixFromTable:-1]];
    [lua removeField];
    
    [lua getField:@"translationMatrix" fromTable:-1];
    if (![lua isNil:-1])
        [_mainModelMesh setTransformTranslate:[lua getMatrixFromTable:-1]];
    [lua removeField];
    
    [lua getField:@"view" fromTable:-1];
    _fieldOfView = [lua getFieldAsNumber:@"FOV" fromTable:-1];
    [lua removeField];
    
    [lua getField:@"models" fromTable:-1];
    
    size_t length = [lua getArraySize:-1];
    size_t passedModel = 0;
    
    for (size_t i = 0; i < length; ++i)
    {
        [lua getItem:(int)(i + 1) fromTable:-1];
        NSString* name = [lua getFieldAsString:@"name" fromTable:-1];
        for (size_t i = passedModel; i < _mainModelMesh.meshes.count; ++i)
        {
            NuoMesh* mesh = _mainModelMesh.meshes[i];
            
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
    
    [lua getField:@"boards" fromTable:-1];
    
    length = [lua getArraySize:-1];
    if (length > 0)
        [self removeAllBoards];
    
    for (size_t i = 0; i < length; ++i)
    {
        [lua getItem:(int)(i + 1) fromTable:-1];
        
        float width, height, thickness;
        {
            [lua getField:@"dimensions" fromTable:-1];
            
            width = [lua getFieldAsNumber:@"width" fromTable:-1];
            height = [lua getFieldAsNumber:@"height" fromTable:-1];
            thickness = [lua getFieldAsNumber:@"thickness" fromTable:-1];
            
            [lua removeField];
        }
        
        NuoBoardMesh* boardMesh = [self createBoard:CGSizeMake(width, height)];
        [lua getField:@"rotationMatrix" fromTable:-1];
        [boardMesh setTransformPoise:[lua getMatrixFromTable:-1]];
        [lua removeField];
        
        [lua getField:@"translationMatrix" fromTable:-1];
        [boardMesh setTransformTranslate:[lua getMatrixFromTable:-1]];
        [lua removeField];
        
        [lua removeField];
    }
    
    [lua removeField];
    
    [lua getField:@"lights" fromTable:-1];
    _ambientDensity = [lua getFieldAsNumber:@"ambient" fromTable:-1];
    [lua removeField];
}


- (void)setModelOptions:(NuoMeshOption *)modelOptions
       withCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    _modelOptions = modelOptions;
    
    if (_modelLoader)
    {
        matrix_float4x4 originalPoise = _mainModelMesh.transformPoise;
        matrix_float4x4 originalTrans = _mainModelMesh.transformTranslate;
        
        [self createMeshs:commandQueue];
        
        _mainModelMesh.transformPoise = originalPoise;
        _mainModelMesh.transformTranslate = originalTrans;
    }
    
    for (NuoBoardMesh* board in _boardMeshes)
    {
        board.shadowOverlayOnly = [modelOptions basicMaterialized];
        [board makePipelineState:[board makePipelineStateDescriptor]];
    }
}


- (void)makeResources
{
    id<MTLBuffer> modelBuffers[kInFlightBufferCount];
    id<MTLBuffer> lightingBuffers[kInFlightBufferCount];
    id<MTLBuffer> lightCastModelBuffers[kInFlightBufferCount];
    
    for (size_t i = 0; i < kInFlightBufferCount; ++i)
    {
        modelBuffers[i] = [self.device newBufferWithLength:sizeof(NuoUniforms)
                                                   options:MTLResourceOptionCPUCacheModeDefault];
        lightingBuffers[i] = [self.device newBufferWithLength:sizeof(LightUniform)
                                                      options:MTLResourceOptionCPUCacheModeDefault];
        lightCastModelBuffers[i] = [self.device newBufferWithLength:sizeof(LightVertexUniforms)
                                                        options:MTLResourceOptionCPUCacheModeDefault];
        
    }
    
    _transUniformBuffers = [[NSArray alloc] initWithObjects:modelBuffers count:kInFlightBufferCount];
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

- (void)updateUniformsForView:(unsigned int)inFlight
{
    // accumulate delta rotation into matrix
    //
    _selectedMesh.transformPoise = matrix_rotation_append(_selectedMesh.transformPoise, _rotationXDelta, _rotationYDelta);
    _rotationXDelta = 0;
    _rotationYDelta = 0;
    
    float radius = _selectedMesh.boundingSphere.radius;
    
    // simply using "z" works until the view matrix is no longer an identitiy
    //
    float distance = _selectedMesh.boundingSphere.center.z;
    
    const float distanceDelta = _zoomDelta * radius / 10.0f;
    const float cameraDistance = distanceDelta + distance;
    const float bilateralFactor = cameraDistance / 750.0f;
    _zoomDelta = 0;
    
    const float doTransX = _transXDelta * bilateralFactor;
    const float doTransY = _transYDelta * bilateralFactor;
    _transXDelta = 0;
    _transYDelta = 0;
    
    const vector_float3 translation =
    {
        doTransX, doTransY,
        distanceDelta
    };
    
    float sceneRadius = 0;
    float sceneCenter = 0;
    NuoBoundingSphere* sceneSphere = nil;
    for (NuoMesh* mesh in _meshes)
    {
        if (!sceneSphere)
            sceneSphere = mesh.boundingSphere;
        else
            sceneSphere = [sceneSphere unionWith:mesh.boundingSphere];
    }
    sceneRadius = sceneSphere.radius;
    sceneCenter = sceneSphere.center.z;

    const matrix_float4x4 transMatrix = matrix_multiply(matrix_translation(translation),
                                                       _selectedMesh.transformTranslate);
    
    float maxSpan = sceneRadius * 2.0;
    const CGSize drawableSize = self.renderTarget.drawableSize;
    const float aspect = drawableSize.width / drawableSize.height;
    float near = -sceneCenter - sceneRadius + 0.01;
    float far = near + maxSpan + 0.02;
    near = std::max<float>(0.001, near);
    far = std::max<float>(near + 0.001, far);
    _projection = matrix_perspective(aspect, _fieldOfView, near, far);

    NuoUniforms uniforms;
    uniforms.viewMatrix = matrix_identity_float4x4;
    uniforms.viewProjectionMatrix = matrix_multiply(_projection, uniforms.viewMatrix);

    memcpy([self.transUniformBuffers[inFlight] contents], &uniforms, sizeof(uniforms));
    
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
    
    [_selectedMesh setTransformTranslate:transMatrix];
    
    for (NuoMesh* mesh in _meshes)
        [mesh updateUniform:inFlight withTransform:matrix_identity_float4x4];
    
    if (_cubeMesh)
    {
        const matrix_float4x4 projectionMatrixForCube = matrix_perspective(aspect, _fieldOfView, 0.3, 2.0);
        [_cubeMesh setProjectionMatrix:projectionMatrixForCube];
        [_cubeMesh updateUniform:inFlight withTransform:matrix_identity_float4x4];
    }
}

- (void)predrawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
               withInFlightIndex:(unsigned int)inFlight
{
    [self updateUniformsForView:inFlight];
    
    // generate shadow map
    //
    for (unsigned int i = 0; i < 2 /* for two light sources only */; ++i)
    {
        _shadowMapRenderer[i].meshes = _meshes;
        _shadowMapRenderer[i].lightSource = _lights[i];
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
    
    [renderPass setVertexBuffer:self.transUniformBuffers[inFlight] offset:0 atIndex:1];
    [renderPass setVertexBuffer:_lightCastBuffers[inFlight] offset:0 atIndex:2];
    
    [renderPass setFragmentBuffer:self.lightingUniformBuffers[inFlight] offset:0 atIndex:0];
    [renderPass setFragmentBuffer:self.modelCharacterUnfiromBuffer offset:0 atIndex:1];
    [renderPass setFragmentTexture:_shadowMapRenderer[0].renderTarget.targetTexture atIndex:0];
    [renderPass setFragmentTexture:_shadowMapRenderer[1].renderTarget.targetTexture atIndex:1];
    [renderPass setFragmentSamplerState:_shadowMapSamplerState atIndex:0];
    
    for (NuoMesh* mesh in _meshes)
    {
        [mesh setCullEnabled:_cullEnabled];
        [mesh drawMesh:renderPass indexBuffer:inFlight];
    }
    
    [renderPass endEncoding];
}


- (void)selectMeshWithScreen:(CGPoint)point
{
    float distance = CGFLOAT_MAX;
    
    for (NuoMesh* mesh in _meshes)
    {
        NuoCoord* center = mesh.boundingSphere.center;
        vector_float4 centerVec = { center.x, center.y, center.z, 1.0 };
        vector_float4 centerProjected = matrix_multiply(_projection, centerVec);
        vector_float2 centerOnScreen = centerProjected.xy / centerProjected.w;
        
        vector_float2 normalized;
        CGSize drawableSize = self.renderTarget.drawableSize;
        float scale = [[NSScreen mainScreen] backingScaleFactor];
        normalized.x = (point.x * scale) / drawableSize.width * 2.0 - 1.0;
        normalized.y = (point.y * scale) / drawableSize.height * 2.0 - 1.0;
        
        float currentDistance = vector_distance(normalized, centerOnScreen);
        if (currentDistance < distance)
        {
            distance = currentDistance;
            _selectedMesh = mesh;
        }
    }
}

@end
