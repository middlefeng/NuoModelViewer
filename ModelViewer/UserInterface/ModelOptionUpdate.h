//
//  ModelOptionUpdate.h
//  ModelViewer
//
//  Created by middleware on 1/5/2017.
//  Copyright © 2017 middleware. All rights reserved.
//


@class NuoMesh;
@class NuoMeshOption;
@class LightOperationPanel;



enum UpdateOptions
{
    kUpdateOption_DecreaseQuality = 1,
    kUpdateOption_RebuildPipeline = 2,
};



@protocol ModelOptionUpdate

- (void)modelUpdate:(NuoMeshOption*)meshOptions;
- (void)modelOptionUpdate:(uint32_t)options;
- (void)lightOptionUpdate:(LightOperationPanel*)panel;
- (void)animationLoad;

- (void)modelPartsSelectionChanged:(NSArray<NuoMesh*>*)selected;

@end

