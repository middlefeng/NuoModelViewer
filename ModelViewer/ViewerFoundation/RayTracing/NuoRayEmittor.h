//
//  RayEmittor.h
//  ModelViewer
//
//  Created by middleware on 6/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#import "NuoRenderPassTarget.h"


extern const uint kRayBufferStrid;


@interface NuoRayEmittor : NSObject


@property (nonatomic, assign) CGFloat fieldOfView;
@property (nonatomic, assign) CGSize drawableSize;
@property (nonatomic, readonly) uint rayCount;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;

- (id<MTLBuffer>)rayBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlight:(uint)inFlight
                  toTarget:(NuoRenderPassTarget*)renderTarget;

- (id<MTLBuffer>)uniformBuffer:(uint32_t)inFlight;



@end

