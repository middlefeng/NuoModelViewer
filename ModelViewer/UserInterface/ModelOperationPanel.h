//
//  ModelOperationPanel.h
//  ModelViewer
//
//  Created by middleware on 9/15/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "NuoRoundedView.h"
#import "NuoTypes.h"




@class ModelOperationPanel;
@class NuoMeshOption;



@protocol ModelOptionUpdate

- (void)modelUpdate:(ModelOperationPanel*)panel;
- (void)modelOptionUpdate:(ModelOperationPanel*)panel;

@end




@interface ModelOperationPanel : NuoRoundedView


@property (nonatomic, strong) NuoMeshOption* meshOptions;

@property (nonatomic, assign) BOOL cullEnabled;

@property (nonatomic, assign) float fieldOfViewRadian;

@property (nonatomic, assign) float ambientDensity;

@property (nonatomic, assign) BOOL showLightSettings;

@property (nonatomic, weak) id<ModelOptionUpdate> optionUpdateDelegate;


- (void)addCheckbox;

@end
