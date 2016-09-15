//
//  NuoModelLoader.h
//  ModelViewer
//
//  Created by middleware on 8/26/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NuoTypes.h"


@class NuoMesh;


@interface NuoModelLoadOption : NSObject

@property (nonatomic, assign) BOOL textured;
@property (nonatomic, assign) NuoModelTextureAlphaType textureType;

@property (nonatomic, assign) BOOL basicMaterialized;

@end


@interface NuoModelLoader : NSObject

- (void)loadModel:(NSString*)path;
- (NSArray<NuoMesh*>*)createMeshsWithOptions:(NuoModelLoadOption*)loadOption
                                  withDevice:(id<MTLDevice>)device;


@end
