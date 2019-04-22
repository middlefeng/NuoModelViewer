//
//  NuoRenderPipelinePass.h
//  ModelViewer
//
//  Created by middleware on 1/17/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NuoRenderPass.h"


/**
 *  a render pass takes the result from its immediate previous
 *  pass, draw it on the background, and leave its subclass draw method to
 *  add additional objects
 *
 *  also, it can take the source as an texture of a pixel format and draw it
 *  to the target of another format, in that way serving as pixel format convertor.
 *
 *  in the conversion-only case, or in a 2D only case, the sampleCount could be
 *  set to 1 to turning off the MSAA
 */

@interface NuoRenderPipelinePass : NuoRenderPass


/**
 *  data exchange with adjecent passes
 */
@property (nonatomic, weak) id<MTLTexture> sourceTexture;

@property (nonatomic, assign) BOOL showCheckerboard;


/**
 *  subclass need take care of the sourceTexture
 */
- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;


/**
 *  the sourceTexture is taken care of by default, according to the other parameters
 */
- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                     withSampleCount:(uint)sampleCount;

@end
