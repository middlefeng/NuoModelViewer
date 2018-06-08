//
//  NuoModelLoaderGPU.m
//  ModelViewer
//
//  Created by Dong on 1/21/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoModelLoaderGPU.h"

#import "NuoMeshOptions.h"
#import "NuoMeshCompound.h"
#import "NuoMeshBounds.h"




@implementation NuoModelLoaderGPU



- (instancetype)initWithLoader:(std::shared_ptr<NuoModelLoader>)loader
{
    self = [super init];
    if (self)
        _loader = loader;
    
    return self;
}



- (NuoMeshCompound*)createMeshsWithOptions:(NuoMeshOption*)loadOption
                          withCommandQueue:(id<MTLCommandQueue>)commandQueue
                              withProgress:(NuoProgressFunction)progress
{
    const float loadingPortionModelBuffer = loadOption.textured ? 0.70 : 0.85;
    const float loadingPortionModelGPU = (1 - loadingPortionModelBuffer);
    
    NuoModelOption options;
    options._textured = loadOption.textured;
    options._textureEmbedMaterialTransparency = loadOption.textureEmbeddingMaterialTransparency;
    options._texturedBump = loadOption.texturedBump;
    options._basicMaterialized = loadOption.basicMaterialized;
    options._physicallyReflection = loadOption.physicallyReflection;
    
    auto progressFunc = [loadingPortionModelBuffer, progress](float progressValue)
    {
        progress(loadingPortionModelBuffer * progressValue);
    };
    
    std::vector<PNuoModelBase> models = _loader->CreateMeshWithOptions(options, loadOption.combineShapes,
                                                                       progressFunc);
    
    NSMutableArray<NuoMesh*>* result = [[NSMutableArray<NuoMesh*> alloc] init];
    
    size_t index = 0;
    for (auto& model : models)
    {
        NuoMesh* mesh = CreateMesh(options, commandQueue, model);
        
        NuoMeshBounds bounds;
        bounds.boundingBox = model->GetBoundingBox();
        
        [mesh setBoundsLocal:bounds];
        [result addObject:mesh];
        
        if (progress)
            progress(++index / (float)models.size() * loadingPortionModelGPU + loadingPortionModelBuffer);
    }
    
    NuoMeshCompound* resultObj = [NuoMeshCompound new];
    [resultObj setMeshes:result];
    
    return resultObj;
}


@end
