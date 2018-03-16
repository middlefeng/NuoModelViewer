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

/**
 *  temporarily set during rendering for the pipeline's calling back
 */
@property (nonatomic, weak) NuoRenderPassTarget* sceneTarget;

@property (nonatomic, strong) NSArray<NuoRenderPass*>* renderPasses;
@property (nonatomic, strong) NSColor* clearColor;

@property (nonatomic, assign) NSUInteger drawSize;

@end




@implementation NuoOffscreenView


- (instancetype)initWithDevice:(id<MTLDevice>)device
                    withTarget:(NSUInteger)drawSize
                withClearColor:(NSColor*)clearColor
                     withScene:(NSArray<NuoRenderPass*>*)renderPasses
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
        
        _clearColor = clearColor;
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
    NSUInteger lastRender = [_renderPasses count] - 1;
    NuoRenderPass* lastScenePass = _renderPasses[lastRender];
    NuoRenderPassTarget* lastTarget = lastScenePass.renderTarget;
    MTLPixelFormat scenePixelFormat = lastTarget.targetPixelFormat;
    uint sceneSampleCount = lastTarget.sampleCount;
    MTLClearColor mtlClearColor = lastTarget.clearColor;
    if (_clearColor)
        mtlClearColor = MTLClearColorMake(_clearColor.redComponent, _clearColor.greenComponent,
                                          _clearColor.blueComponent, _clearColor.alphaComponent);
    
    // privately managed by GPU only, same pixel format and sample-count as scene render
    //
    NuoRenderPassTarget* sceneTarget = [[NuoRenderPassTarget alloc] initWithDevice:commandBuffer.device
                                                                   withPixelFormat:scenePixelFormat
                                                                   withSampleCount:sceneSampleCount];
    sceneTarget.manageTargetTexture = YES;
    sceneTarget.sharedTargetTexture = NO;
    sceneTarget.name = @"Scene";
    
    // sharely managed by GPU and CPU, export to RGBA (since PNG need it)
    //
    NuoRenderPassTarget* exportTarget = [[NuoRenderPassTarget alloc] initWithDevice:commandBuffer.device
                                                                    withPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                    withSampleCount:1];
    exportTarget.manageTargetTexture = YES;
    exportTarget.sharedTargetTexture = YES;
    exportTarget.name = @"Export";
    
    _sceneTarget = sceneTarget;
    
    // final pass to convert the result to RGBA
    NuoRenderPipelinePass* finalPass = [[NuoRenderPipelinePass alloc] initWithCommandQueue:commandBuffer.commandQueue
                                                                           withPixelFormat:exportTarget.targetPixelFormat
                                                                           withSampleCount:1 /* no MSAA for mere conversion */];
    NuoRenderPassTarget* displayTarget = [lastScenePass renderTarget];
    CGSize displaySize = [displayTarget drawableSize];
    
    CGFloat aspectRation = displaySize.width / displaySize.height;
    CGFloat drawEdge = _drawSize;
    if (displaySize.width < displaySize.height)
        drawEdge = drawEdge * aspectRation;
    CGSize drawSize = CGSizeMake(drawEdge, drawEdge / aspectRation);
    
    [lastScenePass setRenderTarget:sceneTarget];
    [_renderPipeline setDrawableSize:drawSize];
    
    if (![_renderPipeline renderWithCommandBuffer:commandBuffer inFlight:0])
        assert(false);
    
    [finalPass setSourceTexture:_sceneTarget.targetTexture];
    [finalPass setRenderTarget:exportTarget];
    [finalPass setDrawableSize:drawSize];
    [finalPass drawWithCommandBuffer:commandBuffer withInFlightIndex:0];
    
    id<MTLBlitCommandEncoder> encoder = [commandBuffer blitCommandEncoder];
    [encoder synchronizeResource:exportTarget.targetTexture];
    [encoder endEncoding];
    
    __block id<MTLTexture> result = exportTarget.targetTexture;
    
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer)
     {
         completionBlock(result);
     }];
    
    [commandBuffer commit];
    
    [lastScenePass setRenderTarget:displayTarget];
    [lastScenePass setDrawableSize:displaySize];
}


@end
