
#import "ModelDissectRenderer.h"

#import "NuoMeshSceneRoot.h"
#import "NuoTypes.h"
#import "NuoTextureMesh.h"

#import "ModelViewerRenderer.h"

@interface ModelDissectRenderer ()

@end



@implementation ModelDissectRenderer
{
    NuoRenderPassTarget* _dissectRenderTarget;
    NuoTextureMesh* _textureMesh;
    NSUInteger _sampleCount;
}



- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    if (self = [super initWithCommandQueue:commandQueue])
    {
        _sampleCount = kSampleCount;
        [self makeResources];
    }

    return self;
}


- (void)makeResources
{

    _dissectRenderTarget = [[NuoRenderPassTarget alloc] initWithCommandQueue:self.commandQueue
                                                             withPixelFormat:MTLPixelFormatBGRA8Unorm
                                                             withSampleCount:kSampleCount];

    _dissectRenderTarget.name = @"Dissect";
    _dissectRenderTarget.clearColor = MTLClearColorMake(0.95, 0.95, 0.95, 1);
    _dissectRenderTarget.manageTargetTexture = YES;
    
    _textureMesh = [[NuoTextureMesh alloc] initWithCommandQueue:self.commandQueue];
}


- (void)setDrawableSize:(CGSize)drawableSize
{
    [super setDrawableSize:drawableSize];
    [_dissectRenderTarget setDrawableSize:drawableSize];
    
    [_textureMesh setAuxiliaryTexture:_dissectRenderTarget.targetTexture];
    [_textureMesh makePipelineAndSampler:MTLPixelFormatBGRA8Unorm withBlendMode:kBlend_None];
}


- (void)setSampleCount:(NSUInteger)sampleCount
{
    if (_sampleCount == sampleCount)
        return;
    
    // super method handles the default render target
    //
    [super setSampleCount:sampleCount];
    
    _sampleCount = sampleCount;
    [_dissectRenderTarget setSampleCount:_sampleCount];
    
    [_textureMesh setSampleCount:_sampleCount];
    [_textureMesh setAuxiliaryTexture:_dissectRenderTarget.targetTexture];
    [_textureMesh makePipelineAndSampler:MTLPixelFormatBGRA8Unorm withBlendMode:kBlend_None];
}



- (void)setSplitViewProportion:(float)splitViewProportion
{
    _textureMesh.auxiliaryProportion = splitViewProportion;
}


- (float)splitViewProportion
{
    return _textureMesh.auxiliaryProportion;
}



- (void)predrawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer
{
    // get the target render pass and draw the scene
    //
    NuoRenderPassEncoder* renderPass = [_dissectRenderTarget retainRenderPassEndcoder:commandBuffer];
    if (!renderPass)
        return;
    
    renderPass.label = @"Dissection Render Pass";
    
    [self setSceneBuffersTo:renderPass];
    [_dissectScene setCullEnabled:[self.paramsProvider cullEnabled]];
    [_dissectScene drawMesh:renderPass];
    
    [_dissectRenderTarget releaseRenderPassEndcoder];
}



- (void)drawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer
{
    [_textureMesh setModelTexture:self.sourceTexture];
    
    NuoRenderPassEncoder* renderPass = [self retainDefaultEncoder:commandBuffer];
    [_textureMesh drawMesh:renderPass];
    [self releaseDefaultEncoder];
}



@end
