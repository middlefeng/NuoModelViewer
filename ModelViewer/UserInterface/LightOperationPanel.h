//
//  LightOperationPanel.h
//  ModelViewer
//
//  Created by middleware on 1/7/17.
//  Copyright © 2017 middleware. All rights reserved.
//


#import <Cocoa/Cocoa.h>


@protocol ModelOptionUpdate;




@interface LightOperationPanel : NSView


@property (nonatomic) float lightDensity;

@property (nonatomic, weak) id<ModelOptionUpdate> optionUpdateDelegate;


@end
