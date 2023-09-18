//
//  NuoTextureBase.h
//  ModelViewer
//
//  Created by middleware on 9/23/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Metal/Metal.h>




enum NuoTextureCubeFace
{
    kCubeFace_px,
    kCubeFace_nx,
    kCubeFace_py,
    kCubeFace_ny,
    kCubeFace_pz,
    kCubeFace_nz,
};




@interface NuoTexture : NSObject

@property (strong) id<MTLTexture> texture;
@property (assign) BOOL hasTransparency;

@end




@interface NuoTextureBase : NSObject

@property (nonatomic) BOOL useImageIO;

+ (NuoTextureBase*)getInstance:(id<MTLCommandQueue>)commandQueue;


- (NuoTexture*)texture2DWithImageNamed:(NSString *)imagePath
                             mipmapped:(BOOL)mipmapped
                     checkTransparency:(BOOL)checkTransparency;

- (id<MTLTexture>)textureCubeWithImageNamed:(NSString *)imagePath;

- (void)saveTexture:(id<MTLTexture>)texture toImage:(NSString*)path;

- (id<MTLSamplerState>)textureSamplerState:(BOOL)mipmap;

@end
