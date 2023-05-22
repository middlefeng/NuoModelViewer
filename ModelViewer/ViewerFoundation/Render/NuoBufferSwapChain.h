//
//  NuoBufferSwapChain.h
//  ModelViewer
//
//  Created by Dong on 5/4/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>


@protocol NuoRenderInFlight;


/**
 *  a reader to a parameter buffer should work with NuoBufferInFlight protocol
 *  rather than NuoBufferSwapChain. the latter is used by the writters that update
 *  a scene's parameters
 */

@interface NuoBufferInFlight : NSObject


- (id<MTLBuffer>)bufferForInFlight:(id<NuoRenderInFlight>)renderpass;


@end



/**
 *  tri-buffer encapsulation
 */

@interface NuoBufferSwapChain : NuoBufferInFlight


- (instancetype)initWithDevice:(id<MTLDevice>)device
                WithBufferSize:(size_t)size
                   withOptions:(MTLResourceOptions)options
                 withChainSize:(uint)chainSize;


- (void)updateBufferWithInFlight:(id<NuoRenderInFlight>)inFlight
                     withContent:(void*)content;


@end


