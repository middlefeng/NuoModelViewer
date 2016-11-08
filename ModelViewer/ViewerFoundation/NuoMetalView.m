
#import "NuoMetalView.h"

#import "NuoTypes.h"
#import "NuoRenderTarget.h"


@interface NuoMetalView ()

@property (nonatomic, readonly) CAMetalLayer *metalLayer;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;

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
    _currentDrawable = [self.metalLayer nextDrawable];
    if (!_currentDrawable)
        return;

    [_notationRenderTarget setTargetTexture:[_currentDrawable texture]];
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    [self.delegate drawInView:self withCommandBuffer:commandBuffer];
    
    [commandBuffer presentDrawable:_currentDrawable];
    [commandBuffer commit];
}


@end
