//
//  NuoOffscreenView.h
//  ModelViewer
//
//  Created by middleware on 2/20/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <Metal/Metal.h>



@class NuoRenderPass;
@class NuoRenderPipeline;
@class NuoCommandBuffer;



@interface NuoOffscreenView : NSObject


@property (nonatomic, strong) NuoRenderPipeline* renderPipeline;


- (instancetype)initWithDevice:(id<MTLDevice>)device
                    withTarget:(NSUInteger)drawSize
                withClearColor:(NSColor*)clearColor
                     withScene:(NSArray<NuoRenderPass*>*) renderPasses;

- (void)renderWithCommandQueue:(NuoCommandBuffer*)commandBuffer
                withCompletion:(void (^)(id<MTLTexture>))completionBlock;

@end
