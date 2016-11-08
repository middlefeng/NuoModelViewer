#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <Quartz/Quartz.h>

@protocol NuoMetalViewDelegate;
@class NuoRenderTarget;



@interface NuoMetalView : NSView

/**
 *  The delegate of this view, responsible for maintain the model/scene state,
 *  and the rendering
 */
@property (nonatomic, weak) id<NuoMetalViewDelegate> delegate;

@property (nonatomic) NSInteger preferredFramesPerSecond;

@property (nonatomic) MTLPixelFormat colorPixelFormat;

@property (nonatomic, readonly) id<CAMetalDrawable> currentDrawable;

@property (nonatomic, readonly) NuoRenderTarget* renderTarget;


- (void)commonInit;

- (void)viewResizing;


/**
 *  Notify the view to render the model/scene (i.e. in turn notifying the delegate)
 */
- (void)render;

@end



@protocol NuoMetalViewDelegate <NSObject>

- (void)drawInView:(NuoMetalView *)view;

@end
