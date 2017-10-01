//
//  NuoAmbientOcclusionRenderer.m
//  ModelViewer
//
//  Created by Dong on 10/1/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoAmbientOcclusionRenderer.h"
#import "NuoScreenSpaceRenderer.h"



@implementation NuoAmbientOcclusionRenderer
{
    NuoScreenSpaceRenderer* _screenSpaceRenderer;
}


- (instancetype)initWithDevice:(id<MTLDevice>)device
            withSceneParameter:(id<NuoMeshSceneParametersProvider>)sceneParameter
{
    self = [super init];
    
    if (self)
    {
        self.device = device;
        _screenSpaceRenderer = [[NuoScreenSpaceRenderer alloc] initWithDevice:device withName:@"Screen"];
        _screenSpaceRenderer.paramsProvider = sceneParameter;
        
        self.renderTarget = [[NuoRenderPassTarget alloc] init];
        self.renderTarget.device = device;
        self.renderTarget.manageTargetTexture = YES;
        self.renderTarget.sharedTargetTexture = YES;
        self.renderTarget.sampleCount = 1;
    }
    
    return self;
}


- (void)setDrawableSize:(CGSize)drawableSize
{
    [super setDrawableSize:drawableSize];
    [_screenSpaceRenderer setDrawableSize:drawableSize];
}


- (void)setMeshes:(NSArray<NuoMesh*>*)meshes
{
    [_screenSpaceRenderer setMeshes:meshes];
}


- (void)predrawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    [_screenSpaceRenderer drawWithCommandBuffer:commandBuffer withInFlightIndex:inFlight];
}


- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    [self predrawWithCommandBuffer:commandBuffer withInFlightIndex:inFlight];
}



@end
