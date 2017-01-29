//
//  LightSource.h
//  ModelViewer
//
//  Created by middleware on 11/19/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LightSource : NSObject

@property (nonatomic, assign) float lightingRotationX;
@property (nonatomic, assign) float lightingRotationY;
@property (nonatomic, assign) float lightingDensity;
@property (nonatomic, assign) float lightingSpacular;

@property (nonatomic, assign) float enableShadow;
@property (nonatomic, assign) float shadowSoften;
@property (nonatomic, assign) float shadowBias;

@end
