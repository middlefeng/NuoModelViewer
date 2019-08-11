//
//  LightOperationPanel.h
//  ModelViewer
//
//  Created by middleware on 1/7/17.
//  Copyright © 2017 middleware. All rights reserved.
//


#import <Cocoa/Cocoa.h>


@protocol ModelOptionUpdate;
@class NuoLightSource;




@interface LightOperationPanel : NSView


@property (nonatomic) float lightDensity;
@property (nonatomic) float lightSpecular;

@property (nonatomic) BOOL shadowEnabled;
@property (nonatomic) float shadowSoften;
@property (nonatomic) float shadowOccluderRadius;
@property (nonatomic) float shadowBias;

@property (nonatomic, weak) id<ModelOptionUpdate> optionUpdateDelegate;


- (void)updateControls:(NuoLightSource*)lightSource;

- (void)lightSettingsChange:(id)sender;


@end
