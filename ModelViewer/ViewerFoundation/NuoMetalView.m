
#import "NuoMetalView.h"

#import "NuoTypes.h"
#import "NuoRenderPipelinePass.h"
#import "NuoRenderPassTarget.h"


@interface NuoMetalView ()

@property (nonatomic, readonly) CAMetalLayer *metalLayer;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (strong) dispatch_semaphore_t displaySemaphore;

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
    
    for (size_t i = 0; i < [_renderPasses count]; ++i)
    {
        NuoRenderPass* render = _renderPasses[i];
        [render setDrawableSize:drawableSize];
    }
    
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


- (void)render
{
    dispatch_semaphore_wait(self.displaySemaphore, DISPATCH_TIME_FOREVER);
    
    _currentDrawable = [self.metalLayer nextDrawable];
    if (!_currentDrawable)
        return;
    
    for (size_t i = 0; i < [_renderPasses count]; ++i)
    {
        NuoRenderPass* renderStep = [_renderPasses objectAtIndex:i];
        if (!renderStep.isPipelinePass)
            continue;
        
        NuoRenderPipelinePass* render1 = (NuoRenderPipelinePass*)renderStep;
        NuoRenderPipelinePass* render2 = nil;
        
        if (i < [_renderPasses count] - 1)
            render2 = (NuoRenderPipelinePass*)[_renderPasses objectAtIndex:i + 1];
        
        if (render2)
        {
            NuoRenderPassTarget* interResult = render1.renderTarget;
            [render2 setSourceTexture:interResult.targetTexture];
        }
        else
        {
            NuoRenderPassTarget* finalResult = render1.renderTarget;
            [finalResult setTargetTexture:[_currentDrawable texture]];
        }
    }

    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    for (size_t i = 0; i < [_renderPasses count]; ++i)
    {
        NuoRenderPass* render = [_renderPasses objectAtIndex:i];
        [render drawWithCommandBuffer:commandBuffer];
    }
    
    __block dispatch_semaphore_t displaySem = self.displaySemaphore;
    
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer)
     {
         for (size_t i = 0; i < [_renderPasses count]; ++i)
         {
             [_renderPasses[i] drawablePresented];
         }
         
         dispatch_semaphore_signal(displaySem);
     }];
    
    [commandBuffer presentDrawable:_currentDrawable];
    [commandBuffer commit];
}


@end
