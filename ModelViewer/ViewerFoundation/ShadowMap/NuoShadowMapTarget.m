//
//  NuoShadowMapTarget.m
//  ModelViewer
//
//  Created by middleware on 1/16/17.
//  Copyright © 2017 middleware. All rights reserved.
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
    self = [super initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                       withPixelFormat:(MTLPixelFormat)pixelFormat
                       withSampleCount:(uint)sampleCount];
    if (self)
    {
        self.colorAttachments = nil;
        self.resolveDepth = YES;
    }
    
    return self;
}



- (void)clearAction:(id<MTLRenderCommandEncoder>)encoder
{
}





@end
