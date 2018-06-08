//
//  ModelOperationTexturePopover.m
//  ModelViewer
//
//  Created by dfeng on 10/5/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "ModelOperationTexturePopover.h"
#import "ModelOperationPanel.h"
#import "NuoMeshOptions.h"
#import "ModelOptionUpdate.h"



@interface ModelOperationTexturePopover ()

@property (nonatomic, weak) id<ModelOptionUpdate> updateDelegate;
@property (nonatomic, weak) NSPopover* popover;
@property (nonatomic, weak) ModelOperationPanel* sourcePanel;

@end





@implementation ModelOperationTexturePopover



- (instancetype)initWithPopover:(NSPopover*)popover
                withSourcePanel:(ModelOperationPanel*)sourcePanel
                   withDelegate:(id<ModelOptionUpdate>)delegate
{
    self = [super init];
    if (self)
    {
        _popover = popover;
        _sourcePanel = sourcePanel;
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
    [checkTextureEmbedTrans setButtonType:NSSwitchButton];
    [checkTextureEmbedTrans setTitle:@"Texture Alpha as Transparency"];
    [checkTextureEmbedTrans setFrame:labelFrame];
    [checkTextureEmbedTrans setTarget:self];
    [checkTextureEmbedTrans setAction:@selector(textureEmbedTransChanged:)];
    [self.view addSubview:checkTextureEmbedTrans];

    labelFrame.origin.y -= rowHeight;

    NSButton* checkTextureBump = [NSButton new];
    [checkTextureBump setButtonType:NSSwitchButton];
    [checkTextureBump setTitle:@"Texture Bump"];
    [checkTextureBump setFrame:labelFrame];
    [checkTextureBump setTarget:self];
    [checkTextureBump setAction:@selector(textureBumpChanged:)];
    [self.view addSubview:checkTextureBump];

    if (_sourcePanel.meshOptions.textureEmbeddingMaterialTransparency)
        checkTextureEmbedTrans.state = NSOnState;
    if (_sourcePanel.meshOptions.texturedBump)
        checkTextureBump.state = NSOnState;
}


- (void)textureEmbedTransChanged:(id)sender
{
    NSButton* btn = (NSButton*)sender;
    _sourcePanel.meshOptions.textureEmbeddingMaterialTransparency = ([btn state] == NSOnState);
    
    [_updateDelegate modelUpdate:_sourcePanel.meshOptions];
}


- (void)textureBumpChanged:(id)sender
{
    NSButton* btn = (NSButton*)sender;
    _sourcePanel.meshOptions.texturedBump = ([btn state] == NSOnState);
    
    [_updateDelegate modelUpdate:_sourcePanel.meshOptions];
}


@end
