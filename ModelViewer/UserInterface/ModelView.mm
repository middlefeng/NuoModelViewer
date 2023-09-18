//
//  ModelView.m
//  ModelViewer
//
//  Created by middleware on 8/26/16.
//  Updated 5/13/2023.
//  Copyright © 2023 middleware. All rights reserved.
//

#import "ModelView.h"

#import "ModelViewConfiguration.h"
#import "ModelConfiguration.h"
#import "ModelComponentPanels.h"
#import "ModelOperationPanel.h"
#import "LightOperationPanel.h"
#import "BoardSettingsPanel.h"

#import "FrameRateView.h"
#import "AppPreferences.h"

// pipeline stages
//
#import "ModelViewerRenderer.h"
#import "ModelSceneParameters.h"
#import "ModelDissectRenderer.h"
#import "ModelSelectionRenderer.h"
#import "NotationRenderer.h"
#import "MotionBlurRenderer.h"

#import "ModelState.h"

#import "NuoLua.h"
#import "NuoDirectoryUtils.h"
#import "NuoMeshOptions.h"
#import "NuoLightSource.h"

#import "NuoProgressSheetPanel.h"

#import "NuoMeshCompound.h"
#import "NuoCubeMesh.h"
#import "NuoBackdropMesh.h"
#import "NuoMeshRotation.h"
#import "NuoMeshAnimation.h"
#import "NuoTextureBase.h"
#import "NuoRayAccelerateStructure.h"
#import "NuoRenderPassAttachment.h"
#import "NuoScheduler.h"

#import "NuoOffscreenView.h"

#import "NuoInspectWindow.h"
#import "OpenInspectPanel.h"


typedef enum
{
    kDrag_Shift_X,
    kDrag_Shift_Y,
    kDrag_Normal,
}
MouseDragMode;



@interface ModelView() < ModelOptionUpdate, NSWindowDelegate >

@end




@implementation ModelView
{
    NuoLua _lua;
    ModelViewConfiguration* _configuration;
    
    // pipeline stages
    //
    ModelRenderer* _modelRender;
    ModelDissectRenderer* _modelDissectRenderer;
    ModelSelectionRenderer* _modelSelectionRenderer;
    NotationRenderer* _notationRenderer;
    MotionBlurRenderer* _motionBlurRenderer;
    
    NSMutableArray<NuoMeshAnimation*>* _animations;
    
    FrameRateView* _frameRateView;
    ModelComponentPanels* _modelComponentPanels;
    ModelOperationPanel* _modelPanel;
    LightOperationPanel* _lightPanel;
    
    BOOL _trackingLighting;
    BOOL _trackingSplitView;
    BOOL _mouseMoved;
    MouseDragMode _mouseDragMode;
    
    IBOutlet NSMenuItem* _sceneResetMenu;
    IBOutlet NSMenuItem* _removeObjectMenu;
    
    __weak AppPreferences* _preferences;
    
    NSString* _documentName;
    
    NuoScheduler* _frameScheduler;
    NSTimer* _frameRateDisplayTimer;
}



- (NuoLua*)lua
{
    return &_lua;
}


- (NSRect)operationPanelLocation
{
    NSRect viewRect = [self frame];
    NSSize panelSize = NSMakeSize(225, 430);
    NSSize panelMargin = NSMakeSize(15, 25);
    NSPoint panelOrigin = NSMakePoint(viewRect.size.width - panelMargin.width - panelSize.width,
                                      viewRect.size.height - panelMargin.height - panelSize.height);
    
    NSRect panelRect;
    panelRect.origin = panelOrigin;
    panelRect.size = panelSize;
    
    return panelRect;
}


- (NSRect)frameRatePanelLocation
{
    NSSize panelSize = NSMakeSize(90, 30);
    NSSize panelMargin = NSMakeSize(15, 25);
    NSPoint panelOrigin = NSMakePoint(panelMargin.width, panelMargin.height);
    
    NSRect panelRect;
    panelRect.origin = panelOrigin;
    panelRect.size = panelSize;
    
    return panelRect;
}


- (void)handleDraggingQuality
{
    NSEvent *event = [[NSApplication sharedApplication] currentEvent];
    BOOL startingDrag = event.type == NSEventTypeLeftMouseDown;
    BOOL endingDrag = event.type == NSEventTypeLeftMouseUp;
    BOOL dragging = event.type == NSEventTypeLeftMouseDragged;
    
    if (startingDrag)
    {
        [_modelRender setSampleCount:1];
        [_modelRender beginUserInteract];
    }
        
    if (dragging)
    {
        [_modelRender setSampleCount:1];
        [_modelRender continueUserInteract];
    }
    
    if (endingDrag)
    {
        [_modelRender endUserInteract:_modelPanel.rayTracingRecordStatus];
        [_modelRender setSampleCount:kSampleCount];
    }
}


- (void)addFrameRatePanel
{
    NSRect panelRect = [self frameRatePanelLocation];
    
    _frameRateView = [FrameRateView new];
    _frameRateView.frame = panelRect;
    _frameRateView.layer.opacity = 0.8f;
    _frameRateView.panelBackground = [NSColor colorNamed:@"Panel_Background"];
    _frameRateView.hidden = YES;
    
    [self addSubview:_frameRateView];
}


- (void)addModelComponentPanels
{
    _modelComponentPanels = [ModelComponentPanels new];
    _modelComponentPanels.containerView = self;
    _modelComponentPanels.modelOptionDelegate = self;
    
    [_modelComponentPanels addPanels];
}


- (void)addModelOperationPanel
{
    NSRect panelRect = [self operationPanelLocation];
    
    _modelPanel = [ModelOperationPanel new];
    _modelPanel.frame = panelRect;
    _modelPanel.layer.opacity = 0.8f;
    _modelPanel.layer.backgroundColor = [NSColor colorWithWhite:1.0 alpha:1.0].CGColor;
    
    NSArray* deviceNames = _configuration.deviceNames;
    
    [_modelPanel setDeviceSelected:_configuration.device.name];
    [_modelPanel setDeviceNames:deviceNames];
    [_modelPanel addSubviews];
    [_modelPanel setOptionUpdateDelegate:self];
    
    [self addSubview:_modelPanel];
}


- (void)addLightOperationPanel
{
    CGRect area = [self lightPanelRect];
    
    _lightPanel = [[LightOperationPanel alloc] initWithFrame:area];
    [self addSubview:_lightPanel];
    [_lightPanel setHidden:YES];
    [_lightPanel setOptionUpdateDelegate:self];
}


- (void)modelMeshInvalid
{
    // clear all table and data structures that depends on the mesh
    //
    [_animations removeAllObjects];
    [_modelPanel setModelPartAnimations:_animations];
    [_modelComponentPanels reloadPanels];
    
    if (_modelPanel.meshMode == kMeshMode_Normal)
    {
        [_modelDissectRenderer setDissectScene:nil];
    }
    else
    {
        NuoMeshSceneRoot* dissectScene = [_modelRender cloneSceneFor:_modelPanel.meshMode];
        [_modelDissectRenderer setDissectScene:dissectScene];
    }
    
    [_modelRender rebuildRayTracingBuffers];
}


- (void)modelUpdate
{
    __weak ModelView* selfWeak = self;
    __weak ModelRenderer* render = _modelRender;
    
    NuoProgressSheetPanel* progressPanel = [NuoProgressSheetPanel new];
    
    [progressPanel performInBackground:^(NuoProgressFunction progress)
                                {
                                    [render updateModelOptionsWithProgress:progress];
                                }
                            withWindow:self.window
                        withCompletion:^()
                                {
                                    [selfWeak modelMeshInvalid];
                                    [selfWeak render];
                                }];
}


- (void)modelOptionUpdate:(uint32_t)options
{
    NSString* currentDevice = _configuration.deviceName;
    NSString* deviceSelected = _modelPanel.deviceSelected;
    
    if (deviceSelected && currentDevice && ![currentDevice isEqualToString:deviceSelected])
    {
        [_configuration setDeviceName:deviceSelected];
        [_configuration save];
    }
    
    if (options & kUpdateOption_DecreaseQuality)
    {
        [self handleDraggingQuality];
    }
    
    NuoRenderPassTarget* target = _modelRender.renderTarget;
    float color = _modelPanel.backgroundColor;
    target.clearColor = MTLClearColorMake(color, color, color, 1);
    
    [self showHideFrameRate:_modelPanel.showFrameRate];
    
    [_modelSelectionRenderer setEnabled:_modelPanel.showModelParts];
    [_modelComponentPanels setHidden:!_modelPanel.showModelParts];
    
    // mark the ray tracing dirty flag before all substantial work, in order not to
    // cause duplicated waste work
    //
    [_modelRender syncRayTracingBuffers];
    
    if (options & kUpdateOption_RebuildPipeline)
    {
        [self setupPipelineSettings];
    }
    
    // the setup of parameter buffers are placed after the pipeline-setting-setup because of
    // buffers are managed by inner sub-renderers or renderer-delegate that is created in the
    // pipeline-setting-setup phase
    //
    [_modelRender setAmbientParameters:_modelPanel.ambientParameters];
    [_modelRender setFieldOfView:_modelPanel.fieldOfViewRadian];
    [_modelRender setAmbientDensity:_modelPanel.ambientDensity];
    [_modelRender setIlluminationStrength:_modelPanel.illumination];
    [_modelRender setShowCheckerboard:_modelPanel.showModelParts];
    [_modelRender.modelState setTransMode:_modelPanel.transformMode];
    
    [_modelRender.sceneParameters setCullEnabled:_modelPanel.cullEnabled];
        
    if (!_modelPanel.showFrameRate)
        [self accumulatingRecord:(_modelPanel.rayTracingRecordStatus == kRecord_Start)];
        
    for (NuoMeshAnimation* animation in _animations)
        [animation setProgress:_modelPanel.animationProgress];
    
    if (_modelPanel.meshMode == kMeshMode_Normal)
        [self.window setAcceptsMouseMovedEvents:NO];
    else
        [self.window setAcceptsMouseMovedEvents:YES];
    
    [_modelComponentPanels updatePanels];
    
    if (!_lightPanel.hidden)
    {
        _notationRenderer.physicallySpecular = _modelRender.modelState.modelOptions._physicallyReflection;
        
        _notationRenderer.irradiance = _lightPanel.lightIrradiance;
        _notationRenderer.specular = _lightPanel.lightSpecular;
        _notationRenderer.shadowSoften = _lightPanel.shadowSoften;
        _notationRenderer.shadowOccluderRadius = _lightPanel.shadowOccluderRadius;
        _notationRenderer.shadowBias = _lightPanel.shadowBias;
    }
    
    [self render];
}



- (void)modelPartsSelectionChanged
{
    ModelState* modelState = _modelRender.modelState;
    NSArray* selected = modelState.selectedParts;
    
    if (selected && selected.count && !_modelSelectionRenderer)
    {
        _modelSelectionRenderer = [[ModelSelectionRenderer alloc] initWithCommandQueue:self.commandQueue
                                                                       withPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                       withSampleCount:kSampleCount];
        _modelSelectionRenderer.modelState = _modelRender.modelState;
        _modelSelectionRenderer.paramsProvider = _modelRender.sceneParameters;
        [self setupPipelineSettings];
    }
    
    if (!selected || !selected.count)
    {
        if (_modelSelectionRenderer)
        {
            _modelSelectionRenderer = nil;
            [self setupPipelineSettings];
        }
    }
    else
    {
        [self render];
    }
}



- (void)showHideFrameRate:(BOOL)show
{
    [_frameRateView setHidden:!show];
    
    [self setMeasureFrameRate:show];
    [self accumulatingRecord:show];
    
    if (show)
    {
        if (!_frameRateDisplayTimer)
        {
            __weak ModelView* weakSelf = self;
            __weak FrameRateView* frameRateView = _frameRateView;
            
            _frameRateDisplayTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 repeats:YES block:^(NSTimer* timer)
                                        {
                                            [frameRateView showFrameRate:[weakSelf frameRate]];
                                        }];
        }
    }
    else
    {
        [_frameRateDisplayTimer invalidate];
        _frameRateDisplayTimer = nil;
    }
}



- (void)accumulatingRecord:(BOOL)record
{
    if (record)
    {
        if (!_frameScheduler)
        {
            __weak ModelView* weakSelf = self;
            
            _frameScheduler = [NuoScheduler new];
            _frameScheduler.schedule = _configuration.renderSchedule;
            
            [_frameScheduler scheduleWithInterval:1 / 60.0 task:^()
                                        {
                                            [weakSelf render];
                                        }];
        }
    }
    else
    {
        [_frameScheduler invalidate];
        _frameScheduler = nil;
    }
}



- (void)animationLoad
{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    openPanel.allowedContentTypes = @[[UTType typeWithFilenameExtension:@"anm"]];
    
    __weak ModelRenderer* renderer = _modelRender;
    __weak ModelOperationPanel* panel = _modelPanel;
    
    NSMutableArray<NuoMeshAnimation*>* animations = [[NSMutableArray alloc] init];
    _animations = animations;
    
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result)
         {
             if (result == NSModalResponseOK)
             {
                 NuoLua* lua = [self lua];
                 lua->LoadFile(openPanel.URL.path.UTF8String);
                 NuoLua::KeySet keys = lua->GetKeysFromTable(-1);
                 
                 for (const std::string& key : keys)
                 {
                     NuoMeshAnimation* current = [NuoMeshAnimation new];
                     current.animationName = [NSString stringWithUTF8String:key.c_str()];
                     
                     lua->GetField(key, -1);
                     [current importAnimation:lua forMesh:renderer.mainModelMesh.meshes];
                     lua->RemoveField();
                     
                     if (current.mesh.count)
                         [animations addObject:current];
                 }
                 
                 [panel setModelPartAnimations:animations];
             }
         }];
}



// awakeFromNib should be the last step of initialization. here set some properties
// to the objects which are created in viewResizing
//
- (void)awakeFromNib
{
    self.metalLayer.device = [_configuration device];
    
    CGRect frame = [_configuration windowFrame];
    
    [super awakeFromNib];
    [self.window setDelegate:self];
    
    if (frame.size.width != 0.0 && frame.size.height != 0.0)
        [self.window setFrame:frame display:YES];
}



- (void)windowWillClose:(NSNotification *)notification
{
    [_configuration setWindowFrame:self.window.frame];
    [_configuration save];
}



// viewResizing is called before awakeFromNib so here becomes the place to create
// member objects programmatically
//
- (void)viewResizing
{
    [super viewResizing];
    
    NSRect viewRect = [self frame];
    NSSize popupSize = NSMakeSize(200, 25);
    NSSize popupMargin = NSMakeSize(10, 10);
    NSPoint popupOrigin = NSMakePoint(viewRect.size.width - popupMargin.width - popupSize.width,
                                      viewRect.size.height - popupMargin.height - popupSize.height);
    
    NSRect popupRect;
    popupRect.origin = popupOrigin;
    popupRect.size = popupSize;
    
    if (!_configuration)
    {
        const char* path = pathForConfigureFile();
        _configuration = [[ModelViewConfiguration alloc] initWithFile:[NSString stringWithUTF8String:path]];
    }
    
    if (!_frameRateView)
    {
        [self addFrameRatePanel];
    }
    
    if (!_modelPanel)
    {
        [self addModelOperationPanel];
    }
    
    if (!_modelComponentPanels)
    {
        [self addModelComponentPanels];
    }
    
    [_modelPanel setFrame:[self operationPanelLocation]];
    
    if (!_lightPanel)
    {
        [self addLightOperationPanel];
    }
    
    [_lightPanel setFrame:[self lightPanelRect]];
    [_modelComponentPanels containerViewResized];
}



- (void)commonInit
{
    [super commonInit];
    
    _modelRender = [[ModelRenderer alloc] initWithCommandQueue:self.commandQueue];
    _modelDissectRenderer = [[ModelDissectRenderer alloc] initWithCommandQueue:self.commandQueue];
    _modelDissectRenderer.paramsProvider = _modelRender.sceneParameters;
    _modelDissectRenderer.splitViewProportion = 0.5;
    _notationRenderer = [[NotationRenderer alloc] initWithCommandQueue:self.commandQueue];
    _notationRenderer.modelState = _modelRender.modelState;
    _motionBlurRenderer = [[MotionBlurRenderer alloc] initWithCommandQueue:self.commandQueue];
    
    [_modelComponentPanels setModelState:_modelRender.modelState];
    [_modelPanel setModelState:_modelRender.modelState];
    [_modelPanel updateControls];
    
    _notationRenderer.notationWidthCap = [self operationPanelLocation].size.width + 30;
    
    // sync the model renderer with the initial settings in the model panel
    //
    [self modelOptionUpdate:kUpdateOption_RebuildPipeline];
    [self modelUpdate];
    
    // sync the light panel with the current initial light vector in the
    // notation renderer
    //
    [_lightPanel updateControls:_notationRenderer.selectedLightSource];
    
    [self setupPipelineSettings];
    [self registerForDraggedTypes:@[@"public.data"]];
}


- (NSRect)lightPanelRect
{
    const CGFloat margin = 10;
    
    CGRect area = [_notationRenderer notationArea];
    NSRect result = area;
    CGFloat width = area.size.width;
    width = width * 0.8;
    result.size.width = width;
    result.size.height = 120;
    result.origin.y = margin;
    result.origin.x += (area.size.width - width) / 2.0;
    
    return result;
}


- (void)setupPipelineSettings
{
    NSMutableArray* renders = [NSMutableArray new];
    
    NuoRenderPassTarget* lastTarget = nil;
    
    // model renderer
    //
    
    [renders addObject:_modelRender];
    
    NuoRenderPassTarget* modelRenderTarget = [[NuoRenderPassTarget alloc] initWithCommandQueue:self.commandQueue
                                                                               withPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                               withSampleCount:1];
    float grayScale = _modelPanel.backgroundColor;
    modelRenderTarget.clearColor = MTLClearColorMake(grayScale, grayScale, grayScale, 1);
    modelRenderTarget.manageTargetTexture = YES;
    modelRenderTarget.name = @"Model";
    
    [_modelRender setRenderTarget:modelRenderTarget];
    lastTarget = modelRenderTarget;
    
    if (_modelPanel.rayTracingHybrid ||
        _modelPanel.rayTracingRecordStatus == kRecord_Stop)
    {
        [_modelRender switchToHybrid];
    }
    else
    {
        [_modelRender switchToRayTracing];
    }
    
    if (_modelPanel.rayTracingRecordStatus == kRecord_Start &&
        _modelPanel.motionBlurRecordStatus != kRecord_Start)
    {
        // when the panel indicates the recording to be "start",
        //   1. if the render's flag is "start" as well, the accumulation need to be reset becuase some render property
        //      other than the recording status is changed
        //   2. if the render's flag is not "start", it is either "stop" or "pause", none of which need reset the
        //      accumulation since either it is already stop, or a pasued accumulation should be resumed
        
        if (_modelRender.rayTracingRecordStatus == kRecord_Start)
            _modelRender.rayTracingRecordStatus = kRecord_Stop;
    }
    
    _modelRender.rayTracingRecordStatus = _modelPanel.rayTracingRecordStatus;
    
    // dissect renderer
    //
    
    if (_modelPanel.meshMode != kMeshMode_Normal)
    {
        [renders addObject:_modelDissectRenderer];
        _modelDissectRenderer.dissectScene = [_modelRender cloneSceneFor:_modelPanel.meshMode];
        
        NuoRenderPassTarget* modelDissectTarget = [[NuoRenderPassTarget alloc] initWithCommandQueue:self.commandQueue
                                                                                    withPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                    withSampleCount:kSampleCount];
        modelDissectTarget.clearColor = MTLClearColorMake(0.95, 0.95, 0.95, 1);
        modelDissectTarget.manageTargetTexture = YES;
        modelDissectTarget.name = @"Model-Dissect";
        
        [_modelDissectRenderer setRenderTarget:modelDissectTarget];
        lastTarget = modelDissectTarget;
    }
    
    // motion blur renderer
    //
    
    if (_modelPanel.motionBlurRecordStatus == kRecord_Start)
    {
        [renders addObject:_motionBlurRenderer];
        
        NuoRenderPassTarget* motionBlurTarget = [[NuoRenderPassTarget alloc] initWithCommandQueue:self.commandQueue
                                                                                  withPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                  withSampleCount:1];
        motionBlurTarget.clearColor = MTLClearColorMake(0, 0, 0, 0);
        motionBlurTarget.manageTargetTexture = YES;
        motionBlurTarget.colorAttachments[0].needWrite = YES;
        motionBlurTarget.name = @"Motion Blur";
        
        [_motionBlurRenderer setRenderTarget:motionBlurTarget];
        
        lastTarget = motionBlurTarget;
    }
    else if (_modelPanel.motionBlurRecordStatus == kRecord_Stop)
    {
        [_motionBlurRenderer resetResources];
    }
    
    // selection overlay
    //
    
    if (_modelSelectionRenderer)
    {
        [renders addObject:_modelSelectionRenderer];
        
        NuoRenderPassTarget* selectionTarget = [[NuoRenderPassTarget alloc] initWithCommandQueue:self.commandQueue
                                                                                 withPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                 withSampleCount:kSampleCount];
        
        selectionTarget.clearColor = MTLClearColorMake(0, 0, 0, 0);
        selectionTarget.manageTargetTexture = YES;
        selectionTarget.name = @"Selection";
        
        [_modelSelectionRenderer setRenderTarget:selectionTarget];
        
        lastTarget = selectionTarget;
    }
    
    // notation renderer
    //
    
    if (_modelPanel.showLightSettings)
    {
        [renders addObject:_notationRenderer];
        
        NuoRenderPassTarget* notationRenderTarget = [[NuoRenderPassTarget alloc] initWithCommandQueue:self.commandQueue
                                                                                      withPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                      withSampleCount:kSampleCount];
        notationRenderTarget.clearColor = MTLClearColorMake(0.95, 0.95, 0.95, 1);
        notationRenderTarget.manageTargetTexture = NO;
        notationRenderTarget.name = @"Notation";
        
        [_notationRenderer setRenderTarget:notationRenderTarget];
        lastTarget = nil;
    }
    
    // the last target is framebuffer
    //
    lastTarget.manageTargetTexture = NO;

    [_lightPanel setHidden:!_modelPanel.showLightSettings];
    
    [self setRenderPasses:renders];
    [self viewResizing];
}



- (BOOL)isDissectSplitViewHandler:(NSEvent*)event
{
    if (_modelPanel.meshMode == kMeshMode_Normal)
        return NO;
    
    NSPoint location = event.locationInWindow;
    location = [self convertPoint:location fromView:nil];
    
    CGFloat mousePos = location.x / [self frame].size.width;
    CGFloat splitViewPostion = _modelDissectRenderer.splitViewProportion;
    
    if (splitViewPostion > 0.95 && mousePos > 0.95)
        return YES;
    if (splitViewPostion < 0.05 && mousePos < 0.05)
        return YES;
    
    return (fabs(splitViewPostion - mousePos) < 0.01);
}


- (void)mouseMoved:(NSEvent *)event
{
    if ([self isDissectSplitViewHandler:event])
    {
        NSCursor* cursor = [NSCursor resizeLeftRightCursor];
        [cursor set];
    }
    else
    {
        NSCursor* cursor = [NSCursor arrowCursor];
        [cursor set];
    }
}


- (void)mouseDown:(NSEvent *)event
{
    if ([self isDissectSplitViewHandler:event])
    {
        _trackingSplitView = YES;
    }
    else if (_modelPanel.showLightSettings)
    {
        NSPoint location = event.locationInWindow;
        location = [self convertPoint:location fromView:nil];
        
        CGRect lightSettingArea = _notationRenderer.notationArea;
        _trackingLighting = CGRectContainsPoint(lightSettingArea, location);
        
        if (_trackingLighting)
        {
            [_notationRenderer selectCurrentLightVector:location];
            NuoLightSource* source = _notationRenderer.selectedLightSource;
            
            [_lightPanel updateControls:source];
        }
    }
    else
    {
        _trackingLighting = NO;
    }
    
    // ok to turn off the advanced shadow unless in case of recording blur, or adjusting light.
    //
    if (!_trackingLighting && _modelPanel.motionBlurRecordStatus == kRecord_Stop)
        [_modelRender setAdvancedShaowEnabled:NO];
    
    [_modelRender beginUserInteract];
    [_modelRender setSampleCount:1];
    
    _mouseMoved = NO;
}


- (void)mouseUp:(NSEvent *)event
{
    [_modelRender setAdvancedShaowEnabled:YES];
    [_modelRender setSampleCount:kSampleCount];
    [_modelRender endUserInteract:_modelPanel.rayTracingRecordStatus];
    
    _trackingLighting = NO;
    _trackingSplitView = NO;
    [self render];
    
    if (!_mouseMoved)
    {
        NSPoint location = event.locationInWindow;
        location = [self convertPoint:location fromView:nil];
        [_modelRender selectMeshWithScreen:location];
    }
}


- (void)mouseDragged:(NSEvent *)theEvent
{
    float deltaX = -0.01 * M_PI * theEvent.deltaY;
    float deltaY = -0.01 * M_PI * theEvent.deltaX;
    
    if (theEvent.modifierFlags & NSEventModifierFlagControl)
    {
        deltaX *= 0.005;
        deltaY *= 0.005;
    }
    
    BOOL mouseWasMoved = _mouseMoved;
    if (!_mouseMoved && (deltaX != 0.0 || deltaY != 0.0))
        _mouseMoved = YES;
    
    if (!mouseWasMoved && _mouseMoved)
    {
        if (theEvent.modifierFlags & NSEventModifierFlagShift)
        {
            if (fabs(deltaX) > fabs(deltaY))
                _mouseDragMode = kDrag_Shift_X;
            else
                _mouseDragMode = kDrag_Shift_Y;
        }
        else
        {
            _mouseDragMode = kDrag_Normal;
        }
    }
    
    if (_mouseDragMode == kDrag_Shift_Y)
        deltaX = 0.0;
    if (_mouseDragMode == kDrag_Shift_X)
        deltaY = 0.0;
    
    if (_trackingSplitView)
    {
        NSPoint location = theEvent.locationInWindow;
        location = [self convertPoint:location fromView:nil];
        
        CGFloat mousePos = location.x / [self frame].size.width;
        _modelDissectRenderer.splitViewProportion = mousePos;
    }
    else if (_trackingLighting)
    {
        [_notationRenderer updateRotationX:deltaX Y:deltaY];
    }
    else
    {
        if ([theEvent modifierFlags] & NSEventModifierFlagCommand)
        {
            NuoCubeMesh* cube = [_modelRender cubeMesh];
            [cube setRotationXDelta:-deltaX];
            [cube setRotationYDelta:-deltaY];
        }
        else
        {
            _modelRender.rotationXDelta = deltaX;
            _modelRender.rotationYDelta = deltaY;
        }
    }
    
    [_modelRender continueUserInteract];
    [self render];
}


- (void)magnifyWithEvent:(NSEvent *)event
{
    if (event.modifierFlags & NSEventModifierFlagCommand)
        _modelRender.backdropScaleDelta = event.magnification;
    else
        _modelRender.zoomDelta = 10 * event.magnification;
    
    [_modelRender continueUserInteract];
    [self render];
}



- (void)scrollWheel:(NSEvent *)event
{
    CGFloat deltaX = -event.deltaX;
    CGFloat deltaY = event.deltaY;
    
    if (event.modifierFlags & NSEventModifierFlagControl)
    {
        deltaX *= 0.005;
        deltaY *= 0.005;
    }
    
    if (event.modifierFlags & NSEventModifierFlagCommand)
    {
        _modelRender.backdropTransXDelta = -deltaX * 0.01;
        _modelRender.backdropTransYDelta = -deltaY * 0.01;
    }
    else
    {
        _modelRender.transXDelta = deltaX;
        _modelRender.transYDelta = deltaY;
    }
    
    [_modelRender setRayTracingRecordStatus:kRecord_Stop];
    [_modelRender syncRayTracingBuffers];
    [_modelRender setRayTracingRecordStatus:_modelPanel.rayTracingRecordStatus];
    [self render];
}


- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    NSPasteboard* paste = [sender draggingPasteboard];
    NSURL* url = [NSURL URLFromPasteboard:paste];
    
    if (url && url.isFileURL)
    {
        NSString* path = url.path;
        if ([path hasSuffix:@".obj"] || [path hasSuffix:@".jpg"] || [path hasSuffix:@".png"])
        {
            NSLog(@"Enterred.");
            return NSDragOperationCopy;
        }
        else if ([path hasSuffix:@".zip"] && [_modelRender.modelState isValidPack:path])
        {
            return NSDragOperationCopy;
        }
        else
        {
            NSFileManager* manager = [NSFileManager defaultManager];
            BOOL isDir = false;
            
            [manager fileExistsAtPath:path isDirectory:&isDir];
            if (isDir)
            {
                NSString* name = [path lastPathComponent];
                name = [name stringByAppendingString:@".obj"];
                
                NSString* filePath = [path stringByAppendingPathComponent:name];
                return [manager fileExistsAtPath:filePath] ? NSDragOperationCopy : NSDragOperationNone;
            }
        }
    }
    
    return NSDragOperationNone;
}


- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
    return YES;
}


- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    NSPasteboard* paste = [sender draggingPasteboard];
    NSURL* url = [NSURL URLFromPasteboard:paste];
    NSString* path = url.path;
    
    if ([path hasSuffix:@".jpg"] || [path hasSuffix:@".png"])
    {
        [self loadBackDropWithPath:path];
        [self render];
    }
    else
    {
        NSFileManager* manager = [NSFileManager defaultManager];
        BOOL isDir = false;
        
        [manager fileExistsAtPath:path isDirectory:&isDir];
        if (isDir)
        {
            NSString* name = [path lastPathComponent];
            name = [name stringByAppendingString:@".obj"];
            path = [path stringByAppendingPathComponent:name];
            
            __weak ModelView* selfWeak = self;
            [self loadMesh:path asPackage:NO withCompletion:^{ [selfWeak render]; }];
        }
        else if ([path hasSuffix:@".obj"])
        {
            __weak ModelView* selfWeak = self;
            [self loadMesh:path asPackage:NO withCompletion:^{ [selfWeak render]; }];
        }
        else if ([path hasSuffix:@".zip"])
        {
            __weak ModelView* selfWeak = self;
            [self loadMesh:path asPackage:YES withCompletion:^{ [selfWeak render]; }];
        }
    }

    return YES;
}



- (void)render
{
    _modelRender.lights = _notationRenderer.lightSources;
    
    if (!_modelRender.modelState.viewTransformReset)
    {
        [_sceneResetMenu setTarget:self];
        [_sceneResetMenu setAction:@selector(resetScene:)];
    }
    
    [super render];
    
    NuoInspectableMaster* inspectMaster = [NuoInspectableMaster sharedMaster];
    [inspectMaster inspect];
}



- (void)loadMesh:(NSString*)path asPackage:(BOOL)isPackage withCompletion:(NuoSimpleFunction)completion
{
    __weak ModelState* modelState = _modelRender.modelState;
    __weak ModelView* selfWeak = self;
    
    NuoProgressSheetPanel* progressPanel = [NuoProgressSheetPanel new];
    
    [progressPanel performInBackground:^(NuoProgressFunction progressFunc)
                                    {
                                        if (isPackage)
                                            [modelState loadPackage:path withProgress:progressFunc];
                                        else
                                            [modelState loadMesh:path withProgress:progressFunc];
                                    }
                            withWindow:self.window
                        withCompletion:^
                                    {
                                        [selfWeak modelMeshInvalid];
                                        completion();
                                    }];
    
    
    [_removeObjectMenu setTarget:self];
    [_removeObjectMenu setAction:@selector(removeObject:)];
    
    NSString* documentName = [path lastPathComponent];
    _documentName = [documentName stringByDeletingPathExtension];
    NSString* title = [[NSString alloc] initWithFormat:@"ModelView - %@", documentName];
    [self.window setTitle:title];
}



- (void)loadScene:(NSString*)path
{
    NuoLua* lua = [self lua];
    lua->LoadFile(path.UTF8String);
    
    CGSize drawableSize;
    lua->GetField("canvas", -1);
    drawableSize.width = lua->GetFieldAsNumber("width", -1);
    drawableSize.height = lua->GetFieldAsNumber("height", -1);
    lua->RemoveField();
    
    NSWindow* window = self.window;
    [window setContentSize:drawableSize];
    
    [_modelRender importScene:lua];
    [_notationRenderer importScene:lua];
    [_lightPanel updateControls:_notationRenderer.selectedLightSource];
    
    [_modelComponentPanels reloadPanels];
    [_modelPanel setFieldOfViewRadian:_modelRender.fieldOfView];
    [_modelPanel setAmbientParameters:[_modelRender ambientParameters]];
    [_modelPanel setAmbientDensity:_modelRender.ambientDensity];
    [_modelPanel setIllumination:_modelRender.illuminationStrength];
    [_modelPanel updateControls];
}



- (void)loadBackDropWithPath:(NSString*)path
{
    NuoTexture* tex = [[NuoTextureBase getInstance:self.commandQueue] texture2DWithImageNamed:path
                                                                                    mipmapped:NO
                                                                            checkTransparency:NO];
    NuoBackdropMesh* backdrop = [[NuoBackdropMesh alloc] initWithCommandQueue:self.commandQueue
                                                                 withBackdrop:tex.texture];
    [backdrop makePipelineAndSampler];
    [_modelRender setBackdropMesh:backdrop];
}



- (IBAction)preferencesDialog:(id)sender
{
    AppPreferences* preferences = _preferences;
    
    if (!preferences)
    {
        preferences = [AppPreferences new];
        _preferences = preferences;
        
        [preferences locateRelativeTo:self.window];
    }
    
    [preferences setConfiguration:_configuration];
    [preferences makeKeyAndOrderFront:nil];
}


- (IBAction)openFile:(id)sender
{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    openPanel.allowedContentTypes = @[[UTType typeWithFilenameExtension:@"obj"],
                                      [UTType typeWithFilenameExtension:@"scn"],
                                      UTTypeZIP];
    
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result)
            {
                if (result == NSModalResponseOK)
                {
                    NSString* path = openPanel.URL.path;
                    NSString* ext = path.pathExtension;
                    
                    if ([ext isEqualToString:@"obj"])
                    {
                        __weak ModelView* selfWeak = self;
                        [self loadMesh:path asPackage:NO withCompletion:^{ [selfWeak render]; }];
                    }
                    
                    if ([ext isEqualToString:@"zip"])
                    {
                        __weak ModelView* selfWeak = self;
                        [self loadMesh:path asPackage:YES withCompletion:^{ [selfWeak render]; }];
                    }
                    
                    if ([ext isEqualToString:@"scn"])
                    {
                        [self loadScene:path];
                        [self render];
                    }
                }
            }];
}



- (IBAction)loadCube:(id)sender
{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    openPanel.allowedContentTypes = @[UTTypeJPEG, UTTypePNG];
    
    __weak id<MTLCommandQueue> commandQueue = self.commandQueue;
    __weak ModelView* selfWeak = self;
    __weak ModelRenderer* renderer = _modelRender;
    
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result)
             {
                 if (result == NSModalResponseOK)
                 {
                     NSString* path = openPanel.URL.path;
                     
                     NuoCubeMesh* cubeMesh = [[NuoCubeMesh alloc] initWithCommandQueue:commandQueue];
                     NuoTextureBase* base = [NuoTextureBase getInstance:commandQueue];
                     cubeMesh.cubeTexture = [base textureCubeWithImageNamed:path];

                     [cubeMesh makePipelineAndSampler:MTLPixelFormatBGRA8Unorm];
                 
                     [renderer setCubeMesh:cubeMesh];
                     [selfWeak render];
                 }
             }];
}



- (IBAction)loadBackdrop:(id)sender
{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    openPanel.allowedContentTypes = @[UTTypeJPEG, UTTypePNG];
    
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result)
             {
                 if (result == NSModalResponseOK)
                 {
                     NSString* path = openPanel.URL.path;
                     
                     [self loadBackDropWithPath:path];
                     [self render];
                 }
             }];
}



- (IBAction)saveScene:(id)sender
{
    NSString* defaultName = _documentName;
    if (!defaultName)
        defaultName = @" ";
    
    NSSavePanel* savePanel = [NSSavePanel savePanel];
    [savePanel setNameFieldStringValue:defaultName];
    [savePanel setCanSelectHiddenExtension:YES];
    [savePanel setAllowedContentTypes:@[[UTType typeWithFilenameExtension:@"scn"]]];
    
    __weak ModelRenderer* renderer = _modelRender;
    
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result)
             {
                 if (result == NSModalResponseOK)
                 {
                     NSString* path = savePanel.URL.path;
                     NSString* result = [renderer exportSceneAsString:[self.window contentView].frame.size];
                     const char* pathStr = path.UTF8String;
                     
                     FILE* file = fopen(pathStr, "w");
                     fwrite(result.UTF8String, sizeof(char), result.length, file);
                     fclose(file);
                 }
             }];
        }



- (NSArray*)exportRenders
{
    NSMutableArray* result = [NSMutableArray new];
    
    [result addObject:_modelRender];
    
    if (_modelPanel.motionBlurRecordStatus == kRecord_Start)
        [result addObject:_motionBlurRenderer];
    
    return result;
}


- (IBAction)exportPNG:(id)sender
{
    NSString* defaultName = _documentName;
    if (!defaultName)
        defaultName = @" ";
    
    NSSavePanel* savePanel = [NSSavePanel savePanel];
    [savePanel setNameFieldStringValue:defaultName];
    [savePanel setCanSelectHiddenExtension:YES];
    [savePanel setAllowedContentTypes:@[UTTypePNG]];
    
    __weak id<MTLCommandQueue> commandQueue = self.commandQueue;
    
    CGFloat previewSize = fmax(_modelRender.renderTarget.drawableSize.height,
                               _modelRender.renderTarget.drawableSize.width);
    
    NSArray* renders = [self exportRenders];
    NSColor* clearColor = [NSColor colorWithRed:_modelPanel.backgroundColor
                                          green:_modelPanel.backgroundColor
                                           blue:_modelPanel.backgroundColor
                                          alpha:1.0];
    
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result)
         {
             if (result == NSModalResponseOK)
             {
                 NuoOffscreenView* offscreen = [[NuoOffscreenView alloc] initWithDevice:commandQueue.device withTarget:previewSize
                                                                         withClearColor:clearColor
                                                                              withScene:renders];
                 NSString* path = savePanel.URL.path;
                 
                 ModelConfiguration configuration;
                 const bool useImageIOSave = configuration.UseImageIO();
                 
                 [offscreen renderWithCommandQueue:commandQueue
                                    withCompletion:^(id<MTLTexture> result)
                                        {
                                            NuoTextureBase* textureBase = [NuoTextureBase getInstance:commandQueue];
                                            
                                            [textureBase setUseImageIO:useImageIOSave];
                                            [textureBase saveTexture:result toImage:path];
                                        }];
             }
         }];
}


- (IBAction)exportLayers:(id)sender
{
    NSString* defaultName = _documentName;
    if (!defaultName)
        defaultName = @" ";
    
    NSSavePanel* savePanel = [NSSavePanel savePanel];
    [savePanel setNameFieldStringValue:defaultName];
    [savePanel setCanSelectHiddenExtension:YES];
    [savePanel setAllowedContentTypes:@[UTTypePNG]];
    
    __weak id<MTLCommandQueue> commandQueue = self.commandQueue;
    __weak ModelRenderer* modelRenderer = _modelRender;
    
    CGFloat previewSize = fmax(_modelRender.renderTarget.drawableSize.height,
                               _modelRender.renderTarget.drawableSize.width);
    
    NSArray* renders = [self exportRenders];
    
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result)
         {
             if (result == NSModalResponseOK)
             {
                 NuoOffscreenView* offscreen = [[NuoOffscreenView alloc] initWithDevice:commandQueue.device withTarget:previewSize
                                                                         withClearColor:[NSColor colorWithRed:0.0
                                                                                                        green:0.0
                                                                                                         blue:0.0
                                                                                                        alpha:0.0]
                                                                              withScene:renders];
                 NSString* path = savePanel.URL.path;
                 NSString* pathBackground = [path stringByDeletingPathExtension];
                 pathBackground = [pathBackground stringByAppendingString:@"-bg.png"];
                 
                 modelRenderer.mainModelMesh.enabled = NO;
                 
                 [offscreen renderWithCommandQueue:self.commandQueue
                                    withCompletion:^(id<MTLTexture> result)
                                      {
                                          NuoTextureBase* textureBase = [NuoTextureBase getInstance:commandQueue];
                                          [textureBase saveTexture:result toImage:pathBackground];
                                      }];
                 
                 modelRenderer.mainModelMesh.enabled = YES;
                 modelRenderer.backdropMesh.enabled = NO;
                 
                 [offscreen renderWithCommandQueue:self.commandQueue
                                    withCompletion:^(id<MTLTexture> result)
                                      {
                                          NuoTextureBase* textureBase = [NuoTextureBase getInstance:commandQueue];
                                          [textureBase saveTexture:result toImage:path];
                                      }];
                 
                 modelRenderer.backdropMesh.enabled = YES;
             }
         }];
}


- (void)resetScene:(id)sender
{
    if (!_modelRender.modelState.viewTransformReset)
    {
        [_modelRender.modelState resetViewTransform];
        [self render];
        
        [_sceneResetMenu setTarget:nil];
        [_sceneResetMenu setAction:nil];
    }
}


- (void)removeObject:(id)sender
{
    [_modelRender removeSelectedMesh];
    
    if (!_modelRender.hasMeshes)
    {
        [_removeObjectMenu setTarget:nil];
        [_removeObjectMenu setAction:nil];
    }
    
    [self modelMeshInvalid];
    [self render];
}


- (IBAction)addBoardObject:(id)sender
{
    BoardSettingsPanel* panel = [BoardSettingsPanel new];
    [panel setRootWindow:self.window];
    
    __weak BoardSettingsPanel* panelWeak = panel;
    __weak ModelRenderer* renderer = _modelRender;
    __weak NSMenuItem* menu = _removeObjectMenu;
    
    [self.window beginSheet:panel completionHandler:^(NSModalResponse returnCode)
     {
         if (returnCode == NSModalResponseOK)
         {
             CGSize size = [panelWeak boardSize];
             if (size.width > 0 && size.height > 0)
             {
                 [renderer createBoard:size withName:panelWeak.boardName];
                 [self modelMeshInvalid];
                 [self render];
                 
                 [menu setTarget:self];
                 [menu setAction:@selector(removeObject:)];
             }
         }
     }];
}


- (IBAction)inspectWindow:(id)sender
{
    OpenInspectPanel* panel = [OpenInspectPanel new];
    [panel setRootWindow:self.window];
    
    __weak OpenInspectPanel* panelWeak = panel;
    
    [self.window beginSheet:panel completionHandler:^(NSModalResponse returnCode)
     {
         if (returnCode == NSModalResponseOK)
         {
             NSString* selected = panelWeak.inspectSelected;
             NuoInspectWindow* window = [[NuoInspectWindow alloc] initWithDevice:self.metalLayer.device
                                                                        withName:selected];
             CGRect frame = self.window.frame;
             frame.origin.x += 50;
             frame.origin.y += 50;
             frame.size.width /= 2.0;
             frame.size.height /= 2.0;
             
             [window setFrame:frame display:YES];
             [window setContentSize:frame.size];
             [window display];
             [window makeKeyAndOrderFront:nil];
             
             [self render];
             
             NuoInspectableMaster* master = [NuoInspectableMaster sharedMaster];
             [master inspect];
         }
     }];
}



@end
