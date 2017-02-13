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


@class LightSource;
@class NuoMeshBox;


@interface NotationLight : NSObject


@property (nonatomic, weak) LightSource* lightSourceDesc;

@property (nonatomic, assign) matrix_float4x4 viewMatrix;
@property (nonatomic, assign) matrix_float4x4 projMatrix;

@property (nonatomic, assign) BOOL selected;


- (instancetype)initWithDevice:(id<MTLDevice>)device isBold:(BOOL)bold;

- (void)drawWithRenderPass:(id<MTLRenderCommandEncoder>)renderPass
              withInFlight:(unsigned int)inFlight;


- (NuoMeshBox*)boundingBox;
- (CGPoint)headPointProjected;


@end
