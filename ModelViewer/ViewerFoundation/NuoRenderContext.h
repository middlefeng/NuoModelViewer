//
//  RenderContext.h
//  ModelViewer
//
//  Created by middleware on 5/14/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <simd/simd.h>


@protocol MTLRenderCommandEncoder;


@interface NuoRenderContext : NSObject

@property (weak, nonatomic) id<MTLRenderCommandEncoder> renderPass;
@property (assign) NSInteger bufferIndex;
@property (assign) matrix_float4x4 matrix;


- (instancetype)initWithRenderPass:(id<MTLRenderCommandEncoder>)renderPass;

@end
