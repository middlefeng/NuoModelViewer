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
#import "NuoAlphaAddPass.h"
#import "NuoCommandBuffer.h"



@interface NuoOffscreenView()


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
        _renderPipeline.renderPasses = _renderPasses;
        
        _clearColor = clearColor;
    }
    
    return self;
}


- (void)renderWithCommandQueue:(id<MTLCommandQueue>)commandQueue
               withPixelFormat:(MTLPixelFormat)pixelFormat
              forAlphaOverflow:(BOOL)alphaOverflow
                withCompletion:(void (^)(id<MTLTexture>))completionBlock;
{
    NuoCommandBuffer* commandBuffer = [[NuoCommandBuffer alloc] initWithCommandQueue:commandQueue
                                                                        withInFlight:0];
    
    NSUInteger lastRender = [_renderPasses count] - 1;
    NuoRenderPass* lastScenePass = _renderPasses[lastRender];
    NuoRenderPassTarget* lastTarget = lastScenePass.renderTarget;
    MTLPixelFormat scenePixelFormat = lastTarget.targetPixelFormat;
    uint sceneSampleCount = (uint)lastTarget.sampleCount;
    MTLClearColor mtlClearColor = lastTarget.clearColor;
    if (_clearColor)
        mtlClearColor = MTLClearColorMake(_clearColor.redComponent, _clearColor.greenComponent,
                                          _clearColor.blueComponent, _clearColor.alphaComponent);
    
    // privately managed by GPU only, same pixel format and sample-count as scene render
    //
    NuoRenderPassTarget* sceneTarget = [[NuoRenderPassTarget alloc] initWithCommandQueue:commandQueue
                                                                         withPixelFormat:scenePixelFormat
                                                                         withSampleCount:sceneSampleCount];
    sceneTarget.manageTargetTexture = YES;
    sceneTarget.sharedTargetTexture = NO;
    sceneTarget.clearColor = mtlClearColor;
    sceneTarget.name = @"Scene";
    
    // sharely managed by GPU and CPU, export to RGBA (since PNG need it)
    //
    NuoRenderPassTarget* exportTarget = [[NuoRenderPassTarget alloc] initWithCommandQueue:commandQueue
                                                                          withPixelFormat:pixelFormat
                                                                          withSampleCount:1];
    exportTarget.manageTargetTexture = YES;
    exportTarget.sharedTargetTexture = YES;
    sceneTarget.clearColor = mtlClearColor;
    exportTarget.name = @"Export";
    
    _sceneTarget = sceneTarget;
    
    // final pass: 1. convert the result to the desired bit depth
    //             2. generate overflow layer (add/linear-dodge)
    
    NuoRenderPipelinePass* finalPass = nil;
    if (alphaOverflow)
    {
        finalPass =  [[NuoAlphaOverflowPass alloc] initWithCommandQueue:commandQueue
                                                        withPixelFormat:exportTarget.targetPixelFormat
                                                        withSampleCount:1 /* no MSAA for mere conversion */];
    }
    else
    {
        finalPass = [[NuoRenderPipelinePass alloc] initWithCommandQueue:commandQueue
                                                        withPixelFormat:exportTarget.targetPixelFormat
                                                        withSampleCount:1 /* no MSAA for mere conversion */];
    }
    
    NuoRenderPassTarget* displayTarget = [lastScenePass renderTarget];
    CGSize displaySize = [displayTarget drawableSize];
    
    CGFloat aspectRation = displaySize.width / displaySize.height;
    CGFloat drawEdge = _drawSize;
    if (displaySize.width < displaySize.height)
        drawEdge = drawEdge * aspectRation;
    CGSize drawSize = CGSizeMake(drawEdge, drawEdge / aspectRation);
    
    [lastScenePass setRenderTarget:sceneTarget];
    [_renderPipeline setDrawableSize:drawSize];
    
    if (![_renderPipeline renderWithCommandBuffer:commandBuffer])
        assert(false);
    
    [finalPass setSourceTexture:_sceneTarget.targetTexture];
    [finalPass setRenderTarget:exportTarget];
    [finalPass setDrawableSize:drawSize];
    [finalPass drawWithCommandBuffer:commandBuffer];
    
    [commandBuffer synchronizeResource:exportTarget.targetTexture];
    
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
