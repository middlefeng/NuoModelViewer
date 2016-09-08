//
//  ModelView.m
//  ModelViewer
//
//  Created by middleware on 8/26/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "ModelView.h"
#import "ModelViewerRenderer.h"

#include "NuoTypes.h"



@implementation ModelView
{
    ModelRenderer* _render;
    
    NSPopUpButton* _renderMode;
}




- (void)viewResizing
{
    [super viewResizing];
    
    NSRect viewRect = [self frame];
    NSSize popupSize = NSMakeSize(150, 25);
    NSSize popupMargin = NSMakeSize(10, 10);
    NSPoint popupOrigin = NSMakePoint(viewRect.size.width - popupMargin.width - popupSize.width,
                                      viewRect.size.height - popupMargin.height - popupSize.height);
    
    NSRect popupRect;
    popupRect.origin = popupOrigin;
    popupRect.size = popupSize;
    
    if (!_renderMode)
    {
        _renderMode = [NSPopUpButton new];
        [_renderMode addItemsWithTitles:@[@"Simple", @"Texture", @"Texture with Transparency",
                                          @"Texture and Material", @"Material"]];
    }
    
    [_renderMode setFrame:popupRect];
    [_renderMode setTarget:self];
    [_renderMode setAction:@selector(renderModeSelected:)];
}



- (void)commonInit
{
    [super commonInit];
    _render = [ModelRenderer new];
    self.delegate = _render;
    
    [self addSubview:_renderMode];
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
    renderer.transX += event.deltaX * 0.1;
    renderer.transY -= event.deltaY * 0.1;
    [self render];
}



- (NSString*)renderMode
{
    NSString* renderMode = [NSString stringWithUTF8String:kNuoModelType_Simple];
    
    NSString* selectedItem = [_renderMode titleOfSelectedItem];
    if ([selectedItem isEqualToString:@"Simple"])
        renderMode =  [NSString stringWithUTF8String:kNuoModelType_Simple];
    else if ([selectedItem isEqualToString:@"Texture"])
        renderMode = [NSString stringWithUTF8String:kNuoModelType_Textured];
    else if ([selectedItem isEqualToString:@"Texture with Transparency"])
        renderMode = [NSString stringWithUTF8String:kNuoModelType_Textured_Transparency];
    else if ([selectedItem isEqualToString:@"Texture and Material"])
        renderMode = [NSString stringWithUTF8String:kNuoModelType_Textured_Materialed];
    else if ([selectedItem isEqualToString:@"Material"])
        renderMode = [NSString stringWithUTF8String:kNuoModelType_Materialed];
    
    return renderMode;
}



- (void)renderModeSelected:(id)sender
{
    [_render setType:[self renderMode]];
    [self render];
}



- (IBAction)openFile:(id)sender
{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result)
            {
                if (result == NSFileHandlingPanelOKButton)
                {
                    NSString* path = openPanel.URL.path;
                    [_render loadMesh:path withType:nil];
                    [self render];
                }
            }];
}



@end
