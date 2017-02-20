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
#import "NuoIntermediateRenderPass.h"



@interface NuoOffscreenView()


@property (nonatomic, weak) id<MTLDevice> device;

@property (nonatomic, strong) NuoRenderPassTarget* sceneTarget;
@property (nonatomic, strong) NuoRenderPassTarget* exportTarget;

@property (nonatomic, assign) NSUInteger drawSize;

@end




@implementation NuoOffscreenView


- (instancetype)initWithDevice:(id<MTLDevice>)device
                    withTarget:(NSUInteger)drawSize
                     withScene:(NSArray<NuoRenderPass*>*) renderPasses
{
    self = [super init];
    
    if (self)
    {
        _drawSize = drawSize;
        _device = device;
        _renderPasses = renderPasses;
        
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



- (void)renderWithCommandQueue:(id<MTLCommandBuffer>)commandBuffer
                withCompletion:(void (^)(id<MTLTexture>))completionBlock;
{
    NuoIntermediateRenderPass* finalPass = [[NuoIntermediateRenderPass alloc] initWithDevice:_device
                                                                             withPixelFormat:_exportTarget.targetPixelFormat];
    NSUInteger lastRender = [_renderPasses count] - 1;
    NuoRenderPass* lastScenePass = _renderPasses[lastRender];
    NuoRenderPassTarget* displayTarget = [lastScenePass renderTarget];
    CGSize displaySize = [displayTarget drawableSize];
    
    CGFloat aspectRation = displaySize.width / displaySize.height;
    [lastScenePass setRenderTarget:_sceneTarget];
    [lastScenePass setDrawableSize:CGSizeMake(_drawSize, _drawSize / aspectRation)];
    
    [lastScenePass setRenderTarget:_sceneTarget];
    [lastScenePass predrawWithCommandBuffer:commandBuffer withInFlightIndex:0];
    [lastScenePass drawWithCommandBuffer:commandBuffer withInFlightIndex:0];
    
    [finalPass setSourceTexture:_sceneTarget.targetTexture];
    [finalPass setRenderTarget:_exportTarget];
    [finalPass setDrawableSize:CGSizeMake(_drawSize, _drawSize / aspectRation)];
    [finalPass drawWithCommandBuffer:commandBuffer withInFlightIndex:0];
    [finalPass.lastRenderPass endEncoding];
    
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
