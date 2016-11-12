//
//  NuoRenderer.h
//  ModelViewer
//
//  Created by middleware on 11/8/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>


#import "NuoRenderPassTarget.h"



@interface NuoRenderPass : NSObject

@property (nonatomic, weak) id<MTLDevice> device;

/**
 *  current index in the tri-buffer flow
 */
@property (nonatomic, assign) NSInteger bufferIndex;

/**
 *  data exchange with adjecent passes
 */
@property (nonatomic, weak) id<MTLTexture> sourceTexture;
@property (nonatomic, strong) NuoRenderPassTarget* renderTarget;

@property (nonatomic, strong) id<MTLRenderCommandEncoder> lastRenderPass;


- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer;


@end
