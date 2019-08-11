//
//  NuoRayBuffer.h
//  ModelViewer
//
//  Created by middleware on 7/20/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>


extern const uint kRayBufferStride;

@class NuoCommandBuffer;


@interface NuoRayBuffer : NSObject



@property (nonatomic, assign) CGSize dimension;
@property (nonatomic, readonly) uint rayCount;

@property (nonatomic, readonly) id<MTLBuffer> buffer;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;

- (void)updateMask:(uint32_t)rayMaskSet withUniform:(id<MTLBuffer>)uniforms
                               withCommandBuffer:(NuoCommandBuffer*)commandBuffer;


@end


