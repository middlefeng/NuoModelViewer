//
//  RayEmittor.h
//  ModelViewer
//
//  Created by middleware on 6/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>


@interface NuoRayEmittor : NSObject


@property (nonatomic, assign) CGFloat fieldOfView;
@property (nonatomic, weak) id<MTLTexture> destineTexture;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;

- (id<MTLBuffer>)rayBuffer:(id<MTLCommandBuffer>)commandBuffer
              withInFlight:(uint)inFlight;



@end

