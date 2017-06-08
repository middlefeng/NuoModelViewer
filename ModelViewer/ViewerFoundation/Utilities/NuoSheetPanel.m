//
//  BoardSettingPanel.m
//  ModelViewer
//
//  Created by middleware on 6/8/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoSheetPanel.h"



static const float kMargin = 10;
static const float kHorizontalSpacing = 2;
static const float kButtonOKWidth = 80;
static const float kButtonOKHeight = 60;



@interface NuoSheetPanel() <NSWindowDelegate>

@end



@implementation NuoSheetPanel
{
    NSButton* _buttonOK;
    NSButton* _buttonCancel;
}


- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self initControls];
        [self layoutControls];
        [self setDelegate:self];
    }
    return self;
}


- (void)initControls
{
    _rootView = [NSView new];
    [self.contentView addSubview:_rootView];
    
    _buttonOK = [[NSButton alloc] init];
    [_buttonOK setTitle:@"OK"];
    [_buttonOK setBezelStyle:NSRoundedBezelStyle];
    [_buttonOK setControlSize:NSControlSizeRegular];
    [self.contentView addSubview:_buttonOK];
    
    _buttonCancel = [[NSButton alloc] init];
    [_buttonCancel setTitle:@"Cancel"];
    [_buttonCancel setBezelStyle:NSRoundedBezelStyle];
    [_buttonCancel setControlSize:NSControlSizeRegular];
    [self.contentView addSubview:_buttonCancel];
    
    [self setStyleMask:[self styleMask] | NSResizableWindowMask];
}



- (void)layoutControls
{
    NSRect rect = [self.contentView bounds];
    
    NSRect rectButtonOK;
    rectButtonOK.origin.x = rect.size.width - kMargin - kButtonOKWidth;
    rectButtonOK.origin.y = 0;
    rectButtonOK.size = CGSizeMake(kButtonOKWidth, kButtonOKHeight);
    _buttonOK.frame = rectButtonOK;
    [_buttonOK setKeyEquivalent:@"\r"];
    
    NSRect rectButtonCancel;
    rectButtonCancel.origin.x = rect.size.width - kMargin - kButtonOKWidth * 2.0 - kHorizontalSpacing;
    rectButtonCancel.origin.y = 0;
    rectButtonCancel.size = CGSizeMake(kButtonOKWidth, kButtonOKHeight);
    _buttonCancel.frame = rectButtonCancel;
}


- (void)cancelOperation:(id)sender
{
    [_rootWindow endSheet:self];
}


- (void)windowDidResize:(NSNotification *)notification
{
    [self layoutControls];
}


@end
