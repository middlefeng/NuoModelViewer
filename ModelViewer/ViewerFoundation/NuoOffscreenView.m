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
#import "NuoRenderPipeline.h"
#import "NuoRenderPipelinePass.h"



@interface NuoOffscreenView() < NuoRenderPipelineDelegate >


@property (nonatomic, weak) id<MTLDevice> device;

@property (nonatomic, strong) NuoRenderPassTarget* sceneTarget;
@property (nonatomic, strong) NuoRenderPassTarget* exportTarget;
@property (nonatomic, strong) NSArray* renderPasses;

@property (nonatomic, assign) NSUInteger drawSize;

@end




@implementation NuoOffscreenView


- (instancetype)initWithDevice:(id<MTLDevice>)device
                    withTarget:(NSUInteger)drawSize
                withClearColor:(NSColor*)clearColor
                     withScene:(NSArray<NuoRenderPass*>*) renderPasses
{
    self = [super init];
    
    if (self)
    {
        _drawSize = drawSize;
        _device = device;
        
        _renderPasses = renderPasses;
        
        _renderPipeline = [NuoRenderPipeline new];
        _renderPipeline.renderPipelineDelegate = self;
        _renderPipeline.renderPasses = _renderPasses;
        
        NSUInteger lastRender = [renderPasses count] - 1;
        NuoRenderPassTarget* lastTarget = renderPasses[lastRender].renderTarget;
        MTLPixelFormat scenePixelFormat = lastTarget.targetPixelFormat;
        NSUInteger sceneSampleCount = lastTarget.sampleCount;
        MTLClearColor mtlClearColor = lastTarget.clearColor;
        if (clearColor)
            mtlClearColor = MTLClearColorMake(clearColor.redComponent, clearColor.greenComponent,
                                              clearColor.blueComponent, clearColor.alphaComponent);
        
        
        // privately managed by GPU only, same pixel format and sample-count as scene render
        //
        _sceneTarget = [NuoRenderPassTarget new];
        _sceneTarget.device = device;
        _sceneTarget.sampleCount = sceneSampleCount;
        _sceneTarget.clearColor = mtlClearColor;
        _sceneTarget.manageTargetTexture = YES;
        _sceneTarget.sharedTargetTexture = NO;
        _sceneTarget.targetPixelFormat = scenePixelFormat;
        _sceneTarget.name = @"Scene";
        
        // sharely managed by GPU and CPU, export to RGBA (since PNG need it)
        //
        _exportTarget = [NuoRenderPassTarget new];
        _exportTarget.device = device;
        _exportTarget.sampleCount = 1;
        _exportTarget.clearColor = mtlClearColor;
        _exportTarget.manageTargetTexture = YES;
        _exportTarget.sharedTargetTexture = YES;
        _exportTarget.targetPixelFormat = MTLPixelFormatRGBA8Unorm;
        _exportTarget.name = @"Export";
    }
    
    return self;
}


- (id<MTLTexture>)nextFinalTexture
{
    return _sceneTarget.targetTexture;
}



- (void)renderWithCommandQueue:(id<MTLCommandBuffer>)commandBuffer
                withCompletion:(void (^)(id<MTLTexture>))completionBlock;
{
    // final pass to convert the result to RGBA
    NuoRenderPipelinePass* finalPass = [[NuoRenderPipelinePass alloc] initWithCommandQueue:commandBuffer.commandQueue
                                                                           withPixelFormat:_exportTarget.targetPixelFormat
                                                                           withSampleCount:1 /* no MSAA for mere conversion */];
    NSUInteger lastRender = [_renderPasses count] - 1;
    NuoRenderPass* lastScenePass = _renderPasses[lastRender];
    NuoRenderPassTarget* displayTarget = [lastScenePass renderTarget];
    CGSize displaySize = [displayTarget drawableSize];
    
    CGFloat aspectRation = displaySize.width / displaySize.height;
    CGFloat drawEdge = _drawSize;
    if (displaySize.width < displaySize.height)
        drawEdge = drawEdge * aspectRation;
    CGSize drawSize = CGSizeMake(drawEdge, drawEdge / aspectRation);
    
    [lastScenePass setRenderTarget:_sceneTarget];
    [_renderPipeline setDrawableSize:drawSize];
    
    if (![_renderPipeline renderWithCommandBuffer:commandBuffer inFlight:0])
        assert(false);
    
    [finalPass setSourceTexture:_sceneTarget.targetTexture];
    [finalPass setRenderTarget:_exportTarget];
    [finalPass setDrawableSize:drawSize];
    [finalPass drawWithCommandBuffer:commandBuffer withInFlightIndex:0];
    
    id<MTLBlitCommandEncoder> encoder = [commandBuffer blitCommandEncoder];
    [encoder synchronizeResource:_exportTarget.targetTexture];
    [encoder endEncoding];
    
    __block id<MTLTexture> result = _exportTarget.targetTexture;
    
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer)
     {
         completionBlock(result);
     }];
    
    [commandBuffer commit];
    
    [lastScenePass setRenderTarget:displayTarget];
    [lastScenePass setDrawableSize:displaySize];
}


@end
