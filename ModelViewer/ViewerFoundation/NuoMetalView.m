
#import "NuoMetalView.h"

#import "NuoTypes.h"
#import "NuoRenderPipeline.h"
#import "NuoRenderPipelinePass.h"
#import "NuoRenderPassTarget.h"

#import <sys/time.h>


#define MEASURE_PERFORMANCE 0


@interface NuoMetalView () < NuoRenderPipelineDelegate >

@property (nonatomic, readonly) CAMetalLayer *metalLayer;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (strong) dispatch_semaphore_t displaySemaphore;
@property (nonatomic, strong) id<CAMetalDrawable> currentDrawable;

/**
 *  current index in the tri-buffer flow
 */
@property (nonatomic, assign) unsigned int inFlightIndex;

#if MEASURE_PERFORMANCE
@property (nonatomic, assign) unsigned int inFlightNumber;
#endif

@end



@implementation NuoMetalView

- (CALayer*)makeBackingLayer
{
    return [CAMetalLayer new];
}

- (CAMetalLayer *)metalLayer
{
    CAMetalLayer* layer = (CAMetalLayer *)self.layer;
    return layer;
}

- (void)awakeFromNib
{
    [self setWantsLayer:YES];

    self.metalLayer.device = MTLCreateSystemDefaultDevice();
    
    [self commonInit];
    [self updateDrawableSize];
}

- (CGSize)drawableSize
{
    return [self metalLayer].drawableSize;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        _displaySemaphore = dispatch_semaphore_create(kInFlightBufferCount);
    }

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame device:(id<MTLDevice>)device
{
    if ((self = [super initWithFrame:frame]))
    {
        [self commonInit];
        self.metalLayer.device = device;
        _displaySemaphore = dispatch_semaphore_create(kInFlightBufferCount);
    }

    return self;
}

- (void)commonInit
{
    _preferredFramesPerSecond = 60;
    
    _commandQueue = [self.metalLayer.device newCommandQueue];
    
    [self setWantsLayer:YES];
    self.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
}


- (void)viewDidMoveToSuperview
{
    [self viewResizing];
}




- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
    [self viewResizing];
}



- (void)viewResizing
{
    [self updateDrawableSize];
}



- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self updateDrawableSize];
}



- (void)updateDrawableSize
{
    // During the first layout pass, we will not be in a view hierarchy, so we guess our scale
    CGFloat scale = [[NSScreen mainScreen] backingScaleFactor];
    CGSize drawableSize = self.bounds.size;
    
    // Since drawable size is in pixels, we need to multiply by the scale to move from points to pixels
    drawableSize.width *= scale;
    drawableSize.height *= scale;

    self.metalLayer.drawableSize = drawableSize;
    
    [self.renderPipeline setDrawableSize:drawableSize];
    [self render];
}

- (void)viewDidEndLiveResize
{
    [super viewDidEndLiveResize];
    [self updateDrawableSize];
}

- (void)setColorPixelFormat:(MTLPixelFormat)colorPixelFormat
{
    self.metalLayer.pixelFormat = colorPixelFormat;
}

- (MTLPixelFormat)colorPixelFormat
{
    return self.metalLayer.pixelFormat;
}


- (void)setRenderPasses:(NSArray<NuoRenderPass *> *)renderPasses
{
    _renderPipeline = [[NuoRenderPipeline alloc] init];
    _renderPipeline.renderPasses = renderPasses;
    _renderPipeline.renderPipelineDelegate = self;
}


- (id<MTLTexture>)nextFinalTexture
{
    _currentDrawable = [self.metalLayer nextDrawable];
    return [_currentDrawable texture];
}


- (void)render
{
    dispatch_semaphore_wait(_displaySemaphore, DISPATCH_TIME_FOREVER);
    
    _inFlightIndex = (_inFlightIndex + 1) % kInFlightBufferCount;
    
#if MEASURE_PERFORMANCE
    _inFlightNumber += 1;

    NSLog(@"In flight frame: %u.", _inFlightNumber);
    
    struct timeval begin, __block end, __block presented;
    gettimeofday(&begin, NULL);
#endif
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    __block dispatch_semaphore_t displaySem = self.displaySemaphore;
    
    if (![_renderPipeline renderWithCommandBuffer:commandBuffer inFlight:_inFlightIndex])
    {
        dispatch_semaphore_signal(displaySem);
#if MEASURE_PERFORMANCE
        _inFlightNumber -= 1;
        NSLog(@"In flight frame skipped: %u.", _inFlightNumber);
#endif
        return;
    };
    
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer)
     {
#if MEASURE_PERFORMANCE
         gettimeofday(&presented, NULL);
         
         float encodeVal = (end.tv_sec - begin.tv_sec) * 1e6 + (end.tv_usec - begin.tv_usec);
         float presentVal = (presented.tv_sec - begin.tv_sec) * 1e6 + (presented.tv_usec - begin.tv_usec);
         NSLog(@"Time spent: %f, %f.", encodeVal, presentVal);
         
         _inFlightNumber -= 1;
#endif
         
         dispatch_semaphore_signal(displaySem);
     }];
    
#if MEASURE_PERFORMANCE
    gettimeofday(&end, NULL);
#endif
    
    [commandBuffer presentDrawable:_currentDrawable];
    [commandBuffer commit];
}


@end
