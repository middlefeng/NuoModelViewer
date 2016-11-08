
#import "NuoMetalView.h"

#import "NuoTypes.h"
#import "NuoRenderTarget.h"
#import "NuoNotationRenderer.h"


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
        _displaySemaphore = dispatch_semaphore_create(InFlightBufferCount);
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
    
    _modelRenderTarget = [NuoRenderTarget new];
    _modelRenderTarget.device = self.metalLayer.device;
    _modelRenderTarget.sampleCount = sSampleCount;
    _modelRenderTarget.clearColor = MTLClearColorMake(0.95, 0.95, 0.95, 1);
    
    _notationRenderTarget = [NuoRenderTarget new];
    _notationRenderTarget.device = self.metalLayer.device;
    _notationRenderTarget.sampleCount = 1;
    _notationRenderTarget.clearColor = MTLClearColorMake(0.95, 0.95, 0.95, 1);
    
    _notationRenderer = [[NuoNotationRenderer alloc] initWithDevice:self.metalLayer.device];
    
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
    
    [_modelRenderTarget setDrawableSize:drawableSize];
    [_modelRenderTarget makeTextures];
    
    if ([_modelRenderTarget.targetTexture width] != drawableSize.width ||
        [_modelRenderTarget.targetTexture height] != drawableSize.height)
    {
        MTLTextureDescriptor *sampleDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                              width:drawableSize.width
                                                                                             height:drawableSize.height
                                                                                          mipmapped:NO];
        sampleDesc.sampleCount = 1;
        sampleDesc.textureType = MTLTextureType2D;
        sampleDesc.resourceOptions = MTLResourceStorageModePrivate;
        sampleDesc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
        
        _modelRenderTarget.targetTexture = [self.metalLayer.device newTextureWithDescriptor:sampleDesc];
    }
    
    [_notationRenderTarget setDrawableSize:drawableSize];
    [_notationRenderTarget makeTextures];
    
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

    [_notationRenderer setSourceTexture:_modelRenderTarget.targetTexture];
    [_notationRenderTarget setTargetTexture:[_currentDrawable texture]];
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    [self.delegate drawToTarget:_modelRenderTarget withCommandBuffer:commandBuffer];
    [self.notationRenderer drawToTarget:_notationRenderTarget withCommandBuffer:commandBuffer];
    
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer) {
        [_currentDrawable present];
        dispatch_semaphore_signal(self.displaySemaphore);
    }];
    
    [commandBuffer commit];
}


@end
