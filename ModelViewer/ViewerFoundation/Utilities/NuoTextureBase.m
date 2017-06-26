//
//  NuoTextureBase.m
//  ModelViewer
//
//  Created by middleware on 9/23/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "NuoTextureBase.h"

#import <CoreImage/CoreImage.h>



static void NuoDataProviderReleaseDataCallback(void * info, const void *  data, size_t size)
{
    free(info);
}



@implementation NuoTexture

@end






@interface NuoTextureBase()



@property (strong) CIContext* CIContext;
@property (weak) id<MTLDevice> device;

@property (strong) NSMutableDictionary<NSString*, NuoTexture*>* texturePool;

@property (strong) id<MTLSamplerState> samplerStateMipMap;
@property (strong) id<MTLSamplerState> samplerStateNoMipMap;


@end



static NuoTextureBase* sInstance;




@implementation NuoTextureBase



+ (NuoTextureBase*)getInstance:(id<MTLDevice>)device
{
    if (!sInstance)
    {
        sInstance = [NuoTextureBase new];
        sInstance.device = device;
        sInstance.texturePool = [NSMutableDictionary new];
    }
    
    return sInstance;
}



- (NuoTexture*)texture2DWithImageNamed:(NSString *)imagePath
                             mipmapped:(BOOL)mipmapped
                     checkTransparency:(BOOL)checkTransparency
                          commandQueue:(id<MTLCommandQueue>)commandQueue
{
    NuoTexture* result = [_texturePool objectForKey:imagePath];
    if (result)
    {
        goto handleTransparency;
    }
    
    {
        CIImage *image = [[CIImage alloc] initWithContentsOfURL:[NSURL fileURLWithPath:imagePath]];
        
        if (image == nil)
        {
            return nil;
        }
        
        BOOL hasTransparency = NO;
        
        NSSize imageSize = image.extent.size;
        const NSUInteger bytesPerPixel = 4;
        const NSUInteger bytesPerRow = bytesPerPixel * imageSize.width;
        uint8_t *imageData = [self dataForImage:image hasTransparent:&hasTransparency];
        
        MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                                     width:imageSize.width
                                                                                                    height:imageSize.height
                                                                                                 mipmapped:mipmapped];
        id<MTLTexture> texture = [self.device newTextureWithDescriptor:textureDescriptor];
        
        MTLRegion region = MTLRegionMake2D(0, 0, imageSize.width, imageSize.height);
        [texture replaceRegion:region mipmapLevel:0 withBytes:imageData bytesPerRow:bytesPerRow];
        
        free(imageData);
        
        result = [NuoTexture new];
        result.texture = texture;
        result.hasTransparency = hasTransparency;
        
        if (mipmapped)
        {
            id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
            id<MTLBlitCommandEncoder> commandEncoder = [commandBuffer blitCommandEncoder];
            [commandEncoder generateMipmapsForTexture:texture];
            [commandEncoder endEncoding];
            [commandBuffer commit];
        }
        
        [_texturePool setObject:result forKey:imagePath];
    }
    
handleTransparency:
    if (!checkTransparency)
    {
        NuoTexture* opaque = [NuoTexture new];
        opaque.texture = result.texture;
        opaque.hasTransparency = NO;
        return opaque;
    }
    else
    {
        return result;
    }
}



- (id<MTLSamplerState>)textureSamplerState:(BOOL)mipmap
{
    if (mipmap)
    {
        if (_samplerStateMipMap)
            return _samplerStateMipMap;
        
        MTLSamplerDescriptor *samplerDesc = [MTLSamplerDescriptor new];
        samplerDesc.sAddressMode = MTLSamplerAddressModeRepeat;
        samplerDesc.tAddressMode = MTLSamplerAddressModeRepeat;
        samplerDesc.minFilter = MTLSamplerMinMagFilterNearest;
        samplerDesc.magFilter = MTLSamplerMinMagFilterNearest;
        samplerDesc.mipFilter = MTLSamplerMipFilterLinear;
        
        _samplerStateMipMap = [self.device newSamplerStateWithDescriptor:samplerDesc];
        return _samplerStateMipMap;
    }
    else
    {
        if (_samplerStateNoMipMap)
            return _samplerStateNoMipMap;
        
        MTLSamplerDescriptor *samplerDesc = [MTLSamplerDescriptor new];
        samplerDesc.sAddressMode = MTLSamplerAddressModeRepeat;
        samplerDesc.tAddressMode = MTLSamplerAddressModeRepeat;
        samplerDesc.minFilter = MTLSamplerMinMagFilterNearest;
        samplerDesc.magFilter = MTLSamplerMinMagFilterNearest;
        samplerDesc.mipFilter = MTLSamplerMipFilterNotMipmapped;
        
        _samplerStateNoMipMap = [self.device newSamplerStateWithDescriptor:samplerDesc];
        return _samplerStateNoMipMap;
    }
}



- (id<MTLTexture>)textureCubeWithImageNamed:(NSString *)imagePath
{
    if (!_CIContext)
        _CIContext = [CIContext contextWithOptions:nil];
    
    CIImage *image = [[CIImage alloc] initWithContentsOfURL:[NSURL fileURLWithPath:imagePath]];
    CGSize imageSize = image.extent.size;
    NSUInteger cubeSize = imageSize.width / 4.0;
    
    MTLTextureDescriptor *textureDescriptor =
            [MTLTextureDescriptor textureCubeDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                  size:cubeSize mipmapped:NO];
    
    id<MTLTexture> texture = [self.device newTextureWithDescriptor:textureDescriptor];
    MTLRegion region = MTLRegionMake2D(0, 0, cubeSize, cubeSize);
    for (uint index = 0; index < 6; ++index)
    {
        void* bytes = [self dataForImage:image forFace:index withCubeSize:cubeSize];
        
        const NSUInteger bytesPerRow = 4 * cubeSize;
        const NSUInteger bytesPerImage = bytesPerRow * cubeSize;
        
        [texture replaceRegion:region mipmapLevel:NO slice:index
                     withBytes:bytes bytesPerRow:bytesPerRow bytesPerImage:bytesPerImage];
        
        free(bytes);
    }
    
    return texture;
}



- (uint8_t *)dataForImage:(CIImage *)image hasTransparent:(BOOL*)hasTransparency
{
    if (!_CIContext)
        _CIContext = [CIContext contextWithOptions:nil];
    
    CGImageRef imageRef = [_CIContext createCGImage:image fromRect:image.extent];
    
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
    CGImageRelease(imageRef);
    
    if (hasTransparency)
        *hasTransparency = [self checkTransparency:rawData withWidth:width withHeight:height];
    
    return rawData;
}



- (uint8_t *)dataForImage:(CIImage *)image forFace:(enum NuoTextureCubeFace)face
             withCubeSize:(NSUInteger)cubeSize
{
    if (!_CIContext)
        _CIContext = [CIContext contextWithOptions:nil];
    
    CGImageRef imageRef = [_CIContext createCGImage:image fromRect:image.extent];
    
    // Create a suitable bitmap context for extracting the bits of the image
    const NSUInteger width = CGImageGetWidth(imageRef);
    const NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    const float faceWidth = width / 4.0;
    const float faceHeight = height / 3.0;
    uint8_t* rawData = (uint8_t *)calloc(cubeSize * cubeSize * 4, sizeof(uint8_t));
    
    const NSUInteger bytesPerPixel = 4;
    const NSUInteger bytesPerRow = bytesPerPixel * cubeSize;
    const NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, cubeSize, cubeSize,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGFloat offsetX = 0;
    CGFloat offsetY = 0;
    switch (face)
    {
        case kCubeFace_nx:
            offsetX = 0.0;
            offsetY = -faceHeight;
            break;
            
        case kCubeFace_ny:
            offsetX = -faceWidth;
            offsetY = 0.0;
            break;
            
        case kCubeFace_nz:
            offsetX = -faceWidth * 3.0;
            offsetY = -faceHeight;
            break;
            
        case kCubeFace_px:
            offsetX = -faceWidth * 2.0;
            offsetY = -faceHeight;
            break;
            
        case kCubeFace_py:
            offsetX = -faceWidth;
            offsetY = -faceHeight * 2.0;
            break;
            
        case kCubeFace_pz:
            offsetX = -faceWidth;
            offsetY = -faceHeight;
            break;
            
        default:
            break;
    }
    
    CGContextTranslateCTM(context, offsetX, offsetY);
    CGContextScaleCTM(context, cubeSize * 4.0 / width, cubeSize * 3.0 / height);
    CGRect sourceRect = CGRectMake(0, 0, width, height);
    CGContextDrawImage(context, sourceRect, imageRef);
    
    CGContextRelease(context);
    CGImageRelease(imageRef);
    
    return rawData;
}



- (void)saveTexture:(id<MTLTexture>)texture toImage:(NSString*)path
{
    size_t w = [texture width];
    size_t h = [texture height];
    size_t bytesPerRow = 4 * w;
    size_t sizeOfBuffer = bytesPerRow * h * 8;
    
    // support RGBA for now
    //
    assert([texture pixelFormat] == MTLPixelFormatRGBA8Unorm);
    
    void* buffer = malloc(sizeOfBuffer);
    assert(buffer);
    
    MTLRegion region = MTLRegionMake2D(0, 0, w, h);
    [texture getBytes:buffer bytesPerRow:bytesPerRow fromRegion:region mipmapLevel:0];
    
    [self saveBytes:buffer ofSize:CGSizeMake(w, h) toImage:path];
}



- (void)saveBytes:(void*)bytes ofSize:(CGSize)sizeOfBuffer toImage:(NSString*)path
{
    size_t w = sizeOfBuffer.width;
    size_t h = sizeOfBuffer.height;
    size_t bytesPerRow = 4 * w;
    size_t size = bytesPerRow * h * 8;
    
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(bytes, bytes, size,
                                                                  NuoDataProviderReleaseDataCallback);
    NSURL* url = [[NSURL alloc] initFileURLWithPath:path];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef image = CGImageCreate(w, h, 8, 8 * 4, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big,
                                     dataProvider, NULL, false, kCGRenderingIntentDefault);
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)url, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destination, image, NULL);
    CGImageDestinationFinalize(destination);
    
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(image);
    CFRelease(destination);
    
    CGDataProviderRelease(dataProvider);
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




@end
