//
//  ModelOptionUpdate.h
//  ModelViewer
//
//  Created by middleware on 1/5/2017.
//  Copyright © 2017 middleware. All rights reserved.
//


@class ModelOperationPanel;
@class LightOperationPanel;



@protocol ModelOptionUpdate

- (void)modelUpdate:(ModelOperationPanel*)panel;
- (void)modelOptionUpdate:(ModelOperationPanel*)panel;
- (void)lightOptionUpdate:(LightOperationPanel*)panel;

@end

