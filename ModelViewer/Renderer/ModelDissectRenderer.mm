
#import "ModelDissectRenderer.h"

#import "NuoMesh.h"
#import "NuoTypes.h"
#import "NuoTextureMesh.h"

#import "ModelViewerRenderer.h"

@interface ModelDissectRenderer ()

@end



@implementation ModelDissectRenderer
{
    NuoRenderPassTarget* _dissectRenderTarget;
    NuoTextureMesh* _textureMesh;
}



- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if (self = [super init])
    {
        self.device = device;
        [self makeResources];
    }

    return self;
}


- (void)makeResources
{
    _dissectRenderTarget = [NuoRenderPassTarget new];
    _dissectRenderTarget.device = self.device;
    _dissectRenderTarget.sampleCount = kSampleCount;
    _dissectRenderTarget.clearColor = MTLClearColorMake(0.95, 0.95, 0.95, 1);
    _dissectRenderTarget.manageTargetTexture = YES;
    _dissectRenderTarget.name = @"Dissect";
    
    _textureMesh = [[NuoTextureMesh alloc] initWithDevice:self.device];
}


- (void)setDrawableSize:(CGSize)drawableSize
{
    [super setDrawableSize:drawableSize];
    [_dissectRenderTarget setDrawableSize:drawableSize];
    
    [_textureMesh setAuxiliaryTexture:_dissectRenderTarget.targetTexture];
    [_textureMesh makePipelineAndSampler:MTLPixelFormatBGRA8Unorm withSampleCount:kSampleCount];
}



- (void)setSplitViewProportion:(float)splitViewProportion
{
    _textureMesh.auxiliaryProportion = splitViewProportion;
}


- (float)splitViewProportion
{
    return _textureMesh.auxiliaryProportion;
}



- (void)predrawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
               withInFlightIndex:(unsigned int)inFlight
{
    MTLRenderPassDescriptor *passDescriptor = [_dissectRenderTarget currentRenderPassDescriptor];
    if (!passDescriptor)
        return;
    
    // get the target render pass and draw the scene
    //
    id<MTLRenderCommandEncoder> renderPass = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
    renderPass.label = @"Dissection Render Pass";
    
    [_modelRenderer setSceneBuffersTo:renderPass withInFlightIndex:inFlight];
    
    for (NuoMesh* mesh in _dissectMeshes)
    {
        [mesh setCullEnabled:[_modelRenderer cullEnabled]];
        [mesh drawMesh:renderPass indexBuffer:inFlight];
    }
    
    [renderPass endEncoding];
}



- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
            withInFlightIndex:(unsigned int)inFlight
{
    [_textureMesh setModelTexture:self.sourceTexture];
    
    MTLRenderPassDescriptor *renderPassDesc = [self.renderTarget currentRenderPassDescriptor];
    id<MTLRenderCommandEncoder> renderPass = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
    [_textureMesh drawMesh:renderPass indexBuffer:inFlight];
    
    [renderPass endEncoding];
}



@end
