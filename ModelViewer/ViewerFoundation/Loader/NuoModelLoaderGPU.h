//
//  NuoModelLoaderGPU.h
//  ModelViewer
//
//  Created by Dong on 1/21/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Metal/Metal.h>
#import "NuoTypes.h"

#include <memory>
#include "NuoModelLoader.h"


@class NuoMeshOption;
@class NuoMeshCompound;



@interface NuoModelLoaderGPU : NSObject


@property (nonatomic, assign) std::shared_ptr<NuoModelLoader> loader;



- (instancetype)initWithLoader:(std::shared_ptr<NuoModelLoader>)loader;

- (NuoMeshCompound*)createMeshsWithOptions:(NuoMeshOption*)loadOption
                                withDevice:(id<MTLDevice>)device
                          withCommandQueue:(id<MTLCommandQueue>)commandQueue
                              withProgress:(NuoProgressFunction)progress;


@end
