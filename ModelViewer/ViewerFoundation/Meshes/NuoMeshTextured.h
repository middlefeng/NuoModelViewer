//
//  NuoMeshTextured.h
//  ModelViewer
//
//  Created by middleware on 9/7/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "NuoMesh.h"


@interface NuoMeshTextured : NuoMesh


@property (nonatomic, readonly) id<MTLTexture> diffuseTex;
@property (nonatomic, readonly) id<MTLSamplerState> samplerState;


- (instancetype)initWithDevice:(id<MTLDevice>)device
               withTexutrePath:(NSString*)texPath
            withVerticesBuffer:(void*)buffer withLength:(size_t)length
                   withIndices:(void*)indices withLength:(size_t)indicesLength;


@end