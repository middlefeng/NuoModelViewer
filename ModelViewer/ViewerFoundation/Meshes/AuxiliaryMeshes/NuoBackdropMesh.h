//
//  NuoBackdropMesh.h
//  ModelViewer
//
//  Created by Dong on 10/21/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoMesh.h"



@interface NuoBackdropMesh : NuoMesh


@property (nonatomic, assign) CGPoint translation;
@property (nonatomic, assign) CGFloat scale;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue withBackdrop:(id<MTLTexture>)backdrop;

- (void)makePipelineAndSampler;
- (void)updateUniform:(id<NuoRenderInFlight>)inFlight withDrawableSize:(CGSize)drawableSize;


@end
