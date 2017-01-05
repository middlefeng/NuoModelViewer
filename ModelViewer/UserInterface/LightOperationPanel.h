//
//  ModelOperationPanel.h
//  ModelViewer
//
//  Created by middleware on 9/15/16.
//  Copyright © 2016 middleware. All rights reserved.
//


#import <Cocoa/Cocoa.h>


@protocol ModelOptionUpdate;




@interface LightOperationPanel : NSView


@property (nonatomic, readonly) float lightDensity;

@property (nonatomic, weak) id<ModelOptionUpdate> optionUpdateDelegate;


@end
