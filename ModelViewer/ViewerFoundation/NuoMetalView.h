#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <Quartz/Quartz.h>

@class NuoRenderPass;
@class NuoRenderPipeline;



@interface NuoMetalView : NSView

/**
 *  The passes of the view's rendering, responsible for maintain the model/scene state,
 *  and the rendering.
 */
@property (nonatomic, strong) NuoRenderPipeline* renderPipeline;

@property (nonatomic) NSInteger preferredFramesPerSecond;

@property (nonatomic) MTLPixelFormat colorPixelFormat;

@property (nonatomic) BOOL measureFrameRate;
@property (nonatomic, readonly) float frameRate;


- (instancetype)initWithFrame:(CGRect)frame device:(id<MTLDevice>)device;

- (void)commonInit;

- (void)viewResizing;

- (CAMetalLayer *)metalLayer;

- (id<MTLCommandQueue>)commandQueue;

- (void)setRenderPasses:(NSArray<NuoRenderPass*>*)renderPasses;

/**
 *  Notify the view to render the model/scene (i.e. in turn notifying the delegate)
 */
- (void)render;

@end

