//
//  ModelView.m
//  ModelViewer
//
//  Created by middleware on 8/26/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "ModelView.h"
#import "ModelViewerRenderer.h"
#import "ModelOperationPanel.h"

#include "NuoMeshOptions.h"



@interface ModelView() <ModelOptionUpdate>

@end




@implementation ModelView
{
    ModelRenderer* _render;
    ModelOperationPanel* _panel;
}



- (NSRect)operationPanelLocation
{
    NSRect viewRect = [self frame];
    NSSize panelSize = NSMakeSize(225, 192);
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
    
    [_render setModelOptions:options];
    [self render];
}


- (void)modelOptionUpdate:(ModelOperationPanel *)panel
{
    [_render setCullEnabled:[panel cullEnabled]];
    [_render setFieldOfView:[panel fieldOfViewRadian]];
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
    _render = [ModelRenderer new];
    self.delegate = _render;
    
    [self registerForDraggedTypes:@[@"public.data"]];
}


- (void)mouseDragged:(NSEvent *)theEvent
{
    ModelRenderer* renderer = (ModelRenderer*)_render;
    
    renderer.rotationXDelta = -0.01 * M_PI * theEvent.deltaY;
    renderer.rotationYDelta = -0.01 * M_PI * theEvent.deltaX;
    [self render];
}


- (void)magnifyWithEvent:(NSEvent *)event
{
    ModelRenderer* renderer = (ModelRenderer*)_render;
    renderer.zoom += 10 * event.magnification;
    [self render];
}



- (void)scrollWheel:(NSEvent *)event
{
    ModelRenderer* renderer = (ModelRenderer*)_render;
    renderer.transX -= event.deltaX;
    renderer.transY += event.deltaY;
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
    ModelRenderer* renderer = (ModelRenderer*)_render;
    
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
    
    [renderer loadMesh:path];
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
                    [_render loadMesh:path];
                    [self render];
                }
            }];
}



@end
