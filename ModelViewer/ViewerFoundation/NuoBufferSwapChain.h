//
//  NuoBufferSwapChain.h
//  ModelViewer
//
//  Created by Dong on 5/4/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>


@class NuoRenderPassEncoder;



@interface NuoBufferSwapChain : NSObject


- (instancetype)initWithDevice:(id<MTLDevice>)device
                WithBufferSize:(size_t)size
                   withOptions:(MTLResourceOptions)options
                 withChainSize:(uint)chainSize;


- (void)updateBufferWithRenderPass:(NuoRenderPassEncoder*)renderpass;
- (id<MTLBuffer>)bufferForRenderPass:(NuoRenderPassEncoder*)renderpass;


@end


