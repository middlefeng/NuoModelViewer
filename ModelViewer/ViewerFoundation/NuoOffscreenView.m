//
//  NuoOffscreenView.m
//  ModelViewer
//
//  Created by middleware on 2/20/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoOffscreenView.h"

#import "NuoRenderPass.h"
#import "NuoRenderPassTarget.h"



@interface NuoOffscreenView()


@property (nonatomic, strong) NuoRenderPassTarget* sceneTarget;
@property (nonatomic, strong) NuoRenderPassTarget* exportTarget;

@property (nonatomic, assign) CGSize drawSize;

@end




@implementation NuoOffscreenView


- (instancetype)initWithDevice:(id<MTLDevice>)device
                    withTarget:(CGSize)drawSize
                     withScene:(NSArray<NuoRenderPass*>*) renderPasses
{
    self = [super init];
    
    if (self)
    {
        _drawSize = drawSize;
        
        NSUInteger lastRender = [renderPasses count] - 1;
        NuoRenderPassTarget* lastTarget = renderPasses[lastRender].renderTarget;
        MTLPixelFormat scenePixelFormat = lastTarget.targetPixelFormat;
        uint sceneSampleCount = lastTarget.sampleCount;
        MTLClearColor clearColor = lastTarget.clearColor;
        
        // privately managed by GPU only, same pixel format and sample-count as scene render
        //
        _sceneTarget = [NuoRenderPassTarget new];
        _sceneTarget.device = device;
        _sceneTarget.sampleCount = sceneSampleCount;
        _sceneTarget.clearColor = clearColor;
        _sceneTarget.manageTargetTexture = YES;
        _sceneTarget.sharedTargetTexture = NO;
        _sceneTarget.targetPixelFormat = scenePixelFormat;
        _sceneTarget.name = @"Scene";
        
        // sharely managed by GPU and CPU, export to RGBA (since PNG need it)
        //
        _exportTarget = [NuoRenderPassTarget new];
        _exportTarget.device = device;
        _exportTarget.sampleCount = 1;
        _exportTarget.clearColor = clearColor;
        _exportTarget.manageTargetTexture = YES;
        _exportTarget.sharedTargetTexture = YES;
        _exportTarget.targetPixelFormat = MTLPixelFormatRGBA8Unorm;
        _exportTarget.name = @"Export";
    }
    
    return self;
}


@end
