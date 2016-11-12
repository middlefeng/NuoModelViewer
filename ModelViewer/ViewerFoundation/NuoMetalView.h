#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <Quartz/Quartz.h>

@class NuoRenderPassTarget;
@class NuoRenderPass;



@interface NuoMetalView : NSView

/**
 *  The passes of the view's rendering, responsible for maintain the model/scene state,
 *  and the rendering.
 */
@property (nonatomic, weak) NSArray<NuoRenderPass*>* renderPasses;

@property (nonatomic) NSInteger preferredFramesPerSecond;

@property (nonatomic) MTLPixelFormat colorPixelFormat;

@property (nonatomic, readonly) id<CAMetalDrawable> currentDrawable;



- (void)commonInit;

- (void)viewResizing;

- (CAMetalLayer *)metalLayer;


/**
 *  Notify the view to render the model/scene (i.e. in turn notifying the delegate)
 */
- (void)render;

@end

