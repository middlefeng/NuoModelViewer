#import "ModelViewerRenderer.h"

#import "NuoUniforms.h"
#import "NuoMeshBounds.h"

#import "NuoCommandBuffer.h"
#import "NuoBufferSwapChain.h"
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

#include "NuoTypes.h"
#include "NuoMeshSceneRoot.h"
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

// sub renderers
//
#import "NuoRayAccelerateStructure.h"
#import "ModelRenderDelegate.h"
#import "ModelHybridRenderDelegate.h"
#import "ModelRayTracerDelegate.h"

#import "NuoDirectoryUtils.h"
#import "NuoModelLoaderGPU.h"
#import "ModelSceneParameters.h"

// inspect
//
#import "NuoCheckboardMesh.h"
#import "NuoInspectableMaster.h"


@interface ModelRenderer ()


@property (nonatomic, weak) NuoMeshCompound* mainModelMesh;
@property (nonatomic, strong) NSMutableArray<NuoBoardMesh*>* boardMeshes;

@property (nonatomic, weak) NuoMesh* selectedMesh;
@property (nonatomic, strong) NuoMeshSceneRoot* sceneRoot;

// transform data. "viewRotation" is relative to the scene's center
//
@property (assign) NuoMatrixFloat44 viewRotation;
@property (assign) NuoMatrixFloat44 viewTranslation;

// need store the center of a snapshot of the scene as the meshes in the scene
// keep moving
//
@property (assign) NuoVectorFloat3 sceneCenter;

@property (strong) NuoModelLoaderGPU* modelLoader;


@end



@implementation ModelRenderer
{
    NuoCheckboardMesh* _checkerboard;
    
    NuoRayAccelerateStructure* _rayAccelerator;
    BOOL _rayAcceleratorOutOfSync;
    BOOL _rayAcceleratorNeedRebuild;
    
    NuoAmbientUniformField _ambientParameters;
    id<ModelRenderDelegate> _renderDelegate;
    BOOL _rayTracingHybrid;
}


@dynamic fieldOfView;



- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    if (self = [super init])
    {
        self.commandQueue = commandQueue;
        
        _modelOptions = [NuoMeshOption new];
        
        _checkerboard = [[NuoCheckboardMesh alloc] initWithCommandQueue:commandQueue];
        
        _sceneRoot = [[NuoMeshSceneRoot alloc] init];
        _boardMeshes = [NSMutableArray new];
        
        _sceneParameters = [[ModelSceneParameters alloc] initWithDevice:commandQueue.device];
        _sceneParameters.sceneRoot = _sceneRoot;
        
        _viewRotation = NuoMatrixFloat44Identity;
        _viewTranslation = NuoMatrixFloat44Identity;
        
        _rayAccelerator = [[NuoRayAccelerateStructure alloc] initWithCommandQueue:commandQueue];
    }

    return self;
}


- (void)switchToHybrid
{
    if (_rayTracingHybrid && _renderDelegate)
        return;
    
    _renderDelegate = [[ModelHybridRenderDelegate alloc] initWithCommandQueue:self.commandQueue
                                                              withAccelerator:_rayAccelerator
                                                                withSceneRoot:_sceneRoot
                                                          withSceneParameters:_sceneParameters];
    
    _rayTracingHybrid = YES;
}


- (void)switchToRayTracing
{
    if (!_rayTracingHybrid && _renderDelegate)
        return;
    
    _renderDelegate = [[ModelRayTracerDelegate alloc] initWithCommandQueue:self.commandQueue
                                                           withAccelerator:_rayAccelerator
                                                             withSceneRoot:_sceneRoot];
        
    _rayTracingHybrid = NO;
}


- (void)setRayTracingRecordStatus:(RecordStatus)rayTracingRecordStatus
{
    _rayTracingRecordStatus = rayTracingRecordStatus;
    _renderDelegate.rayTracingRecordStatus = rayTracingRecordStatus;
}


- (void)beginUserInteract
{
    if (_rayTracingHybrid)
        _rayTracingRecordStatus = kRecord_Stop;
}


- (void)continueUserInteract
{
    if (!_rayTracingHybrid)
    {
        [self setRayTracingRecordStatus:kRecord_Stop];
        [self syncRayTracingBuffers];
        [self setRayTracingRecordStatus:_rayTracingRecordStatus];
    }
}


- (void)endUserInteract:(RecordStatus)recordStatus
{
    if (_rayTracingHybrid)
        _rayTracingRecordStatus = recordStatus;
}


- (void)setDrawableSize:(CGSize)drawableSize
{
    [super setDrawableSize:drawableSize];
    [_rayAccelerator setDrawableSize:drawableSize];
    
    [_renderDelegate setDrawableSize:drawableSize];
    [_sceneParameters setDrawableSize:drawableSize];
}


- (void)setFieldOfView:(float)fieldOfView
{
    [_sceneParameters setFieldOfView:fieldOfView];
    [_rayAccelerator setFieldOfView:fieldOfView];
}



- (float)fieldOfView
{
    return [_sceneParameters fieldOfView];
}



- (void)setAdvancedShaowEnabled:(BOOL)enabled
{
    [_sceneRoot setShadowOptionPCSS:enabled];
    [_sceneRoot setShadowOptionPCF:enabled];
}


- (void)setSampleCount:(NSUInteger)sampleCount
{
    // no calling to super. because of the deferred pass, the sample
    // count of the final target is always 1
    
    // no calling to shadow map render. they are not MSAA-ed
    // no calling to cube/backdrop render. they are not MSAA-ed
    
    [_renderDelegate setSampleCount:sampleCount];
    [_sceneRoot setSampleCount:sampleCount];
}



- (void)setTransMode:(TransformMode)transMode
{
    _transMode = transMode;
    
    if (transMode == kTransformMode_View)
        [self caliberateSceneCenter];
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
    return [_sceneRoot.meshes count] != 0;
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

    [_sceneRoot replaceMesh:_mainModelMesh with:mesh];
    
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
    [_sceneRoot addBoardObject:boardMesh];
    
    [self rebuildRayTracingBuffers];
    
    return boardMesh;
}


- (void)removeMesh:(NuoMesh*)mesh
{
    if (_sceneRoot.meshes.count > 0)
    {
        [_sceneRoot removeMesh:mesh];
        
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
        
        if (_sceneRoot.meshes.count > 0 && mesh == _selectedMesh)
            _selectedMesh = _sceneRoot.meshes[0];
        else
            _selectedMesh = nil;
        
        [self rebuildRayTracingBuffers];
    }
}


- (void)removeSelectedMesh
{
    [self removeMesh:_selectedMesh];
}



- (void)removeAllBoards
{
    for (NuoMesh* mesh in _boardMeshes)
        [_sceneRoot removeMesh:mesh];

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
            exporter.SetEntryValueFloat(self.fieldOfView);
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
                exporter.SetEntryValueFloat(light.lightingSpecular);
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
                exporter.SetEntryValueFloat(_ambientParameters.bias);
                exporter.EndEntry(false);
                
                exporter.StartEntry("intensity");
                exporter.SetEntryValueFloat(_ambientParameters.intensity);
                exporter.EndEntry(false);
                
                exporter.StartEntry("range");
                exporter.SetEntryValueFloat(_ambientParameters.sampleRadius);
                exporter.EndEntry(false);
                
                exporter.StartEntry("scale");
                exporter.SetEntryValueFloat(_ambientParameters.scale);
                exporter.EndEntry(false);
            }
            
            exporter.EndTable();
            exporter.EndEntry(true);
        }
        
        {
            exporter.StartEntry("illumination");
            exporter.SetEntryValueFloat(_illuminationStrength);
            exporter.EndEntry(false);
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
        _viewTranslation = lua->GetMatrixFromTable(-1);
    lua->RemoveField();
    
    lua->GetField("view", -1);
    self.fieldOfView = lua->GetFieldAsNumber("FOV", -1);
    lua->RemoveField();
    
    lua->GetField("models", -1);
    
    const size_t length = lua->GetArraySize(-1);
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
        const size_t length = lua->GetArraySize(-1);
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
    
    self.ambientDensity = lua->GetFieldAsNumber("ambient", -1);
    
    {
        lua->GetField("ambientParams", -1);
        
        if (!lua->IsNil(-1))
        {
            _ambientParameters.bias = lua->GetFieldAsNumber("bias", -1);
            _ambientParameters.intensity = lua->GetFieldAsNumber("intensity", -1);
            _ambientParameters.sampleRadius = lua->GetFieldAsNumber("range", -1);
            _ambientParameters.scale = lua->GetFieldAsNumber("scale", -1);
            [self setAmbientParameters:_ambientParameters];
        }
        lua->RemoveField();
    }
    
    {
        lua->GetField("illumination", -1);
        if (!lua->IsNil(-1))
            [self setIlluminationStrength:lua->GetFieldAsNumber("illumination", -2)];

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
        const NuoMatrixFloat44 originalPoise = _mainModelMesh.transformPoise;
        const NuoMatrixFloat44 originalTrans = _mainModelMesh.transformTranslate;
        
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


- (void)setAmbientDensity:(float)ambientDensity
{
    _ambientDensity = ambientDensity;
    _sceneParameters.ambient = NuoVectorFloat3(_ambientDensity,
                                               _ambientDensity,
                                               _ambientDensity);
}


- (void)setAmbientParameters:(const NuoAmbientUniformField&)ambientParameters
{
    _ambientParameters = ambientParameters;
    
    [_renderDelegate setAmbientParameters:ambientParameters];
    
    NuoVectorFloat3 ambient(_ambientDensity, _ambientDensity, _ambientDensity);
    [_renderDelegate setAmbient:ambient];
}


- (const NuoAmbientUniformField&)ambientParameters
{
    return _ambientParameters;
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
    
    if (_transMode == kTransformMode_View)
    {
        _viewTranslation = NuoMatrixTranslation(translation) * _viewTranslation;
    }
    else
    {
        const NuoMatrixFloat44 transMatrix = NuoMatrixTranslation(translation) * _selectedMesh.transformTranslate;
        [_selectedMesh setTransformTranslate:transMatrix];
    }
}


- (void)caliberateSceneCenter
{
    NuoBounds bounds = [_sceneRoot worldBounds:NuoMatrixFloat44Identity].boundingBox;
    _sceneCenter = bounds._center;
}


- (NuoMatrixFloat44)viewMatrix
{
    // rotation is around the center of a previous scene snapshot
    //
    const NuoMatrixFloat44 viewTrans = NuoMatrixRotationAround(_viewRotation, _sceneCenter);
    return _viewTranslation * viewTrans;
}


- (void)updateUniformsForView:(NuoCommandBuffer*)commandBuffer
{
    // move all delta position coming from the view's mouse/gesture into the matrix,
    // according to the transform mode (i.e. scene or mesh)
    //
    [self handleDeltaPosition];
    
    [_sceneParameters setViewMatrix:[self viewMatrix]];
    [_sceneParameters setLights:_lights];
    [_sceneParameters updateUniforms:commandBuffer];
    
    [_sceneRoot updateUniform:commandBuffer withTransform:NuoMatrixFloat44Identity];
    [_sceneRoot setCullEnabled:_sceneParameters.cullEnabled];
    
    if (_cubeMesh)
    {
        const CGSize& drawableSize = _sceneParameters.drawableSize;
        const float aspect = drawableSize.width / drawableSize.height;
        
        const NuoMatrixFloat44 projectionMatrixForCube = NuoMatrixPerspective(aspect, self.fieldOfView, 0.3, 2.0);
        [_cubeMesh setProjectionMatrix:projectionMatrixForCube];
        [_cubeMesh updateUniform:commandBuffer withTransform:NuoMatrixFloat44Identity];
    }
    
    if (_backdropMesh)
    {
        [_backdropMesh setScale:_backdropMesh.scale + _backdropScaleDelta];
        
        CGPoint translation = [_backdropMesh translation];
        translation.x += _backdropTransXDelta;
        translation.y += _backdropTransYDelta;
        [_backdropMesh setTranslation:translation];
        
        [_backdropMesh updateUniform:commandBuffer withDrawableSize:self.renderTarget.drawableSize];
        
        _backdropScaleDelta = 0.0;
        _backdropTransXDelta = 0.0;
        _backdropTransYDelta = 0.0;
    }
}

- (void)predrawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer
{
    [self updateUniformsForView:commandBuffer];
    
    _renderDelegate.rayTracingRecordStatus = _rayTracingRecordStatus;
    
    if (_rayTracingRecordStatus != kRecord_Stop)
    {
        // updat to the intersector accelerating sturcture
        
        if (_rayAcceleratorNeedRebuild)
            [_rayAccelerator setRoot:_sceneRoot];
        else if (_rayAcceleratorOutOfSync)
            [_rayAccelerator setRoot:_sceneRoot withCommandBuffer:commandBuffer];
        
        [_rayAccelerator setView:[self viewMatrix]];
        
        if (_rayAcceleratorOutOfSync)
        {
            [_renderDelegate setViewMatrix:[self viewMatrix]];
            [_renderDelegate setAmbient:_ambientDensity];
            [_renderDelegate setAmbientParameters:_ambientParameters];
            [_renderDelegate setIlluminationStrength:_illuminationStrength];
        }
    }
    
    [_renderDelegate setLights:_lights];
    [_renderDelegate setDelegateTarget:self.renderTarget];
    [_renderDelegate predrawWithCommandBuffer:commandBuffer
                         withRayStructChanged:_rayAcceleratorNeedRebuild
                        withRayStructAdjusted:_rayAcceleratorOutOfSync];
    
    if (_rayTracingRecordStatus != kRecord_Stop)
    {
        _rayAcceleratorNeedRebuild = NO;
        _rayAcceleratorOutOfSync = NO;
    }
}


- (void)drawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer
{
    [_renderDelegate drawWithCommandBufferPriorBackdrop:commandBuffer];
    
    // deferred rendering for the illumination
    
    NuoRenderPassEncoder* deferredRenderPass = [self retainDefaultEncoder:commandBuffer];
    
    if (_showCheckerboard)
        [_checkerboard drawMesh:deferredRenderPass];
    
    if (_cubeMesh)
        [_cubeMesh drawMesh:deferredRenderPass];
    
    BOOL drawBackdrop = _backdropMesh && _backdropMesh.enabled;
    if (drawBackdrop)
        [_backdropMesh drawMesh:deferredRenderPass];

    if (_mainModelMesh.enabled)
    {
        [deferredRenderPass pushParameterState:@"Deferred render"];
        
        [_renderDelegate drawWithCommandBuffer:commandBuffer];
        
        [deferredRenderPass popParameterState];
    }
    
    [self releaseDefaultEncoder];
}


- (void)selectMeshWithScreen:(CGPoint)point
{
    float distance = CGFLOAT_MAX;
    const float scale = [[NSScreen mainScreen] backingScaleFactor];
    const CGPoint scaledPoint = CGPointMake(point.x * scale, point.y * scale);
    
    const CGSize drawableSize = self.renderTarget.drawableSize;
    const NuoVectorFloat2 normalized(scaledPoint.x / drawableSize.width * 2.0 - 1.0,
                                     scaledPoint.y / drawableSize.height * 2.0 - 1.0);
    
    for (NuoMesh* mesh in _sceneRoot.meshes)
    {
        const NuoVectorFloat3 center = [mesh worldBounds:NuoMatrixFloat44Identity].boundingBox._center;
        const NuoVectorFloat4 centerVec(center.x(), center.y(), center.z(), 1.0);
        const NuoVectorFloat4 centerProjected = _sceneParameters.projection * centerVec;
        const NuoVectorFloat2 centerOnScreen = NuoVectorFloat2(centerProjected.x(), centerProjected.y()) / centerProjected.w();
        
        const float currentDistance = NuoDistance(normalized, centerOnScreen);
        if (currentDistance < distance)
        {
            distance = currentDistance;
            _selectedMesh = mesh;
        }
    }
}


- (NuoMeshSceneRoot*)cloneSceneFor:(NuoMeshModeShaderParameter)mode
{
    NuoMeshSceneRoot* newScene = [_sceneRoot cloneForMode:mode];
    return newScene;
}



- (void)rebuildRayTracingBuffers
{
    _rayAcceleratorNeedRebuild = YES;
}


- (void)syncRayTracingBuffers
{
    // mark this "dirty" mark as the BHV accelerator need to be synced at the time of
    // uniforms update
    //
    _rayAcceleratorOutOfSync = YES;
}



- (void)setResolveDepth:(BOOL)resolveDepth
{
    [_renderDelegate setResolveDepth:resolveDepth];
}



@end
