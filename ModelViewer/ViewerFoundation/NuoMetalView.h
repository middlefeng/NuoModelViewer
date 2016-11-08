#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <Quartz/Quartz.h>

@protocol NuoMetalViewDelegate;
@class NuoRenderTarget;
@class NuoNotationRenderer;



@interface NuoMetalView : NSView

/**
 *  The delegate of this view, responsible for maintain the model/scene state,
 *  and the rendering
 */
@property (nonatomic, weak) id<NuoMetalViewDelegate> delegate;

/**
 *  The renderer for the overlay notations. Overlay notations are UI elements rendered
 *  as 3D objects, but not interfere with the original scene depth.
 */
@property (nonatomic, strong) NuoNotationRenderer* notationRenderer;



@property (nonatomic) NSInteger preferredFramesPerSecond;

@property (nonatomic) MTLPixelFormat colorPixelFormat;

@property (nonatomic, readonly) id<CAMetalDrawable> currentDrawable;

@property (nonatomic, readonly) NuoRenderTarget* modelRenderTarget;
@property (nonatomic, readonly) NuoRenderTarget* notationRenderTarget;

@property (strong) id<MTLTexture> debugTexture;


- (void)commonInit;

- (void)viewResizing;

- (CAMetalLayer *)metalLayer;


/**
 *  Notify the view to render the model/scene (i.e. in turn notifying the delegate)
 */
- (void)render;

@end



@protocol NuoMetalViewDelegate <NSObject>

- (void)drawToTarget:(NuoRenderTarget *)target withCommandBuffer:(id<MTLCommandBuffer>)commandBuffer;

@end
