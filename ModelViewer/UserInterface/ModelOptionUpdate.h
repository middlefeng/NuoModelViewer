//
//  ModelOptionUpdate.h
//  ModelViewer
//
//  Created by middleware on 1/5/2017.
//  Copyright © 2017 middleware. All rights reserved.
//


@class NuoMesh;
@class LightOperationPanel;



enum UpdateOptions
{
    kUpdateOption_None            = 0,
    kUpdateOption_DecreaseQuality = 1,
    kUpdateOption_RebuildPipeline = 2,
};



@protocol ModelOptionUpdate

- (void)modelUpdate;
- (void)modelOptionUpdate:(uint32_t)options;
- (void)animationLoad;

- (void)modelPartsSelectionChanged;

@end

