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

#import "ModelViewerRenderer.h"
#import "NotationRenderer.h"

#import "NuoLua.h"
#import "NuoMeshOptions.h"
#import "LightSource.h"



@interface ModelView() <ModelOptionUpdate>

@end




@implementation ModelView
{
    NuoLua* _lua;
    ModelRenderer* _modelRender;
    NotationRenderer* _notationRender;
    NSArray<NuoRenderPass*>* _renders;
    
    ModelComponentPanels* _modelComponentPanels;
    ModelOperationPanel* _modelPanel;
    LightOperationPanel* _lightPanel;
    
    BOOL _trackingLighting;
    
    NSString* _documentName;
}



- (NuoLua*)lua
{
    if (!_lua)
        _lua = [[NuoLua alloc] init];
    
    return _lua;
}


- (NSRect)modelPartsPanelLocation
{
    NSRect viewRect = [self frame];
    NSSize listSize = NSMakeSize(225, 315);
    NSSize listMargin = NSMakeSize(15, 25);
    
    NSRect listRect;
    listRect.origin = NSMakePoint(listMargin.width, viewRect.size.height - listSize.height - listMargin.height);
    listRect.size = listSize;
    
    return listRect;
}


- (NSRect)operationPanelLocation
{
    NSRect viewRect = [self frame];
    NSSize panelSize = NSMakeSize(225, 315);
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


- (void)modelUpdate:(ModelOperationPanel *)panel
{
    if (panel)
    {
        NuoMeshOption* options = panel.meshOptions;
        [_modelRender setModelOptions:options withCommandQueue:[self commandQueue]];
    }
    
    [_modelComponentPanels setMesh:_modelRender.mesh];
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
        [self setupPipelineSettings];
    }
    
    [self render];
}



- (void)lightOptionUpdate:(LightOperationPanel*)panel;
{
    _notationRender.density = [panel lightDensity];
    _notationRender.spacular = [panel lightSpacular];
    _notationRender.shadowSoften = [panel shadowSoften];
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
    _notationRender = [[NotationRenderer alloc] initWithDevice:self.metalLayer.device];
    _notationRender.notationWidthCap = [self operationPanelLocation].size.width + 30;
    
    // sync the model renderer with the initial settings in the model panel
    //
    [self modelOptionUpdate:_modelPanel];
    [self modelUpdate:_modelPanel];
    
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
        _renders = [[NSArray alloc] initWithObjects:_modelRender, _notationRender, nil];
        
        NuoRenderPassTarget* modelRenderTarget = [NuoRenderPassTarget new];
        modelRenderTarget.device = self.metalLayer.device;
        modelRenderTarget.sampleCount = kSampleCount;
        modelRenderTarget.clearColor = MTLClearColorMake(0.95, 0.95, 0.95, 1);
        modelRenderTarget.manageTargetTexture = YES;
        modelRenderTarget.name = @"Model";
        
        [_modelRender setRenderTarget:modelRenderTarget];
        
        NuoRenderPassTarget* notationRenderTarget = [NuoRenderPassTarget new];
        notationRenderTarget.device = self.metalLayer.device;
        notationRenderTarget.sampleCount = 1;
        notationRenderTarget.clearColor = MTLClearColorMake(0.95, 0.95, 0.95, 1);
        notationRenderTarget.manageTargetTexture = NO;
        notationRenderTarget.name = @"Notation";
        
        [_notationRender setRenderTarget:notationRenderTarget];
    }
    else
    {
        _renders = [[NSArray alloc] initWithObjects:_modelRender, nil];
        
        NuoRenderPassTarget* modelRenderTarget = [NuoRenderPassTarget new];
        modelRenderTarget.device = self.metalLayer.device;
        modelRenderTarget.sampleCount = kSampleCount;
        modelRenderTarget.clearColor = MTLClearColorMake(0.95, 0.95, 0.95, 1);
        modelRenderTarget.manageTargetTexture = NO;
        modelRenderTarget.name = @"Model";
        
        [_modelRender setRenderTarget:modelRenderTarget];
    }

    [_lightPanel setHidden:!_modelPanel.showLightSettings];
    
    [self setRenderPasses:_renders];
    [self viewResizing];
}


- (void)mouseDown:(NSEvent *)event
{
    if (_modelPanel.showLightSettings)
    {
        NSPoint location = event.locationInWindow;
        location = [self convertPoint:location fromView:nil];
        
        CGRect lightSettingArea = _notationRender.notationArea;
        _trackingLighting = CGRectContainsPoint(lightSettingArea, location);
        
        if (_trackingLighting)
        {
            [_notationRender selectCurrentLightVector:location];
            LightSource* source = _notationRender.selectedLightSource;
            
            [_lightPanel updateControls:source];
        }
    }
    else
    {
        _trackingLighting = NO;
    }
}


- (void)mouseUp:(NSEvent *)event
{
    _trackingLighting = NO;
    [self render];
}


- (void)mouseDragged:(NSEvent *)theEvent
{
    float deltaX = -0.01 * M_PI * theEvent.deltaY;
    float deltaY = -0.01 * M_PI * theEvent.deltaX;
    
    if (_trackingLighting)
    {
        LightSource* lightSource = _notationRender.selectedLightSource;
        [_notationRender setRotateX:lightSource.lightingRotationX + deltaX];
        [_notationRender setRotateY:lightSource.lightingRotationY + deltaY];
    }
    else
    {
        _modelRender.rotationXDelta = deltaX;
        _modelRender.rotationYDelta = deltaY;
    }
    
    [self render];
}


- (void)magnifyWithEvent:(NSEvent *)event
{
    _modelRender.zoom += 10 * event.magnification;
    [self render];
}



- (void)scrollWheel:(NSEvent *)event
{
    _modelRender.transX -= event.deltaX;
    _modelRender.transY += event.deltaY;
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
    [super render];
}



- (void)loadMesh:(NSString*)path
{
    [_modelRender loadMesh:path withCommandQueue:[self commandQueue]];
    [_modelComponentPanels setMesh:_modelRender.mesh];
    
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
    
    [_modelComponentPanels setMesh:_modelRender.mesh];
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



@end
