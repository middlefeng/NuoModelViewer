//
//  NuoRenderPipeline.h
//  ModelViewer
//
//  Created by middleware on 2/20/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>



@class NuoRenderPass;



/**
 *  use this delegate to defer the retrival of the final target texture.
 *  the retrival is time consuming in some case and should be deferred until
 *  the very last pass
 */
@protocol NuoRenderPipelineDelegate <NSObject>


- (id<MTLTexture>)nextFinalTexture;


@end



@interface NuoRenderPipeline : NSObject


/**
 *  The passes of the view's rendering, responsible for maintain the model/scene state,
 *  and the rendering.
 *
 *  Note that the pipeline does the sequential rendering for all the passes but does not
 *  own the passes (i.e. weak). The passes are constructed and owned by application
 */
@property (nonatomic, weak) NSArray<NuoRenderPass*>* renderPasses;

@property (nonatomic, weak) id<NuoRenderPipelineDelegate> renderPipelineDelegate;


- (BOOL)renderWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                       inFlight:(uint)inFlight;

- (void)setDrawableSize:(CGSize)size;


@end
