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


- (instancetype)initWithDevice:(id<MTLDevice>)device withBackdrop:(id<MTLTexture>)backdrop;

- (void)makePipelineAndSampler;
- (void)updateUniform:(NSInteger)bufferIndex withDrawableSize:(CGSize)drawableSize;


@end
