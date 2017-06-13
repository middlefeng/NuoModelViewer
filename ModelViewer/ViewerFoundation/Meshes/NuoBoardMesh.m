//
//  NuoBoardMesh.m
//  ModelViewer
//
//  Created by middleware on 6/6/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoBoardMesh.h"


@implementation NuoBoardMesh
{
    id<MTLSamplerState> _samplerState;
}


- (MTLRenderPipelineDescriptor*)makePipelineStateDescriptor
{
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    
    NSString* vertexFunc = _image ? @"vertex_project_board_image" : @"vertex_project_shadow";
    NSString* fragmnFunc = _image ? @"fragment_board_image" : @"fragment_light_shadow";
    
    MTLFunctionConstantValues* funcConstant = [MTLFunctionConstantValues new];
    [funcConstant setConstantValue:&_shadowOverlayOnly type:MTLDataTypeBool atIndex:3];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:vertexFunc];
    pipelineDescriptor.fragmentFunction = [library newFunctionWithName:fragmnFunc
                                                        constantValues:funcConstant error:nil];
    pipelineDescriptor.sampleCount = kSampleCount;
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
    MTLRenderPipelineColorAttachmentDescriptor* colorAttachment = pipelineDescriptor.colorAttachments[0];
    colorAttachment.blendingEnabled = YES;
    colorAttachment.rgbBlendOperation = MTLBlendOperationAdd;
    colorAttachment.alphaBlendOperation = MTLBlendOperationAdd;
    colorAttachment.sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    colorAttachment.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    colorAttachment.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    
    return pipelineDescriptor;
}

- (void)makePipelineShadowState
{
    [super makePipelineShadowState:@"vertex_shadow"];
}


- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    [renderPass setCullMode:MTLCullModeBack];
    
    if (_image)
    {
        [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
        [renderPass setRenderPipelineState:self.renderPipelineState];
        [renderPass setDepthStencilState:self.depthStencilState];
        
        [renderPass setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
        [renderPass setVertexBuffer:self.transformBuffers[index] offset:0 atIndex:3];
        [renderPass setFragmentTexture:_image atIndex:2];
        [renderPass setFragmentSamplerState:_samplerState atIndex:0];
        [renderPass drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                               indexCount:[self.indexBuffer length] / sizeof(uint32_t)
                                indexType:MTLIndexTypeUInt32
                              indexBuffer:self.indexBuffer
                        indexBufferOffset:0];
    }
    else
    {
        [super drawMesh:renderPass indexBuffer:index];
    }
}


- (void)setImage:(id<MTLTexture>)image
{
    _image = image;
    
    if (_image)
    {
        self.shadowPipelineState = nil;
        
        // create sampler state
        MTLSamplerDescriptor *samplerDesc = [MTLSamplerDescriptor new];
        samplerDesc.sAddressMode = MTLSamplerAddressModeRepeat;
        samplerDesc.tAddressMode = MTLSamplerAddressModeRepeat;
        samplerDesc.minFilter = MTLSamplerMinMagFilterLinear;
        samplerDesc.magFilter = MTLSamplerMinMagFilterLinear;
        samplerDesc.mipFilter = MTLSamplerMipFilterLinear;
        _samplerState = [self.device newSamplerStateWithDescriptor:samplerDesc];
    }
    else
    {
        [self makePipelineShadowState];
        _samplerState = nil;
    }
    
    [self makePipelineState:[self makePipelineStateDescriptor]];
}


@end
