//
//  NuoAlphaAddPass.h
//  ModelViewer
//
//  Created by Dong 9/24/23
//  Copyright © 2023 Dong Feng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NuoRenderPipelinePass.h"


/**
 *  a render pass that add the part of the source color which is truncated
 *  by Photoshop when Photoshop covert a pre-multiplied alpha image to
 *  straight alpha.
 */

@interface NuoAlphaOverflowPass : NuoRenderPipelinePass


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                     withSampleCount:(uint)sampleCount;

@end
