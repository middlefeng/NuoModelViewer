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


@interface NuoRayBuffer : NSObject



@property (nonatomic, assign) CGSize dimension;
@property (nonatomic, readonly) uint rayCount;

@property (nonatomic, readonly) id<MTLBuffer> buffer;


- (instancetype)initWithDevice:(id<MTLDevice>)device;

- (void)updateMask:(uint32_t)rayMask withUniform:(id<MTLBuffer>)uniforms
                               withCommandBuffer:(id<MTLCommandBuffer>)commandBuffer;


@end


