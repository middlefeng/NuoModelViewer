
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



- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    if (self = [super initWithCommandQueue:commandQueue])
    {
        [self makeResources];
    }

    return self;
}


- (void)makeResources
{
    _dissectRenderTarget = [[NuoRenderPassTarget alloc] initWithCommandQueue:self.commandQueue
                                                             withSampleCount:kSampleCount];
    _dissectRenderTarget.clearColor = MTLClearColorMake(0.95, 0.95, 0.95, 1);
    _dissectRenderTarget.manageTargetTexture = YES;
    _dissectRenderTarget.name = @"Dissect";
    
    _textureMesh = [[NuoTextureMesh alloc] initWithCommandQueue:self.commandQueue];
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
    // get the target render pass and draw the scene
    //
    id<MTLRenderCommandEncoder> renderPass = [_dissectRenderTarget retainRenderPassEndcoder:commandBuffer];
    if (!renderPass)
        return;
    
    renderPass.label = @"Dissection Render Pass";
    
    [self setSceneBuffersTo:renderPass withInFlightIndex:inFlight];
    
    for (NuoMesh* mesh in _dissectMeshes)
    {
        [mesh setCullEnabled:[self.paramsProvider cullEnabled]];
        [mesh drawMesh:renderPass indexBuffer:inFlight];
    }
    
    [_dissectRenderTarget releaseRenderPassEndcoder];
}



- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
            withInFlightIndex:(unsigned int)inFlight
{
    [_textureMesh setModelTexture:self.sourceTexture];
    
    id<MTLRenderCommandEncoder> renderPass = [self retainDefaultEncoder:commandBuffer];
    [_textureMesh drawMesh:renderPass indexBuffer:inFlight];
    [self releaseDefaultEncoder];
}



@end
