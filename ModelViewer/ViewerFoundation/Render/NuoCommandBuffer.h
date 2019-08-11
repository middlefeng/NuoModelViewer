//
//  NuoCommandBuffer.h
//  ModelViewer
//
//  Created by Dong on 5/3/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#import "NuoRenderInFlight.h"



@class NuoComputeEncoder;
@class NuoRenderPassEncoder;


@interface NuoCommandBuffer : NSObject <NuoRenderInFlight>


@property (nonatomic, readonly) id<MTLCommandQueue> commandQueue;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                        withInFlight:(uint)inFlight;

- (void)synchronizeResource:(id<MTLResource>)resource;
- (void)copyFromTexture:(id<MTLTexture>)src toTexture:(id<MTLTexture>)dst;
- (void)copyFromBuffer:(id<MTLBuffer>)src toBuffer:(id<MTLBuffer>)dst;

- (void)addCompletedHandler:(MTLCommandBufferHandler)block;
- (void)commit;
- (void)presentDrawable:(id<MTLDrawable>)drawable;

- (NuoComputeEncoder*)computeEncoderWithName:(NSString*)name;
- (NuoRenderPassEncoder*)renderCommandEncoderWithDescriptor:(MTLRenderPassDescriptor*)descriptor;


@end


