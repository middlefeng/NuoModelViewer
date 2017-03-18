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


+ (NuoTextureBase*)getInstance:(id<MTLDevice>)device;


- (NuoTexture*)texture2DWithImageNamed:(NSString *)imagePath
                             mipmapped:(BOOL)mipmapped
                     checkTransparency:(BOOL)checkTransparency
                          commandQueue:(id<MTLCommandQueue>)commandQueue;

- (id<MTLTexture>)textureCubeWithImageNamed:(NSString *)imagePath;

- (void)saveTexture:(id<MTLTexture>)texture toImage:(NSString*)path;

@end
