//
//  NuoScreenSpaceTarget.h
//  ModelViewer
//
//  Created by Dong on 9/28/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoRenderPassTarget.h"
#import <Metal/Metal.h>



@interface NuoScreenSpaceTarget : NuoRenderPassTarget


@property (nonatomic, readonly) id<MTLTexture> positionBuffer;
@property (nonatomic, readonly) id<MTLTexture> normalBuffer;
@property (nonatomic, readonly) id<MTLTexture> ambientBuffer;
@property (nonatomic, readonly) id<MTLTexture> shadowOverlayBuffer;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue withSampleCount:(uint)sampleCount;


@end
