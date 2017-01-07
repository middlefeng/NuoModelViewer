//
//  NotationRenderer.h
//  ModelViewer
//
//  Created by dfeng on 11/8/16.
//  Copyright © 2016 middleware. All rights reserved.
//



#import "NuoIntermediateRenderPass.h"


@class LightSource;
@class NuoLua;


@interface NotationRenderer : NuoIntermediateRenderPass


@property (nonatomic, readonly) NSArray<LightSource*>* lightSources;

@property (nonatomic, assign) float notationWidthCap;
@property (nonatomic, assign) CGRect notationArea;


// retrieve the currently-selected description

@property (nonatomic, readonly) LightSource* selectedLightSource;


- (void)selectCurrentLightVector:(CGPoint)point;
- (void)importScene:(NuoLua*)lua;


// manipulator to the current selected light source

- (void)setRotateX:(float)rotateX;
- (void)setRotateY:(float)rotateY;
- (void)setDensity:(float)density;
- (void)setSpacular:(float)spacular;


@end
