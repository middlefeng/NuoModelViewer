//
//  ModelOperationTexturePopover.m
//  ModelViewer
//
//  Created by dfeng on 10/5/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "ModelOperationTexturePopover.h"
#import "ModelOperationPanel.h"



@interface ModelOperationTexturePopover ()

@end





@implementation ModelOperationTexturePopover
{
    NSPopover* _popover;
    ModelOperationPanel* _sourcePanel;
}



- (instancetype)initWithPopover:(NSPopover*)popover
                withSourcePanel:(ModelOperationPanel*)sourcePanel
{
    self = [super init];
    if (self)
    {
        _popover = popover;
        _sourcePanel = sourcePanel;
    }
    return self;
}


- (void)loadView
{
    self.view = [NSView new];
    self.view.frame = CGRectMake(0, 0, _popover.contentSize.width, _popover.contentSize.height);
    
    CGFloat rowHeight = 22;
    CGFloat rowCoord = rowHeight * 2 + 15;
    
    CGSize viewSize = self.view.bounds.size;
    CGRect labelFrame = CGRectMake(15, 0, viewSize.width, rowCoord);
    labelFrame.origin.y = 12;
    
    NSButton* checkTextureEmbedTrans = [NSButton new];
    [checkTextureEmbedTrans setButtonType:NSSwitchButton];
    [checkTextureEmbedTrans setTitle:@"Texture Alpha as Transparency"];
    [checkTextureEmbedTrans setFrame:labelFrame];
    [checkTextureEmbedTrans setTarget:self];
    [checkTextureEmbedTrans setAction:@selector(textureEmbedTransChanged:)];
    [self.view addSubview:checkTextureEmbedTrans];
    //_checkTextureEmbedTrans = checkTextureEmbedTrans;

    labelFrame.origin.y -= rowHeight;

    NSButton* checkTextureBump = [NSButton new];
    [checkTextureBump setButtonType:NSSwitchButton];
    [checkTextureBump setTitle:@"Texture Bump"];
    [checkTextureBump setFrame:labelFrame];
    [checkTextureBump setTarget:self];
    [checkTextureBump setAction:@selector(textureBumpChanged:)];
    [self.view addSubview:checkTextureBump];
    //_checkTextureBump = checkTextureBump;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}


@end
