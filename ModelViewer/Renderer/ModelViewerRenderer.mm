#import "ModelViewerRenderer.h"

#import "NuoUniforms.h"
#import "NuoMeshBounds.h"

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

#include "NuoTypes.h"
#include "NuoMeshCompound.h"
#include "NuoBoardMesh.h"
#include "NuoCubeMesh.h"
#include "NuoBackdropMesh.h"
#include "NuoRenderPassTarget.h"
#include "NuoModelBase.h"
#include "NuoModelLoader.h"
#include "NuoTableExporter.h"
#include "NuoPackage.h"

#include "NuoMathVector.h"

#include "NuoLua.h"

#import "NuoLightSource.h"
#import "NuoShadowMapRenderer.h"
#import "NuoDeferredRenderer.h"
#import "NuoDirectoryUtils.h"
#import "NuoModelLoaderGPU.h"


@interface ModelRenderer ()


@property (nonatomic, weak) NuoMeshCompound* mainModelMesh;
@property (nonatomic, strong) NSMutableArray<NuoBoardMesh*>* boardMeshes;

@property (nonatomic, weak) NuoMesh* selectedMesh;
@property (nonatomic, strong) NSMutableArray<NuoMesh*>* meshes;

// transform data. "viewRotation" is relative to the scene's center
//
@property (assign) NuoMatrixFloat44 viewRotation;
@property (assign) NuoMatrixFloat44 viewTranslation;
@property (assign) NuoMatrixFloat44 projection;

// need store the center of a snapshot of the scene as the meshes in the scene
// keep moving
//
@property (assign) NuoVectorFloat3 sceneCenter;

@property (strong) NuoModelLoaderGPU* modelLoader;


@end



@implementation ModelRenderer
{
    // per-frame GPU buffers (confirm to protocol NuoMeshSceneParametersProvider)
    //
    NSArray<id<MTLBuffer>>* _transUniformBuffers;
    NSArray<id<MTLBuffer>>* _lightCastBuffers;
    NSArray<id<MTLBuffer>>* _lightingUniformBuffers;
    id<MTLBuffer> _modelCharacterUnfiromBuffer;
    
    NuoShadowMapRenderer* _shadowMapRenderer[2];
    NuoRenderPassTarget* _immediateTarget;
    NuoDeferredRenderer* _deferredRenderer;
}



- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    if ((self = [super initWithCommandQueue:commandQueue]))
    {
        [self makeResources];
        
        _modelOptions = [NuoMeshOption new];
        _cullEnabled = YES;
        _fieldOfView = (2 * M_PI) / 8;
        
        _shadowMapRenderer[0] = [[NuoShadowMapRenderer alloc] initWithCommandQueue:commandQueue withName:@"Shadow 0"];
        _shadowMapRenderer[1] = [[NuoShadowMapRenderer alloc] initWithCommandQueue:commandQueue withName:@"Shadow 1"];
        
        _immediateTarget = [[NuoRenderPassTarget alloc] initWithCommandQueue:commandQueue
                                                             withPixelFormat:MTLPixelFormatBGRA8Unorm
                                                             withSampleCount:kSampleCount];
        _immediateTarget.name = @"immediate";
        _immediateTarget.manageTargetTexture = YES;
        _immediateTarget.sharedTargetTexture = NO;
        
        _deferredRenderer = [[NuoDeferredRenderer alloc] initWithCommandQueue:commandQueue withSceneParameter:self];
        
        _meshes = [NSMutableArray new];
        _boardMeshes = [NSMutableArray new];
        
        _viewRotation = NuoMatrixFloat44Identity;
        _viewTranslation = NuoMatrixFloat44Identity;
        
        self.paramsProvider = self;
    }

    return self;
}


- (void)setDrawableSize:(CGSize)drawableSize
{
    [super setDrawableSize:drawableSize];
    [_immediateTarget setDrawableSize:drawableSize];
    [_shadowMapRenderer[0] setDrawableSize:drawableSize];
    [_shadowMapRenderer[1] setDrawableSize:drawableSize];
    [_deferredRenderer setDrawableSize:drawableSize];
}


- (void)setAdvancedShaowEnabled:(BOOL)enabled
{
    for (NuoMesh* mesh in _meshes)
    {
        [mesh setShadowOptionPCSS:enabled];
        [mesh setShadowOptionPCF:enabled];
    }
}


- (void)setSampleCount:(NSUInteger)sampleCount
{
    // no calling to super. because of the deferred pass, the sample
    // count of the final target is always 1
    
    // no calling to shadow map render. they are not MSAA-ed
    
    [_immediateTarget setSampleCount:sampleCount];
    [_deferredRenderer setSampleCount:sampleCount];
    
    for (NuoMesh* mesh in _meshes)
        [mesh setSampleCount:sampleCount];
    
    [_cubeMesh setSampleCount:sampleCount];
}



- (void)setTransMode:(TransformMode)transMode
{
    _transMode = transMode;
    
    if (transMode == kTransformMode_View)
        [self caliberateSceneCenter];
}


- (void)setRenderTarget:(NuoRenderPassTarget *)renderTarget
{
    [super setRenderTarget:renderTarget];
    [_shadowMapRenderer[0].renderTarget setSampleCount:1/*renderTarget.sampleCount*/];
    [_shadowMapRenderer[1].renderTarget setSampleCount:1/*renderTarget.sampleCount*/];
}


- (void)loadMesh:(NSString*)path withProgress:(NuoProgressFunction)progress
{
    std::shared_ptr<NuoModelLoader> loader = std::make_shared<NuoModelLoader>();
    loader->LoadModel(path.UTF8String);
    
    _modelLoader = [[NuoModelLoaderGPU alloc] initWithLoader:loader];
    
    [self createMeshsWithProgress:^(float progressPercent)
         {
             progress(progressPercent * (1 - 0.3) + 0.3);
         }];

    [_mainModelMesh centerMesh];
    
    // move model from camera for a default distance (3 times of r)
    //
    const NuoBounds bounds = [_mainModelMesh worldBounds:NuoMatrixFloat44Identity].boundingBox;
    const float radius = bounds.MaxDimension() / 2.0;
    const float defaultDistance = - 3.0 * radius;
    const NuoVectorFloat3 defaultDistanceVec(0, 0, defaultDistance);
    [_mainModelMesh setTransformTranslate:NuoMatrixTranslation(defaultDistanceVec)];
    
    [self caliberateSceneCenter];
}


- (BOOL)loadPackage:(NSString*)path withProgress:(NuoProgressFunction)progress
{
    const char* documentPath = pathForDocument();
    NSString* packageFolder = [NSString stringWithUTF8String:documentPath];
    packageFolder = [packageFolder stringByAppendingPathComponent:@"packaged_load"];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL exist = [fileManager fileExistsAtPath:packageFolder isDirectory:&isDir];
    if (exist)
        [fileManager removeItemAtPath:packageFolder error:nil];
    
    NuoPackage package;
    std::string objFile;
    size_t totalUncompressed = 0;
    size_t uncompressed = 0;
    
    NuoUnpackCallback checkCallback = [&totalUncompressed](std::string filename, void* buffer, size_t length)
    {
        totalUncompressed += length;
    };
    
    NuoUnpackCallback callback =
    [&objFile, &uncompressed, &totalUncompressed, progress, fileManager, packageFolder]
    (std::string filename, void* buffer, size_t length)
    {
        NSString* path = [NSString stringWithFormat:@"%@/%s", packageFolder, filename.c_str()];
        
        NSString* pathFolder = [path stringByDeletingLastPathComponent];
        if (![fileManager fileExistsAtPath:pathFolder])
            [fileManager createDirectoryAtPath:pathFolder withIntermediateDirectories:YES attributes:nil error:nil];
        
        NSData* data = [[NSData alloc] initWithBytesNoCopy:buffer length:length freeWhenDone:NO];
        [data writeToFile:path atomically:NO];
        
        if ([path hasSuffix:@".obj"])
            objFile = path.UTF8String;
        
        uncompressed += length;
        
        progress(uncompressed / (float)totalUncompressed * 0.3);
    };
    
    package.open(path.UTF8String);
    package.testFile(checkCallback);
    package.unpackFile(callback);
    
    if (objFile.empty())
    {
        return NO;
    }
    
    [self loadMesh:[NSString stringWithUTF8String:objFile.c_str()]
                        withProgress:^(float progressPercent)
                             {
                                 progress(progressPercent * 0.5 + 0.5);
                             }];
    
    return YES;
}


- (BOOL)isValidPack:(NSString*)path
{
    bool valid = false;
    
    NuoUnpackCallback callback = [&valid](std::string filename, void* buffer, size_t length)
    {
        if (valid)
            return;
        
        size_t extPos = filename.find(".obj");
        
        if (extPos == std::string::npos)
            return;
        
        size_t fileNameLength = filename.length();
        if (fileNameLength - extPos == 4)
        {
            size_t firstPos = filename.find("/");
            size_t lastPos = filename.find_last_of("/");
            
            if (firstPos != std::string::npos && firstPos == lastPos)
                valid = true;
        }
    };
    
    NuoPackage package;
    package.open(path.UTF8String);
    package.testFile(callback);
    
    return valid;
}


- (BOOL)hasMeshes
{
    return [_meshes count] != 0;
}


- (BOOL)viewTransformReset
{
    return _viewRotation.IsIdentity() &&
           _viewTranslation.IsIdentity();
}


- (void)createMeshsWithProgress:(NuoProgressFunction)progress
{
    NuoMeshCompound* mesh = [_modelLoader createMeshsWithOptions:_modelOptions
                                                withCommandQueue:self.commandQueue
                                                    withProgress:progress];

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


- (void)resetViewTransform
{
    _viewRotation = NuoMatrixFloat44Identity;
    _viewTranslation = NuoMatrixFloat44Identity;
}


- (NuoBoardMesh*)createBoard:(CGSize)size
{
    std::shared_ptr<NuoModelBoard> modelBoard(new NuoModelBoard(size.width, size.height, 0.001));
    modelBoard->CreateBuffer();
    NuoBoardMesh* boardMesh = CreateBoardMesh(self.commandQueue, modelBoard, [_modelOptions basicMaterialized]);
    
    const NuoBounds bounds = boardMesh.boundsLocal.boundingBox;
    const float radius = bounds.MaxDimension();
    const float defaultDistance = - 3.0 * radius;
    const NuoVectorFloat3 defaultDistanceVec(0, 0, defaultDistance);
    [boardMesh setTransformTranslate:NuoMatrixTranslation(defaultDistanceVec)];
    [_boardMeshes addObject:boardMesh];
    
    // boards are all opaque so they are drawn first
    //
    [_meshes insertObject:boardMesh atIndex:0];
    
    return boardMesh;
}


- (void)removeMesh:(NuoMesh*)mesh
{
    if (_meshes.count > 0)
    {
        [_meshes removeObject:mesh];
        
        if ([mesh isKindOfClass:[NuoBoardMesh class]])
        {
            NuoBoardMesh* boardMesh = (NuoBoardMesh*)mesh;
            [_boardMeshes removeObject:boardMesh];
        }
        
        if (mesh == _mainModelMesh)
        {
            _mainModelMesh = nil;
            _modelLoader = nil;
        }
        
        if (_meshes.count > 0 && mesh == _selectedMesh)
            _selectedMesh = _meshes[0];
        else
            _selectedMesh = nil;
    }
}


- (void)removeSelectedMesh
{
    [self removeMesh:_selectedMesh];
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
        exporter.StartEntry("viewMatrixRotation");
        exporter.SetMatrix(_viewRotation);
        exporter.EndEntry(true);
        
        exporter.StartEntry("viewMatrixTranslation");
        exporter.SetMatrix(_viewTranslation);
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
                    const NuoVectorFloat3& dimension = boardMesh.dimensions;
                    exporter.StartEntry("width");
                    exporter.SetEntryValueFloat(dimension.x());
                    exporter.EndEntry(false);
                    exporter.StartEntry("height");
                    exporter.SetEntryValueFloat(dimension.y());
                    exporter.EndEntry(false);
                    exporter.StartEntry("thickness");
                    exporter.SetEntryValueFloat(dimension.z());
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
            
            exporter.StartEntry("ambientParams");
            exporter.StartTable();
            
            {
                exporter.StartEntry("bias");
                exporter.SetEntryValueFloat(_deferredParameters.ambientOcclusionParams.bias);
                exporter.EndEntry(false);
                
                exporter.StartEntry("intensity");
                exporter.SetEntryValueFloat(_deferredParameters.ambientOcclusionParams.intensity);
                exporter.EndEntry(false);
                
                exporter.StartEntry("range");
                exporter.SetEntryValueFloat(_deferredParameters.ambientOcclusionParams.sampleRadius);
                exporter.EndEntry(false);
                
                exporter.StartEntry("scale");
                exporter.SetEntryValueFloat(_deferredParameters.ambientOcclusionParams.scale);
                exporter.EndEntry(false);
            }
            
            exporter.EndTable();
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
    lua->GetField("rotationMatrix", -1);
    [_mainModelMesh setTransformPoise:lua->GetMatrixFromTable(-1)];
    lua->RemoveField();
    
    lua->GetField("translationMatrix", -1);
    if (!lua->IsNil(-1))
        [_mainModelMesh setTransformTranslate:lua->GetMatrixFromTable(-1)];
    lua->RemoveField();
    
    // backward compatible the old "viewMatrix"
    lua->GetField("viewMatrix", -1);
    if (!lua->IsNil(-1))
        _viewRotation = lua->GetMatrixFromTable(-1);
    lua->RemoveField();
    
    lua->GetField("viewMatrixRotation", -1);
    if (!lua->IsNil(-1))
        _viewRotation = lua->GetMatrixFromTable(-1);
    lua->RemoveField();
    
    lua->GetField("viewMatrixTranslation", -1);
    if (!lua->IsNil(-1))
        _viewRotation = lua->GetMatrixFromTable(-1);
    lua->RemoveField();
    
    lua->GetField("view", -1);
    _fieldOfView = lua->GetFieldAsNumber("FOV", -1);
    lua->RemoveField();
    
    lua->GetField("models", -1);
    
    size_t length = lua->GetArraySize(-1);
    size_t passedModel = 0;
    
    for (size_t i = 0; i < length; ++i)
    {
        lua->GetItem((int)(i + 1), -1);
        const std::string name = lua->GetFieldAsString("name", -1);
        for (size_t i = passedModel; i < _mainModelMesh.meshes.count; ++i)
        {
            NuoMesh* mesh = _mainModelMesh.meshes[i];
            
            if (mesh.modelName.UTF8String == name)
            {
                [mesh setEnabled:lua->GetFieldAsBool("enabled", -1)];
                [mesh setReverseCommonCullMode:lua->GetFieldAsBool("cullModeReverse", -1)];
                [mesh setUnifiedOpacity:lua->GetFieldAsNumber("opacity", -1)];
                [mesh setSmoothConservative:lua->GetFieldAsBool("smoothConservative", -1)];
                [mesh smoothWithTolerance:lua->GetFieldAsNumber("smooth", -1)];
                
                passedModel = ++i;
                break;
            }
        }
        lua->RemoveField();
    }
    lua->RemoveField();
    
    lua->GetField("boards", -1);
    
    if (!lua->IsNil(-1))
    {
        length = lua->GetArraySize(-1);
        if (length > 0)
            [self removeAllBoards];
        
        for (size_t i = 0; i < length; ++i)
        {
            lua->GetItem((int)(i + 1), -1);
            
            float width, height, thickness;
            {
                lua->GetField("dimensions", -1);
                
                width = lua->GetFieldAsNumber("width", -1);
                height = lua->GetFieldAsNumber("height", -1);
                thickness = lua->GetFieldAsNumber("thickness", -1);
                
                lua->RemoveField();
            }
            
            NuoBoardMesh* boardMesh = [self createBoard:CGSizeMake(width, height)];
            lua->GetField("rotationMatrix", -1);
            [boardMesh setTransformPoise:lua->GetMatrixFromTable(-1)];
            lua->RemoveField();
            
            lua->GetField("translationMatrix", -1);
            [boardMesh setTransformTranslate:lua->GetMatrixFromTable(-1)];
            lua->RemoveField();
            
            lua->RemoveField();
        }
    }
    
    lua->RemoveField();
    
    lua->GetField("lights", -1);
    
    _ambientDensity = lua->GetFieldAsNumber("ambient", -1);
    
    {
        lua->GetField("ambientParams", -1);
        
        if (!lua->IsNil(-1))
        {
            NuoDeferredRenderUniforms params = _deferredParameters;
            params.ambientOcclusionParams.bias = lua->GetFieldAsNumber("bias", -1);
            params.ambientOcclusionParams.intensity = lua->GetFieldAsNumber("intensity", -1);
            params.ambientOcclusionParams.sampleRadius = lua->GetFieldAsNumber("range", -1);
            params.ambientOcclusionParams.scale = lua->GetFieldAsNumber("scale", -1);
            [self setDeferredParameters:params];
        }
        lua->RemoveField();
    }
    
    lua->RemoveField();
    
    [self caliberateSceneCenter];
}


- (void)setModelOptions:(NuoMeshOption *)modelOptions
           withProgress:(NuoProgressFunction)progress
{
    _modelOptions = modelOptions;
    
    if (_modelLoader)
    {
        NuoMatrixFloat44 originalPoise = _mainModelMesh.transformPoise;
        NuoMatrixFloat44 originalTrans = _mainModelMesh.transformTranslate;
        
        [self createMeshsWithProgress:progress];
        
        _mainModelMesh.transformPoise = originalPoise;
        _mainModelMesh.transformTranslate = originalTrans;
    }
    
    for (NuoBoardMesh* board in _boardMeshes)
    {
        board.shadowOverlayOnly = [modelOptions basicMaterialized];
        [board makePipelineState];
    }
}


- (void)setDeferredParameters:(NuoDeferredRenderUniforms)deferredParameters
{
    _deferredParameters = deferredParameters;
    [_deferredRenderer setParameters:&deferredParameters];
}


- (void)makeResources
{
    id<MTLBuffer> modelBuffers[kInFlightBufferCount];
    id<MTLBuffer> lightingBuffers[kInFlightBufferCount];
    id<MTLBuffer> lightCastModelBuffers[kInFlightBufferCount];
    
    for (size_t i = 0; i < kInFlightBufferCount; ++i)
    {
        modelBuffers[i] = [self.commandQueue.device newBufferWithLength:sizeof(NuoUniforms)
                                                   options:MTLResourceStorageModeManaged];
        lightingBuffers[i] = [self.commandQueue.device newBufferWithLength:sizeof(NuoLightUniforms)
                                                      options:MTLResourceStorageModeManaged];
        lightCastModelBuffers[i] = [self.commandQueue.device newBufferWithLength:sizeof(NuoLightVertexUniforms)
                                                        options:MTLResourceStorageModeManaged];
        
    }
    
    _transUniformBuffers = [[NSArray alloc] initWithObjects:modelBuffers count:kInFlightBufferCount];
    _lightingUniformBuffers = [[NSArray alloc] initWithObjects:lightingBuffers count:kInFlightBufferCount];
    _lightCastBuffers = [[NSArray alloc] initWithObjects:lightCastModelBuffers count:kInFlightBufferCount];
    
    NuoModelCharacterUniforms modelCharacter;
    modelCharacter.opacity = 1.0f;
    _modelCharacterUnfiromBuffer = [self.commandQueue.device newBufferWithLength:sizeof(NuoModelCharacterUniforms)
                                                                         options:MTLResourceOptionCPUCacheModeDefault];
    memcpy([_modelCharacterUnfiromBuffer contents], &modelCharacter, sizeof(NuoModelCharacterUniforms));
}

- (void)handleDeltaPosition
{
    if (_transMode == kTransformMode_Model && [self viewTransformReset])
        [self caliberateSceneCenter];
    
    NuoBounds bounds;
    if (_selectedMesh)
        bounds = [_selectedMesh worldBounds:[self viewMatrix]].boundingBox;
    float radius = bounds.MaxDimension();
    
    // simply using "z" works until the view matrix is no longer an identitiy
    //
    float distance = bounds._center.z();
    
    const float distanceDelta = _zoomDelta * radius / 10.0f;
    const float cameraDistance = distanceDelta + distance;
    const float bilateralFactor = cameraDistance / 750.0f;
    _zoomDelta = 0;
    
    // accumulate delta rotation into matrix
    //
    if (_transMode == kTransformMode_View)
        _viewRotation = NuoMatrixRotationAppend(_viewRotation, _rotationXDelta, _rotationYDelta);
    else
        _selectedMesh.transformPoise = NuoMatrixRotationAppend(_selectedMesh.transformPoise, _rotationXDelta, _rotationYDelta);
    
    _rotationXDelta = 0;
    _rotationYDelta = 0;
    
    // accumulate delta translation into matrix
    //
    const float doTransX = _transXDelta * bilateralFactor;
    const float doTransY = _transYDelta * bilateralFactor;
    _transXDelta = 0;
    _transYDelta = 0;
    
    const NuoVectorFloat3 translation
    (
        doTransX, doTransY,
        distanceDelta
    );
    
    NuoMatrixFloat44 transMatrix = _selectedMesh.transformTranslate;
    if (_transMode == kTransformMode_View)
    {
        _viewTranslation = NuoMatrixTranslation(translation) * _viewTranslation;
    }
    else
    {
        transMatrix = NuoMatrixTranslation(translation) * transMatrix;
        [_selectedMesh setTransformTranslate:transMatrix];
    }
}


- (void)caliberateSceneCenter
{
    NuoBounds bounds;
    bool head = true;
    
    for (NuoMesh* mesh in _meshes)
    {
        if (head)
        {
            bounds = [mesh worldBounds:NuoMatrixFloat44Identity].boundingBox;
            head = false;
        }
        else
        {
            bounds = bounds.Union([mesh worldBounds:NuoMatrixFloat44Identity].boundingBox);
        }
    }
    
    _sceneCenter = bounds._center;
}


- (NuoMatrixFloat44)viewMatrix
{
    // rotation is around the center of a previous scene snapshot
    //
    NuoMatrixFloat44 viewTrans = NuoMatrixRotationAround(_viewRotation, _sceneCenter);
    return _viewTranslation * viewTrans;
}


- (void)updateUniformsForView:(unsigned int)inFlight
{
    // move all delta position coming from the view's mouse/gesture into the matrix,
    // according to the transform mode (i.e. scene or mesh)
    //
    [self handleDeltaPosition];
    
    // rotation is around the center of a previous scene snapshot
    //
    NuoMatrixFloat44 viewTrans = [self viewMatrix];
    
    const CGSize drawableSize = self.renderTarget.drawableSize;
    const float aspect = drawableSize.width / drawableSize.height;
    
    // bounding box transform and determining the near/far
    //
    NuoBounds bounds;
    bool head = true;
    for (NuoMesh* mesh in _meshes)
    {
        if (head)
        {
            bounds = [mesh worldBounds:viewTrans].boundingBox;
            head = false;
        }
        else
        {
            bounds = bounds.Union([mesh worldBounds:viewTrans].boundingBox);
        }
    }

    float near = -bounds._center.z() - bounds._span.z() / 2.0 + 0.01;
    float far = near + bounds._span.z() + 0.02;
    near = std::max<float>(0.001, near);
    far = std::max<float>(near + 0.001, far);
    
    _projection = NuoMatrixPerspective(aspect, _fieldOfView, near, far);

    NuoUniforms uniforms;
    uniforms.viewMatrix = viewTrans._m;
    uniforms.viewProjectionMatrix = (_projection * viewTrans)._m;

    memcpy([self.transUniformBuffers[inFlight] contents], &uniforms, sizeof(uniforms));
    [self.transUniformBuffers[inFlight] didModifyRange:NSMakeRange(0, sizeof(uniforms))];
    
    NuoLightUniforms lighting;
    lighting.ambientDensity = _ambientDensity;
    for (unsigned int i = 0; i < 4; ++i)
    {
        const NuoMatrixFloat44 rotationMatrix = NuoMatrixRotation(_lights[i].lightingRotationX,
                                                                  _lights[i].lightingRotationY);
        
        NuoVectorFloat4 lightVector(0, 0, 1, 0);
        lightVector = rotationMatrix * lightVector;
        lighting.lightParams[i].direction = NuoVectorFloat4(lightVector.x(),
                                                            lightVector.y(),
                                                            lightVector.z(), 0.0)._vector;
        lighting.lightParams[i].density = _lights[i].lightingDensity;
        lighting.lightParams[i].spacular = _lights[i].lightingSpacular;
        
        if (i < 2)
        {
            lighting.shadowParams[i].soften = _lights[i].shadowSoften;
            lighting.shadowParams[i].bias = _lights[i].shadowBias;
            lighting.shadowParams[i].occluderRadius = _lights[i].shadowOccluderRadius;
        }
    }
    
    memcpy([self.lightingUniformBuffers[inFlight] contents], &lighting, sizeof(NuoLightUniforms));
    [self.lightingUniformBuffers[inFlight] didModifyRange:NSMakeRange(0, sizeof(NuoLightUniforms))];
    
    for (NuoMesh* mesh in _meshes)
    {
        [mesh updateUniform:inFlight withTransform:NuoMatrixFloat44Identity];
        [mesh setCullEnabled:_cullEnabled];
    }
    
    if (_cubeMesh)
    {
        const NuoMatrixFloat44 projectionMatrixForCube = NuoMatrixPerspective(aspect, _fieldOfView, 0.3, 2.0);
        [_cubeMesh setProjectionMatrix:projectionMatrixForCube];
        [_cubeMesh updateUniform:inFlight withTransform:NuoMatrixFloat44Identity];
    }
    
    if (_backdropMesh)
    {
        [_backdropMesh setScale:_backdropMesh.scale + _backdropScaleDelta];
        
        CGPoint translation = [_backdropMesh translation];
        translation.x += _backdropTransXDelta;
        translation.y += _backdropTransYDelta;
        [_backdropMesh setTranslation:translation];
        
        [_backdropMesh updateUniform:inFlight withDrawableSize:self.renderTarget.drawableSize];
        
        _backdropScaleDelta = 0.0;
        _backdropTransXDelta = 0.0;
        _backdropTransYDelta = 0.0;
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
    NuoLightVertexUniforms lightUniforms;
    lightUniforms.lightCastMatrix[0] = _shadowMapRenderer[0].lightCastMatrix._m;
    lightUniforms.lightCastMatrix[1] = _shadowMapRenderer[1].lightCastMatrix._m;
    memcpy([_lightCastBuffers[inFlight] contents], &lightUniforms, sizeof(lightUniforms));
    [_lightCastBuffers[inFlight] didModifyRange:NSMakeRange(0, sizeof(lightUniforms))];
    
    [_deferredRenderer setMeshes:_meshes];
    [_deferredRenderer predrawWithCommandBuffer:commandBuffer withInFlightIndex:inFlight];
}


- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    // get the target render pass and draw the scene
    //
    id<MTLRenderCommandEncoder> renderPass = [_immediateTarget retainRenderPassEndcoder:commandBuffer];
    if (!renderPass)
        return;
    
    renderPass.label = @"Scene Render Pass";
    
    if (_cubeMesh)
        [_cubeMesh drawMesh:renderPass indexBuffer:inFlight];
    
    [self setSceneBuffersTo:renderPass withInFlightIndex:inFlight];
    
    for (NuoMesh* mesh in _meshes)
    {
        if (mesh.enabled)
            [mesh drawMesh:renderPass indexBuffer:inFlight];
    }
    
    [_immediateTarget releaseRenderPassEndcoder];
    
    BOOL drawBackdrop = _backdropMesh && _backdropMesh.enabled;
    if (drawBackdrop)
    {
        id<MTLRenderCommandEncoder> deferredRenderPass = [self retainDefaultEncoder:commandBuffer];
        [_backdropMesh drawMesh:deferredRenderPass indexBuffer:inFlight];
    }
    
    [_deferredRenderer setRenderTarget:self.renderTarget];
    [_deferredRenderer setImmediateResult:_immediateTarget.targetTexture];
    [_deferredRenderer drawWithCommandBuffer:commandBuffer withInFlightIndex:inFlight];
    
    if (drawBackdrop)
    {
        [self releaseDefaultEncoder];
    }
}


- (void)selectMeshWithScreen:(CGPoint)point
{
    float distance = CGFLOAT_MAX;
    
    for (NuoMesh* mesh in _meshes)
    {
        NuoVectorFloat3 center = [mesh worldBounds:NuoMatrixFloat44Identity].boundingBox._center;
        NuoVectorFloat4 centerVec(center.x(), center.y(), center.z(), 1.0);
        NuoVectorFloat4 centerProjected = _projection * centerVec;
        NuoVectorFloat2 centerOnScreen = NuoVectorFloat2(centerProjected.x(), centerProjected.y()) / centerProjected.w();
        
        CGSize drawableSize = self.renderTarget.drawableSize;
        float scale = [[NSScreen mainScreen] backingScaleFactor];
        NuoVectorFloat2 normalized((point.x * scale) / drawableSize.width * 2.0 - 1.0,
                                   (point.y * scale) / drawableSize.height * 2.0 - 1.0);
        
        float currentDistance = NuoDistance(normalized, centerOnScreen);
        if (currentDistance < distance)
        {
            distance = currentDistance;
            _selectedMesh = mesh;
        }
    }
}


- (NSArray<NuoMesh*>*)cloneMeshesFor:(NuoMeshModeShaderParameter)mode
{
    NSMutableArray<NuoMesh*>* cloned = [NSMutableArray new];
    
    for (NuoMesh* mesh in _meshes)
    {
        NuoMesh* newMesh = [mesh cloneForMode:mode];
        [cloned addObject:newMesh];
    }
    
    return cloned;
}


- (void)setResolveDepth:(BOOL)resolveDepth
{
    [_immediateTarget setResolveDepth:resolveDepth];
}



#pragma mark -- Protocol NuoMeshSceneParametersProvider

- (NuoShadowMapRenderer*)shadowMapRenderer:(NSUInteger)index
{
    return _shadowMapRenderer[index];
}

- (NSArray<id<MTLBuffer>>*)lightCastBuffers
{
    return _lightCastBuffers;
}


- (NSArray<id<MTLBuffer>>*)lightingUniformBuffers
{
    return _lightingUniformBuffers;
}


- (id<MTLBuffer>)modelCharacterUnfiromBuffer
{
    return _modelCharacterUnfiromBuffer;
}


- (NSArray<id<MTLBuffer>>*)transUniformBuffers
{
    return _transUniformBuffers;
}


- (id<MTLTexture>)depthMap
{
    return _immediateTarget.depthTexture;
}



@end
