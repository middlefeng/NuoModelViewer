//
//  NuoRenderer.m
//  ModelViewer
//
//  Created by middleware on 11/8/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "NuoRenderPass.h"


static const unsigned int kInFlightBufferCount = 3;


@interface NuoRenderPass()

@end


@implementation NuoRenderPass


- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
}


- (void)drawablePresented
{
    _bufferIndex = (_bufferIndex + 1) % kInFlightBufferCount;
}


@end
