//
//  NuoComputeEncoder.h
//  ModelViewer
//
//  Created by middleware on 7/8/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>


@interface NuoComputeEncoder : NSObject


@property (nonatomic, assign) CGSize dataSize;


- (instancetype)initWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                         withPipeline:(id<MTLComputePipelineState>)pipeline
                             withName:(NSString*)name;

- (void)setTexture:(id<MTLTexture>)texture atIndex:(uint)index;
- (void)setBuffer:(id<MTLBuffer>)buffer offset:(uint)offset atIndex:(uint)index;

- (void)dispatch;


@end

