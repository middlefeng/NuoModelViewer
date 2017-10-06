//
//  ModelView.m
//  ModelViewer
//
//  Created by middleware on 8/26/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "ModelView.h"

#import "ModelComponentPanels.h"
#import "ModelOperationPanel.h"
#import "LightOperationPanel.h"
#import "BoardSettingsPanel.h"

#import "ModelViewerRenderer.h"
#import "ModelDissectRenderer.h"
#import "NotationRenderer.h"

#import "NuoLua.h"
#import "NuoMeshOptions.h"
#import "NuoLightSource.h"

#import "NuoMeshCompound.h"
#import "NuoCubeMesh.h"
#import "NuoMeshRotation.h"
#import "NuoMeshAnimation.h"
#import "NuoTextureBase.h"

#include "NuoOffscreenView.h"



typedef enum
{
    kDrag_Shift_X,
    kDrag_Shift_Y,
    kDrag_Normal,
}
MouseDragMode;



@interface ModelView() <ModelOptionUpdate>

@end




@implementation ModelView
{
    NuoLua* _lua;
    ModelRenderer* _modelRender;
    ModelDissectRenderer* _modelDissectRenderer;
    NotationRenderer* _notationRender;
    NSArray<NuoRenderPass*>* _renders;
    
    NSMutableArray<NuoMeshAnimation*>* _animations;
    
    ModelComponentPanels* _modelComponentPanels;
    ModelOperationPanel* _modelPanel;
    LightOperationPanel* _lightPanel;
    
    BOOL _trackingLighting;
    BOOL _trackingSplitView;
    BOOL _mouseMoved;
    MouseDragMode _mouseDragMode;
    
    IBOutlet NSMenuItem* _sceneResetMenu;
    IBOutlet NSMenuItem* _removeObjectMenu;
    
    NSString* _documentName;
}



- (NuoLua*)lua
{
    if (!_lua)
        _lua = [[NuoLua alloc] init];
    
    return _lua;
}


- (NSRect)operationPanelLocation
{
    NSRect viewRect = [self frame];
    NSSize panelSize = NSMakeSize(225, 346);
    NSSize panelMargin = NSMakeSize(15, 25);
    NSPoint panelOrigin = NSMakePoint(viewRect.size.width - panelMargin.width - panelSize.width,
                                      viewRect.size.height - panelMargin.height - panelSize.height);
    
    NSRect panelRect;
    panelRect.origin = panelOrigin;
    panelRect.size = panelSize;
    
    return panelRect;
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
    [_modelComponentPanels setMesh:_modelRender.mainModelMesh.meshes];
    [_animations removeAllObjects];
    [_modelPanel setModelPartAnimations:_animations];
    
    if (_modelPanel.meshMode == kMeshMode_Normal)
    {
        [_modelDissectRenderer setDissectMeshes:nil];
    }
    else
    {
        NSArray<NuoMesh*>* dissectMeshes = [_modelRender cloneMeshesFor:_modelPanel.meshMode];
        [_modelDissectRenderer setDissectMeshes:dissectMeshes];
    }
}


- (void)modelUpdate:(NuoMeshOption *)meshOptions
{
    if (meshOptions)
    {
        [_modelRender setModelOptions:meshOptions withCommandQueue:[self commandQueue]];
        [self modelMeshInvalid];
    }
    
    [self render];
}


- (void)modelOptionUpdate:(ModelOperationPanel *)panel
{
    if (panel)
    {
        [_modelComponentPanels setHidden:![panel showModelParts]];
        
        [_modelRender setCullEnabled:[panel cullEnabled]];
        [_modelRender setFieldOfView:[panel fieldOfViewRadian]];
        [_modelRender setAmbientDensity:[panel ambientDensity]];
        [_modelRender setTransMode:[panel transformMode]];
        [self setupPipelineSettings];
        
        for (NuoMeshAnimation* animation in _animations)
            [animation setProgress:panel.animationProgress];
        
        if (panel.meshMode == kMeshMode_Normal)
            [self.window setAcceptsMouseMovedEvents:NO];
        else
            [self.window setAcceptsMouseMovedEvents:YES];
    }
    
    [_modelComponentPanels updatePanels];
    
    [self render];
}



- (void)animationLoad
{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    openPanel.allowedFileTypes = @[@"anm"];
    
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result)
         {
             if (result == NSFileHandlingPanelOKButton)
             {
                 NuoLua* lua = [self lua];
                 [lua loadFile:openPanel.URL.path];
                 NSArray* keys = [lua getKeysFromTable:-1];
                 
                 NSMutableArray<NuoMeshAnimation*>* animations = [[NSMutableArray alloc] init];
                 for (NSString* key in keys)
                 {
                     NuoMeshAnimation* current = [NuoMeshAnimation new];
                     current.animationName = key;
                     
                     [lua getField:key fromTable:-1];
                     [current importAnimation:lua forMesh:_modelRender.mainModelMesh.meshes];
                     [lua removeField];
                     
                     if (current.mesh.count)
                         [animations addObject:current];
                 }
                 
                 _animations = animations;
                 [_modelPanel setModelPartAnimations:_animations];
             }
         }];
}



- (void)lightOptionUpdate:(LightOperationPanel*)panel;
{
    _notationRender.density = [panel lightDensity];
    _notationRender.spacular = [panel lightSpacular];
    _notationRender.shadowSoften = [panel shadowSoften];
    _notationRender.shadowOccluderRadius = [panel shadowOccluderRadius];
    _notationRender.shadowBias = [panel shadowBias];
    [self render];
}



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
    
    _modelRender = [[ModelRenderer alloc] initWithDevice:self.metalLayer.device];
    _modelDissectRenderer = [[ModelDissectRenderer alloc] initWithDevice:self.metalLayer.device];
    _modelDissectRenderer.paramsProvider = _modelRender;
    _modelDissectRenderer.splitViewProportion = 0.5;
    _notationRender = [[NotationRenderer alloc] initWithDevice:self.metalLayer.device];
    _notationRender.notationWidthCap = [self operationPanelLocation].size.width + 30;
    
    // sync the model renderer with the initial settings in the model panel
    //
    [self modelOptionUpdate:_modelPanel];
    [self modelUpdate:_modelPanel.meshOptions];
    
    // sync the light panel with the current initial light vector in the
    // notation renderer
    //
    [_lightPanel updateControls:_notationRender.selectedLightSource];
    
    [self setupPipelineSettings];
    [self registerForDraggedTypes:@[@"public.data"]];
}


- (NSRect)lightPanelRect
{
    const CGFloat margin = 10;
    
    CGRect area = [_notationRender notationArea];
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
    if (_modelPanel.showLightSettings)
    {
        if (_modelPanel.meshMode == kMeshMode_Normal)
        {
            _renders = [[NSArray alloc] initWithObjects:_modelRender, _notationRender, nil];
        }
        else
        {
            _renders = [[NSArray alloc] initWithObjects:_modelRender, _modelDissectRenderer, _notationRender, nil];
            _modelDissectRenderer.dissectMeshes = [_modelRender cloneMeshesFor:_modelPanel.meshMode];
            
            NuoRenderPassTarget* modelDissectTarget = [NuoRenderPassTarget new];
            modelDissectTarget.device = self.metalLayer.device;
            modelDissectTarget.sampleCount = kSampleCount;
            modelDissectTarget.clearColor = MTLClearColorMake(0.95, 0.95, 0.95, 1);
            modelDissectTarget.manageTargetTexture = YES;
            modelDissectTarget.name = @"Model-Dissect";
            
            [_modelDissectRenderer setRenderTarget:modelDissectTarget];
        }
        
        NuoRenderPassTarget* modelRenderTarget = [NuoRenderPassTarget new];
        modelRenderTarget.device = self.metalLayer.device;
        modelRenderTarget.sampleCount = 1;
        modelRenderTarget.clearColor = MTLClearColorMake(0.95, 0.95, 0.95, 1);
        modelRenderTarget.manageTargetTexture = YES;
        modelRenderTarget.name = @"Model";
        
        [_modelRender setRenderTarget:modelRenderTarget];
        
        NuoRenderPassTarget* notationRenderTarget = [NuoRenderPassTarget new];
        notationRenderTarget.device = self.metalLayer.device;
        notationRenderTarget.sampleCount = kSampleCount;
        notationRenderTarget.clearColor = MTLClearColorMake(0.95, 0.95, 0.95, 1);
        notationRenderTarget.manageTargetTexture = NO;
        notationRenderTarget.name = @"Notation";
        
        [_notationRender setRenderTarget:notationRenderTarget];
    }
    else
    {
        if (_modelPanel.meshMode == kMeshMode_Normal)
        {
            _renders = [[NSArray alloc] initWithObjects:_modelRender, nil];
        }
        else
        {
            _renders = [[NSArray alloc] initWithObjects:_modelRender, _modelDissectRenderer, nil];
            _modelDissectRenderer.dissectMeshes = [_modelRender cloneMeshesFor:_modelPanel.meshMode];
            
            NuoRenderPassTarget* modelDissectTarget = [NuoRenderPassTarget new];
            modelDissectTarget.device = self.metalLayer.device;
            modelDissectTarget.sampleCount = kSampleCount;
            modelDissectTarget.clearColor = MTLClearColorMake(0.95, 0.95, 0.95, 1);
            modelDissectTarget.manageTargetTexture = NO;
            modelDissectTarget.name = @"Model-Dissect";
            
            [_modelDissectRenderer setRenderTarget:modelDissectTarget];
        }
        
        NuoRenderPassTarget* modelRenderTarget = [NuoRenderPassTarget new];
        modelRenderTarget.device = self.metalLayer.device;
        modelRenderTarget.sampleCount = 1;
        modelRenderTarget.clearColor = MTLClearColorMake(0.95, 0.95, 0.95, 1);
        modelRenderTarget.manageTargetTexture = (_modelPanel.meshMode != kMeshMode_Normal);
        modelRenderTarget.name = @"Model";
        
        [_modelRender setRenderTarget:modelRenderTarget];
    }

    [_lightPanel setHidden:!_modelPanel.showLightSettings];
    
    [self setRenderPasses:_renders];
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
        
        CGRect lightSettingArea = _notationRender.notationArea;
        _trackingLighting = CGRectContainsPoint(lightSettingArea, location);
        
        if (_trackingLighting)
        {
            [_notationRender selectCurrentLightVector:location];
            NuoLightSource* source = _notationRender.selectedLightSource;
            
            [_lightPanel updateControls:source];
        }
    }
    else
    {
        _trackingLighting = NO;
    }
    
    _mouseMoved = NO;
}


- (void)mouseUp:(NSEvent *)event
{
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
        NuoLightSource* lightSource = _notationRender.selectedLightSource;
        [_notationRender setRotateX:lightSource.lightingRotationX + deltaX];
        [_notationRender setRotateY:lightSource.lightingRotationY + deltaY];
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
    
    [self render];
}


- (void)magnifyWithEvent:(NSEvent *)event
{
    _modelRender.zoomDelta = 10 * event.magnification;
    [self render];
}



- (void)scrollWheel:(NSEvent *)event
{
    _modelRender.transXDelta = -event.deltaX;
    _modelRender.transYDelta = event.deltaY;
    [self render];
}


- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    NSPasteboard* paste = [sender draggingPasteboard];
    NSArray *draggedFilePaths = [paste propertyListForType:NSFilenamesPboardType];
    
    if (draggedFilePaths.count > 0)
    {
        NSString* path = draggedFilePaths[0];
        if ([path hasSuffix:@".obj"])
        {
            return NSDragOperationGeneric;
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
                return [manager fileExistsAtPath:filePath];
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
    NSArray *draggedFilePaths = [paste propertyListForType:NSFilenamesPboardType];
    NSString* path = draggedFilePaths[0];
    
    NSFileManager* manager = [NSFileManager defaultManager];
    BOOL isDir = false;
    
    [manager fileExistsAtPath:path isDirectory:&isDir];
    if (isDir)
    {
        NSString* name = [path lastPathComponent];
        name = [name stringByAppendingString:@".obj"];
        path = [path stringByAppendingPathComponent:name];
    }
    
    [self loadMesh:path];
    [self render];
    return YES;
}



- (void)render
{
    _modelRender.lights = _notationRender.lightSources;
    
    if (!_modelRender.viewTransformReset)
    {
        [_sceneResetMenu setTarget:self];
        [_sceneResetMenu setAction:@selector(resetScene:)];
    }
    
    [super render];
}



- (void)loadMesh:(NSString*)path
{
    [_modelRender loadMesh:path withCommandQueue:[self commandQueue]];
    [self modelMeshInvalid];
    
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
    [lua loadFile:path];
    
    CGSize drawableSize;
    [lua getField:@"canvas" fromTable:-1];
    drawableSize.width = [lua getFieldAsNumber:@"width" fromTable:-1];
    drawableSize.height = [lua getFieldAsNumber:@"height" fromTable:-1];
    [lua removeField];
    
    NSWindow* window = self.window;
    [window setContentSize:drawableSize];
    
    [_modelRender importScene:lua];
    [_notationRender importScene:lua];
    [_lightPanel updateControls:_notationRender.selectedLightSource];
    
    [_modelComponentPanels setMesh:_modelRender.mainModelMesh.meshes];
    [_modelPanel setFieldOfViewRadian:_modelRender.fieldOfView];
    [_modelPanel setAmbientDensity:_modelRender.ambientDensity];
    [_modelPanel updateControls];
}



- (IBAction)openFile:(id)sender
{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    openPanel.allowedFileTypes = @[@"obj", @"scn"];
    
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result)
            {
                if (result == NSFileHandlingPanelOKButton)
                {
                    NSString* path = openPanel.URL.path;
                    NSString* ext = path.pathExtension;
                    
                    if ([ext isEqualToString:@"obj"])
                        [self loadMesh:path];
                    
                    if ([ext isEqualToString:@"scn"])
                        [self loadScene:path];
                    
                    [self render];
                }
            }];
}



- (IBAction)loadCube:(id)sender
{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    openPanel.allowedFileTypes = @[@"jpg", @"png"];
    
    __weak __block id<MTLDevice> device = self.metalLayer.device;
    
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result)
             {
                 if (result == NSFileHandlingPanelOKButton)
                 {
                     NSString* path = openPanel.URL.path;
                     
                     NuoCubeMesh* cubeMesh = [[NuoCubeMesh alloc] initWithDevice:device];
                     NuoTextureBase* base = [NuoTextureBase getInstance:device];
                     cubeMesh.cubeTexture = [base textureCubeWithImageNamed:path];
                         
                     [cubeMesh makeDepthStencilState];
                     [cubeMesh makePipelineAndSampler:MTLPixelFormatBGRA8Unorm];
                 
                     [_modelRender setCubeMesh:cubeMesh];
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
    [savePanel setAllowedFileTypes:@[@"scn"]];
    
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result)
             {
                 if (result == NSFileHandlingPanelOKButton)
                 {
                     NSString* path = savePanel.URL.path;
                     NSString* result = [_modelRender exportSceneAsString:[self.window contentView].frame.size];
                     const char* pathStr = path.UTF8String;
                     
                     FILE* file = fopen(pathStr, "w");
                     fwrite(result.UTF8String, sizeof(char), result.length, file);
                     fclose(file);
                 }
             }];
        }


- (IBAction)exportPNG:(id)sender
{
    NSString* defaultName = _documentName;
    if (!defaultName)
        defaultName = @" ";
    
    NSSavePanel* savePanel = [NSSavePanel savePanel];
    [savePanel setNameFieldStringValue:defaultName];
    [savePanel setCanSelectHiddenExtension:YES];
    [savePanel setAllowedFileTypes:@[@"png"]];
    
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result)
     {
         if (result == NSFileHandlingPanelOKButton)
         {
             __block __weak id<MTLDevice> device = self.metalLayer.device;
             
             CGFloat previewSize = fmax(_modelRender.renderTarget.drawableSize.height,
                                        _modelRender.renderTarget.drawableSize.width);
             
             NuoOffscreenView* offscreen = [[NuoOffscreenView alloc] initWithDevice:device withTarget:previewSize
                                                                          withClearColor:[NSColor colorWithRed:0.0
                                                                                                         green:0.0
                                                                                                          blue:0.0
                                                                                                         alpha:0.0]
                                                                          withScene:@[_modelRender]];
             NSString* path = savePanel.URL.path;
             
             [offscreen renderWithCommandQueue:[self.commandQueue commandBuffer]
                                withCompletion:^(id<MTLTexture> result)
                                    {
                                        NuoTextureBase* textureBase = [NuoTextureBase getInstance:device];
                                        [textureBase saveTexture:result toImage:path];
                                    }];
         }
     }];
}


- (void)resetScene:(id)sender
{
    if (!_modelRender.viewTransformReset)
    {
        [_modelRender resetViewTransform];
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
    
    [self render];
}


- (IBAction)addBoardObject:(id)sender
{
    BoardSettingsPanel* panel = [BoardSettingsPanel new];
    [panel setRootWindow:self.window];
    
    __weak BoardSettingsPanel* panelWeak = panel;
    __weak ModelRenderer* renderer = _modelRender;
    
    [self.window beginSheet:panel completionHandler:^(NSModalResponse returnCode)
     {
         if (returnCode == NSModalResponseOK)
         {
             CGSize size = [panelWeak boardSize];
             if (size.width > 0 && size.height > 0)
             {
                 [renderer createBoard:size];
                 [self render];
                 
                 [_removeObjectMenu setTarget:self];
                 [_removeObjectMenu setAction:@selector(removeObject:)];
             }
         }
     }];
}



@end
