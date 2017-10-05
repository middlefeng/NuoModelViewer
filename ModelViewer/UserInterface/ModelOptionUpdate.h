//
//  ModelOptionUpdate.h
//  ModelViewer
//
//  Created by middleware on 1/5/2017.
//  Copyright © 2017 middleware. All rights reserved.
//


@class NuoMeshOption;
@class ModelOperationPanel;
@class LightOperationPanel;



@protocol ModelOptionUpdate

- (void)modelUpdate:(NuoMeshOption*)meshOptions;
- (void)modelOptionUpdate:(ModelOperationPanel*)panel;
- (void)lightOptionUpdate:(LightOperationPanel*)panel;
- (void)animationLoad;

@end

