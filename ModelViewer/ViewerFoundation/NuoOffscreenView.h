//
//  NuoOffscreenView.h
//  ModelViewer
//
//  Created by middleware on 2/20/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>



@class NuoRenderPass;



@interface NuoOffscreenView : NSObject


/**
 *  The passes of the view's rendering, which is likely to be shared with the on-screen
 *  pipeline
 */
@property (nonatomic, strong) NSArray<NuoRenderPass*>* renderPasses;


- (instancetype)initWithDevice:(id<MTLDevice>)device
                    withTarget:(NSUInteger)drawSize
                     withScene:(NSArray<NuoRenderPass*>*) renderPasses;

- (void)renderWithCommandQueue:(id<MTLCommandBuffer>)commandBuffer
                withCompletion:(void (^)(id<MTLTexture>))completionBlock;


@end
