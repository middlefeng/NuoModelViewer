//
//  MotionBlurRenderer.h
//  ModelViewer
//
//  Created by Dong on 11/11/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoRenderPipelinePass.h"



@interface MotionBlurRenderer : NuoRenderPipelinePass

- (instancetype)initWithDevice:(id<MTLDevice>)device;

- (void)setSourceTexture:(id<MTLTexture>)sourceTexture;
- (id<MTLTexture>)sourceTexture;

@end
