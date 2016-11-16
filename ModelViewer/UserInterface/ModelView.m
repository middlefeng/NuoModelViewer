//
//  ModelView.m
//  ModelViewer
//
//  Created by middleware on 8/26/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "ModelView.h"
#import "ModelOperationPanel.h"

#import "ModelViewerRenderer.h"
#import "NotationRenderer.h"

#include "NuoMeshOptions.h"



@interface ModelView() <ModelOptionUpdate>

@end




@implementation ModelView
{
    ModelRenderer* _modelRender;
    NotationRenderer* _notationRender;
    NSArray<NuoRenderPass*>* _renders;
    
    ModelOperationPanel* _panel;
    
    BOOL _trackingLighting;
}



- (NSRect)operationPanelLocation
{
    NSRect viewRect = [self frame];
    NSSize panelSize = NSMakeSize(225, 226);
    NSSize panelMargin = NSMakeSize(15, 25);
    NSPoint panelOrigin = NSMakePoint(viewRect.size.width - panelMargin.width - panelSize.width,
                                      viewRect.size.height - panelMargin.height - panelSize.height);
    
    NSRect panelRect;
    panelRect.origin = panelOrigin;
    panelRect.size = panelSize;
    
    return panelRect;
}



- (void)addOperationPanel
{
    NSRect panelRect = [self operationPanelLocation];
    
    _panel = [ModelOperationPanel new];
    _panel.frame = panelRect;
    _panel.layer.opacity = 0.8f;
    _panel.layer.backgroundColor = [NSColor colorWithWhite:1.0 alpha:1.0].CGColor;
    
    [_panel addCheckbox];
    [_panel setOptionUpdateDelegate:self];
    
    [self addSubview:_panel];
}


- (void)modelUpdate:(ModelOperationPanel *)panel
{
    NuoMeshOption* options = [NuoMeshOption new];
    [options setBasicMaterialized:[panel basicMaterialized]];
    [options setTextured:[panel textured]];
    [options setTextureEmbeddingMaterialTransparency:[panel textureEmbeddingMaterialTransparency]];
    [options setCombineShapes:[panel combineShapes]];
    
    [_modelRender setModelOptions:options];
    [self render];
}


- (void)modelOptionUpdate:(ModelOperationPanel *)panel
{
    [_modelRender setCullEnabled:[panel cullEnabled]];
    [_modelRender setFieldOfView:[panel fieldOfViewRadian]];
    [self setupPipelineSettings];
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
    
    if (!_panel)
    {
        [self addOperationPanel];
    }
    
    [_panel setFrame:[self operationPanelLocation]];
}



- (void)commonInit
{
    [super commonInit];
    
    _modelRender = [[ModelRenderer alloc] initWithDevice:self.metalLayer.device];
    _notationRender = [[NotationRenderer alloc] initWithDevice:self.metalLayer.device];
    
    [self setupPipelineSettings];
    
    [self registerForDraggedTypes:@[@"public.data"]];
}


- (void)setupPipelineSettings
{
    if (_panel.showLightSettings)
    {
        _renders = [[NSArray alloc] initWithObjects:_modelRender, _notationRender, nil];
        
        NuoRenderPassTarget* modelRenderTarget = [NuoRenderPassTarget new];
        modelRenderTarget.device = self.metalLayer.device;
        modelRenderTarget.sampleCount = kSampleCount;
        modelRenderTarget.clearColor = MTLClearColorMake(0.95, 0.95, 0.95, 1);
        modelRenderTarget.manageTargetTexture = YES;
        
        [_modelRender setRenderTarget:modelRenderTarget];
        
        NuoRenderPassTarget* notationRenderTarget = [NuoRenderPassTarget new];
        notationRenderTarget.device = self.metalLayer.device;
        notationRenderTarget.sampleCount = 1;
        notationRenderTarget.clearColor = MTLClearColorMake(0.95, 0.95, 0.95, 1);
        notationRenderTarget.manageTargetTexture = NO;
        
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
        
        [_modelRender setRenderTarget:modelRenderTarget];
    }
    
    [self setRenderPasses:_renders];
    [self viewResizing];
}


- (void)mouseDown:(NSEvent *)event
{
    if (_panel.showLightSettings)
    {
        NSPoint location = event.locationInWindow;
        location = [self convertPoint:location fromView:nil];
        
        CGRect lightSettingArea = _notationRender.notationArea;
        _trackingLighting = CGRectContainsPoint(lightSettingArea, location);
    }
    else
    {
        _trackingLighting = NO;
    }
}


- (void)mouseUp:(NSEvent *)event
{
    _trackingLighting = NO;
}


- (void)mouseDragged:(NSEvent *)theEvent
{
    float deltaX = -0.01 * M_PI * theEvent.deltaY;
    float deltaY = -0.01 * M_PI * theEvent.deltaX;
    
    if (_trackingLighting)
    {
        _notationRender.rotateX += deltaX;
        _notationRender.rotateY += deltaY;
        _modelRender.lightingRotationX = _notationRender.rotateX;
        _modelRender.lightingRotationY = _notationRender.rotateY;
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
    
    [_modelRender loadMesh:path];
    [self render];
    return YES;
}



- (IBAction)openFile:(id)sender
{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result)
            {
                if (result == NSFileHandlingPanelOKButton)
                {
                    NSString* path = openPanel.URL.path;
                    [_modelRender loadMesh:path];
                    [self render];
                }
            }];
}



@end
