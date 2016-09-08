//
//  NuoMeshTextured.m
//  ModelViewer
//
//  Created by middleware on 9/7/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "NuoMeshTextured.h"
#import <CoreImage/CoreImage.h>



@implementation NuoMeshTextured



- (instancetype)initWithDevice:(id<MTLDevice>)device
            withVerticesBuffer:(void*)buffer withLength:(size_t)length
                   withIndices:(void*)indices withLength:(size_t)indicesLength
{
    if ((self = [super initWithDevice:device withVerticesBuffer:buffer withLength:length
                          withIndices:indices withLength:indicesLength]))
    {
        _hasTransparency = NO;
    }
    
    return self;
}



- (void)drawMesh:(id<MTLRenderCommandEncoder>) renderPass
{
    [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderPass setCullMode:MTLCullModeBack];
    
    [renderPass setRenderPipelineState:self.renderPipelineState];
    [renderPass setDepthStencilState:self.depthStencilState];
    
    [renderPass setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [renderPass setFragmentTexture:self.diffuseTex atIndex:0];
    [renderPass setFragmentSamplerState:self.samplerState atIndex:0];
    
    [renderPass drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                           indexCount:[self.indexBuffer length] / sizeof(uint32_t)
                            indexType:MTLIndexTypeUInt32
                          indexBuffer:self.indexBuffer
                    indexBufferOffset:0];
}




- (void)makeTexture:(NSString*)texPath checkTransparency:(BOOL)check
{
    _diffuseTex = [self texture2DWithImageNamed:texPath mipmapped:NO checkTransparency:check];
    
    // create sampler state
    MTLSamplerDescriptor *samplerDesc = [MTLSamplerDescriptor new];
    samplerDesc.sAddressMode = MTLSamplerAddressModeRepeat;
    samplerDesc.tAddressMode = MTLSamplerAddressModeRepeat;
    samplerDesc.minFilter = MTLSamplerMinMagFilterNearest;
    samplerDesc.magFilter = MTLSamplerMinMagFilterLinear;
    samplerDesc.mipFilter = MTLSamplerMipFilterLinear;
    _samplerState = [self.device newSamplerStateWithDescriptor:samplerDesc];
}


- (MTLRenderPipelineDescriptor*)makePipelineStateDescriptor
{
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"vertex_project_textured"];
    pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_light_textured"];
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    MTLRenderPipelineColorAttachmentDescriptor* colorAttachment = pipelineDescriptor.colorAttachments[0];
    if (_hasTransparency)
    {
        colorAttachment.blendingEnabled = YES;
        colorAttachment.rgbBlendOperation = MTLBlendOperationAdd;
        colorAttachment.alphaBlendOperation = MTLBlendOperationAdd;
        colorAttachment.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        colorAttachment.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    }
    
    MTLVertexDescriptor* vertexDescriptor = [MTLVertexDescriptor new];
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[0].offset = 0;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[0].offset = 16;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[0].offset = 32;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.layouts[0].stride = 48;
    vertexDescriptor.layouts[0].stepRate = 1;
    vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    
    pipelineDescriptor.vertexDescriptor = vertexDescriptor;
    
    return pipelineDescriptor;
}



- (uint8_t *)dataForImage:(CIImage *)image checkTransparency:(BOOL)checkTransparency
{
    CIContext* ciContext = [CIContext contextWithOptions:nil];
    CGImageRef imageRef = [ciContext createCGImage:image fromRect:image.extent];
    
    // Create a suitable bitmap context for extracting the bits of the image
    const NSUInteger width = CGImageGetWidth(imageRef);
    const NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    uint8_t *rawData = (uint8_t *)calloc(height * width * 4, sizeof(uint8_t));
    const NSUInteger bytesPerPixel = 4;
    const NSUInteger bytesPerRow = bytesPerPixel * width;
    const NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1, -1);
    
    CGRect imageRect = CGRectMake(0, 0, width, height);
    CGContextDrawImage(context, imageRect, imageRef);
    
    CGContextRelease(context);
    
    if (checkTransparency)
        _hasTransparency = [self checkTransparency:rawData withWidth:width withHeight:height];
    
    return rawData;
}



- (void)setTransparency:(BOOL)transparent
{
    _hasTransparency = transparent;
}



- (BOOL)checkTransparency:(uint8_t *)dataForImage withWidth:(size_t)width withHeight:(size_t)height
{
    const NSUInteger bytesPerPixel = 4;
    const NSUInteger bytesPerRow = bytesPerPixel * width;
    
    for (size_t row = 0; row < height; ++row)
    {
        uint8_t* rowPtr = dataForImage + row * bytesPerRow;
        
        for (size_t col = 0; col < width; ++col)
        {
            uint8_t* pixel = rowPtr + col * bytesPerPixel;
            if (pixel[3] < 250)
                return YES;
        }
    }
    
    return NO;
}



- (id<MTLTexture>)texture2DWithImageNamed:(NSString *)imagePath
                                mipmapped:(BOOL)mipmapped
                        checkTransparency:(BOOL)checkTransparency
{
    CIImage *image = [[CIImage alloc] initWithContentsOfURL:[NSURL fileURLWithPath:imagePath]];
    
    if (image == nil)
    {
        return nil;
    }
    
    NSSize imageSize = image.extent.size;
    const NSUInteger bytesPerPixel = 4;
    const NSUInteger bytesPerRow = bytesPerPixel * imageSize.width;
    uint8_t *imageData = [self dataForImage:image checkTransparency:checkTransparency];
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                                 width:imageSize.width
                                                                                                height:imageSize.height
                                                                                             mipmapped:mipmapped];
    id<MTLTexture> texture = [self.device newTextureWithDescriptor:textureDescriptor];
    
    MTLRegion region = MTLRegionMake2D(0, 0, imageSize.width, imageSize.height);
    [texture replaceRegion:region mipmapLevel:0 withBytes:imageData bytesPerRow:bytesPerRow];
    
    free(imageData);
    
    return texture;
}



@end
