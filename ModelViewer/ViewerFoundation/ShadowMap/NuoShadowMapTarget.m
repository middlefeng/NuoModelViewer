//
//  NuoShadowMapTarget.m
//  ModelViewer
//
//  Created by middleware on 1/16/17.
//  Updated by Dong on 5/21/23
//  Copyright © 2023 middleware. All rights reserved.
//

#import "NuoShadowMapTarget.h"



@interface NuoShadowMapTarget()

@property (nonatomic, strong) id<MTLTexture> depthSampleTexture;

@end




@implementation NuoShadowMapTarget



- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                     withSampleCount:(uint)sampleCount
{
    self = [super initWithCommandQueue:commandQueue
                       withPixelFormat:MTLPixelFormatR32Float
                       withSampleCount:sampleCount];
    if (self)
    {
        self.manageTargetTexture = YES;
        self.clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 1.0);
        self.storeDepth = NO;
    }
    
    return self;
}


- (void)setDrawableSize:(CGSize)drawableSize
{
    [super setDrawableSize:drawableSize];
}



- (void)clearAction:(NuoRenderPassEncoder*)encoder
{
}





@end
