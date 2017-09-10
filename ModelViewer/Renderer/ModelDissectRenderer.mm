
#import "ModelDissectRenderer.h"

#import "NuoMesh.h"
#import "NuoTypes.h"

#import "ModelViewerRenderer.h"

@interface ModelDissectRenderer ()

@end



@implementation ModelDissectRenderer
{
}



- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if ((self = [super initWithDevice:device withPixelFormat:MTLPixelFormatBGRA8Unorm
                      withSampleCount:kSampleCount]))
    {
        [self makeResources];
    }

    return self;
}


- (void)makeResources
{
}



- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
            withInFlightIndex:(unsigned int)inFlight
{
    /*[super drawWithCommandBuffer:commandBuffer withInFlightIndex:inFlight];
    
    id<MTLRenderCommandEncoder> renderPass = self.lastRenderPass;
    self.lastRenderPass = nil;
    
    [renderPass endEncoding];*/
    
    MTLRenderPassDescriptor *passDescriptor = [self.renderTarget currentRenderPassDescriptor];
    if (!passDescriptor)
        return;
    
    // get the target render pass and draw the scene
    //
    id<MTLRenderCommandEncoder> renderPass = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
    renderPass.label = @"Scene Render Pass";
    
    [_modelRenderer setSceneBuffersTo:renderPass withInFlightIndex:inFlight];
    
    for (NuoMesh* mesh in _dissectMeshes)
    {
        [mesh setCullEnabled:[_modelRenderer cullEnabled]];
        [mesh drawMesh:renderPass indexBuffer:inFlight];
    }
    
    [renderPass endEncoding];
}



@end
