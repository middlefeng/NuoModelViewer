//
//  RayTracingOptionsPopover.m
//  ModelViewer
//
//  Created by Dong on 12/8/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "RayTracingOptionsPopover.h"
#import "ModelState.h"
#import "ModelOptionUpdate.h"



@interface RayTracingOptionsPopover ()

@property (nonatomic, weak) id<ModelOptionUpdate> updateDelegate;
@property (nonatomic, weak) NSPopover* popover;
@property (nonatomic, weak) ModelState* modelState;

@end



@implementation RayTracingOptionsPopover


- (instancetype)initWithPopover:(NSPopover*)popover
                 withModelState:(ModelState*)modelState
                   withDelegate:(id<ModelOptionUpdate>)delegate
{
    self = [super init];
    if (self)
    {
        _popover = popover;
        _modelState = modelState;
        _updateDelegate = delegate;
    }
    return self;
}


- (void)loadView
{
    self.view = [NSView new];
    self.view.frame = CGRectMake(0, 0, _popover.contentSize.width, _popover.contentSize.height);
    
    CGFloat rowHeight = 22;
    CGFloat rowCoord = rowHeight + 8;
    
    CGSize viewSize = self.view.bounds.size;
    CGRect labelFrame = CGRectMake(15, 0, viewSize.width, rowHeight);
    labelFrame.origin.y = rowCoord;
    
    NSButton* mipSampling = [NSButton new];
    [mipSampling setButtonType:NSButtonTypeSwitch];
    [mipSampling setTitle:@"Multiple Importance Sampling"];
    [mipSampling setFrame:labelFrame];
    [mipSampling setTarget:self];
    [mipSampling setAction:@selector(textureEmbedTransChanged:)];
    [self.view addSubview:mipSampling];

    labelFrame.origin.y -= rowHeight;

    NSButton* indirectSpecular = [NSButton new];
    [indirectSpecular setButtonType:NSButtonTypeSwitch];
    [indirectSpecular setTitle:@"Indirect Specular"];
    [indirectSpecular setFrame:labelFrame];
    [indirectSpecular setTarget:self];
    [indirectSpecular setAction:@selector(textureBumpChanged:)];
    [self.view addSubview:indirectSpecular];

    /*if (_modelState.modelOptions._textureEmbedMaterialTransparency)
        checkTextureEmbedTrans.state = NSControlStateValueOn;
    if (_modelState.modelOptions._texturedBump)
        checkTextureBump.state = NSControlStateValueOn;*/
}

@end
