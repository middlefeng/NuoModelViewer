//
//  NuoNotationRenderer.h
//  ModelViewer
//
//  Created by middleware on 11/6/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#import "NuoMetalView.h"
#import "NuoRenderPipelinePass.h"

/**
 *  an intermeidate render pass takes the result from its immediate previous
 *  pass, draw it on the background, and leave its subclass draw method to
 *  add additional objects
 *
 *  also, it can take the source as an texture of a pixel format and draw it
 *  to the target of another format, in that way serving as pixel format convertor
 */

@interface NuoIntermediateRenderPass : NuoRenderPipelinePass

- (instancetype)initWithDevice:(id<MTLDevice>)device
               withPixelFormat:(MTLPixelFormat)pixelFormat;

@end
