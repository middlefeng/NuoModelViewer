//
//  ModelOperationTexturePopover.m
//  ModelViewer
//
//  Created by dfeng on 10/5/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "ModelOperationTexturePopover.h"
#import "ModelOperationPanel.h"
#import "ModelState.h"
#import "NuoMeshOptions.h"
#import "ModelOptionUpdate.h"



@interface ModelOperationTexturePopover ()

@property (nonatomic, weak) id<ModelOptionUpdate> updateDelegate;
@property (nonatomic, weak) NSPopover* popover;
@property (nonatomic, weak) ModelState* modelState;

@end





@implementation ModelOperationTexturePopover



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
    
    NSButton* checkTextureEmbedTrans = [NSButton new];
    [checkTextureEmbedTrans setButtonType:NSButtonTypeSwitch];
    [checkTextureEmbedTrans setTitle:@"Texture Alpha as Transparency"];
    [checkTextureEmbedTrans setFrame:labelFrame];
    [checkTextureEmbedTrans setTarget:self];
    [checkTextureEmbedTrans setAction:@selector(textureEmbedTransChanged:)];
    [self.view addSubview:checkTextureEmbedTrans];

    labelFrame.origin.y -= rowHeight;

    NSButton* checkTextureBump = [NSButton new];
    [checkTextureBump setButtonType:NSButtonTypeSwitch];
    [checkTextureBump setTitle:@"Texture Bump"];
    [checkTextureBump setFrame:labelFrame];
    [checkTextureBump setTarget:self];
    [checkTextureBump setAction:@selector(textureBumpChanged:)];
    [self.view addSubview:checkTextureBump];

    if (_modelState.modelOptions._textureEmbedMaterialTransparency)
        checkTextureEmbedTrans.state = NSControlStateValueOn;
    if (_modelState.modelOptions._texturedBump)
        checkTextureBump.state = NSControlStateValueOn;
}


- (void)textureEmbedTransChanged:(id)sender
{
    NSButton* btn = (NSButton*)sender;
    _modelState.modelOptions._textureEmbedMaterialTransparency = ([btn state] == NSControlStateValueOn);
    
    [_updateDelegate modelUpdate];
}


- (void)textureBumpChanged:(id)sender
{
    NSButton* btn = (NSButton*)sender;
    _modelState.modelOptions._texturedBump = ([btn state] == NSControlStateValueOn);
    
    [_updateDelegate modelUpdate];
}


@end
