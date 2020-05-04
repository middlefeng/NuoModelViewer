#import "ModelViewerRenderer.h"

#import "NuoUniforms.h"
#import "NuoMeshBounds.h"

#import "NuoCommandBuffer.h"
#import "NuoBufferSwapChain.h"
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

#include "NuoMeshSceneRoot.h"
#include "NuoCubeMesh.h"
#include "NuoBackdropMesh.h"
#include "NuoRenderPassTarget.h"
#include "NuoModelBase.h"
#include "NuoTableExporter.h"

#include "NuoMathVector.h"

#include "NuoLua.h"

#import "NuoLightSource.h"

// sub renderers
//
#import "NuoRayAccelerateStructure.h"
#import "ModelHybridRenderDelegate.h"
#import "ModelRayTracerDelegate.h"

#import "ModelSceneParameters.h"

// inspect
//
#import "NuoCheckboardMesh.h"
#import "NuoInspectableMaster.h"


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
        
        _checkerboard = [[NuoCheckboardMesh alloc] initWithCommandQueue:commandQueue];
        
        _modelState = [[ModelState alloc] initWithCommandQueue:commandQueue];
        
        _sceneParameters = [[ModelSceneParameters alloc] initWithDevice:commandQueue.device];
        _sceneParameters.sceneRoot = _modelState.sceneRoot;
        
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
                                                                withSceneRoot:_modelState.sceneRoot
                                                          withSceneParameters:_sceneParameters];
    
    _rayTracingHybrid = YES;
}


- (void)switchToRayTracing
{
    ModelRayTracerDelegate* delegate = (ModelRayTracerDelegate*)_renderDelegate;
        
    if (!delegate || _rayTracingHybrid)
    {
        delegate = [[ModelRayTracerDelegate alloc] initWithCommandQueue:self.commandQueue
                                                        withAccelerator:_rayAccelerator
                                                          withSceneRoot:_modelState.sceneRoot];
    }
    
    [delegate setMultipleImportanceSampling:_modelState.rayTracingMultipleImportance];
    [delegate setIndirectSpecular:_modelState.rayTracingIndirectSpecular];
    
    _renderDelegate = delegate;
        
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
    
    [self continueUserInteract];
}


- (void)continueUserInteract
{
    if (!_rayTracingHybrid)
    {
        RecordStatus orginalStatus = _rayTracingRecordStatus;
        
        [self setRayTracingRecordStatus:kRecord_Stop];
        [self syncRayTracingBuffers];
        [self setRayTracingRecordStatus:orginalStatus];
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
    [_modelState setAdvancedShaowEnabled:enabled];
}


- (void)setSampleCount:(NSUInteger)sampleCount
{
    // no calling to super. because of the deferred pass, the sample
    // count of the final target is always 1
    
    // no calling to shadow map render. they are not MSAA-ed
    // no calling to cube/backdrop render. they are not MSAA-ed
    
    [_renderDelegate setSampleCount:sampleCount];
    [_modelState setSceneSampleCount:sampleCount];
}


- (BOOL)hasMeshes
{
    return [_modelState.sceneRoot.meshes count] != 0;
}


- (void)createBoard:(CGSize)size withName:(NSString*)name
{
    [_modelState createBoard:size withName:name];
    [self rebuildRayTracingBuffers];
}


- (void)removeSelectedMesh
{
    [_modelState removeSelectedMesh];
    [self rebuildRayTracingBuffers];
}



- (void)removeAllBoards
{
    [_modelState removeAllBoards];
    [self rebuildRayTracingBuffers];
}


- (NSArray<NuoMesh*>*)configurableMeshParts
{
    return [_modelState configurableMeshParts];
}


- (NuoMeshCompound*)mainModelMesh
{
    return _modelState.mainModelMesh;
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
    
    [_modelState exportScenePoises:&exporter];
    [_modelState exportBoardModels:&exporter];
    
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
        
        [_modelState exportModelConfiguration:&exporter];
        
        exporter.StartEntry("lights");
        exporter.StartTable();
        
        for (unsigned char lightIndex = 0; lightIndex < _lights.count; ++lightIndex)
        {
            exporter.StartArrayIndex(lightIndex);
            exporter.StartTable();
            
            NuoLightSource* light = _lights[lightIndex];
            
            {
                exporter.StartEntry("rotation");
                exporter.SetMatrix(light.lightDirection);
                exporter.EndEntry(true);
                
                exporter.StartEntry("irradiance");
                exporter.SetEntryValueFloat(light.lightingIrradiance);
                exporter.EndEntry(false);
                
                exporter.StartEntry("specular");
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
    [_modelState importScenePoises:lua];

    lua->GetField("view", -1);
    self.fieldOfView = lua->GetFieldAsNumber("FOV", -1);
    lua->RemoveField();
    
    [_modelState importModelConfiguration:lua];
    [_modelState importBoardModels:lua];
    
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
    
    [_modelState caliberateSceneCenter];
}


- (void)updateModelOptionsWithProgress:(NuoProgressFunction)progress
{
    [_modelState updateModelOptionsWithProgress:progress];
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
    if (_modelState.transMode == kTransformMode_Model && [_modelState viewTransformReset])
        [_modelState caliberateSceneCenter];
    
    NuoBounds bounds = [_modelState selectedMeshBounds:[_modelState viewMatrix]];
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
    [_modelState rotateX:_rotationXDelta Y:_rotationYDelta];
    
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
    
    [_modelState tanslate:translation];
}


- (void)updateUniformsForView:(NuoCommandBuffer*)commandBuffer
{
    // move all delta position coming from the view's mouse/gesture into the matrix,
    // according to the transform mode (i.e. scene or mesh)
    //
    [self handleDeltaPosition];
    
    [_sceneParameters setViewMatrix:[_modelState viewMatrix]];
    [_sceneParameters setLights:_lights];
    [_sceneParameters updateUniforms:commandBuffer];
    
    [_modelState.sceneRoot updateUniform:commandBuffer withTransform:NuoMatrixFloat44Identity];
    [_modelState.sceneRoot setCullEnabled:_sceneParameters.cullEnabled];
    
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
            [_rayAccelerator setRoot:_modelState.sceneRoot];
        else if (_rayAcceleratorOutOfSync)
            [_rayAccelerator setRoot:_modelState.sceneRoot withCommandBuffer:commandBuffer];
        
        [_rayAccelerator setView:[_modelState viewMatrix]];
        
        if (_rayAcceleratorOutOfSync)
        {
            [_renderDelegate setViewMatrix:[_modelState viewMatrix]];
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

    if (_modelState.mainModelMesh.enabled)
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
    
    for (NuoMesh* mesh in _modelState.sceneRoot.meshes)
    {
        const NuoVectorFloat3 center = [mesh worldBounds:NuoMatrixFloat44Identity].boundingBox._center;
        const NuoVectorFloat4 centerVec(center.x(), center.y(), center.z(), 1.0);
        const NuoVectorFloat4 centerProjected = _sceneParameters.projection * centerVec;
        const NuoVectorFloat2 centerOnScreen = NuoVectorFloat2(centerProjected.x(), centerProjected.y()) / centerProjected.w();
        
        const float currentDistance = NuoDistance(normalized, centerOnScreen);
        if (currentDistance < distance)
        {
            distance = currentDistance;
            [_modelState selectMesh:mesh];
        }
    }
}


- (NuoMeshSceneRoot*)cloneSceneFor:(NuoMeshModeShaderParameter)mode
{
    return [_modelState cloneSceneFor:mode];
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
