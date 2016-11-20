//
//  NotationLight.h
//  ModelViewer
//
//  Created by middleware on 11/13/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <simd/simd.h>


@class NuoMeshBox;


@interface NotationLight : NSObject


@property (nonatomic, assign) float density;

@property (nonatomic, assign) float rotateX;
@property (nonatomic, assign) float rotateY;

@property (nonatomic, assign) matrix_float4x4 viewMatrix;
@property (nonatomic, assign) matrix_float4x4 projMatrix;

@property (nonatomic, assign) BOOL selected;


@property (nonatomic, readonly) NSInteger bufferIndex;


- (instancetype)initWithDevice:(id<MTLDevice>)device;

- (void)drawWithRenderPass:(id<MTLRenderCommandEncoder>)renderPass;
- (void)drawablePresented;


- (NuoMeshBox*)boundingBox;
- (CGPoint)headPointProjected;


@end
