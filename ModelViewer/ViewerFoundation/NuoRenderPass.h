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
@property (nonatomic, readonly) NSInteger bufferIndex;

@property (nonatomic, strong) NuoRenderPassTarget* renderTarget;


- (void)setDrawableSize:(CGSize)drawableSize;


- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer;
- (void)drawablePresented;

- (BOOL)isPipelinePass;


@end
