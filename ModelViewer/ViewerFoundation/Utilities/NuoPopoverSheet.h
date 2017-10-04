//
//  NuoPopoverSheet.h
//  ModelViewer
//
//  Created by dfeng on 10/4/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class NuoPopoverSheet;


@protocol NuoPopoverSheetDelegate


- (NSViewController*)popoverSheetcontentViewController:(NuoPopoverSheet*)sheet;
- (CGSize)popoverSheetcontentSize:(NuoPopoverSheet*)sheet;


@end




@interface NuoPopoverSheet : NSButton


@property (nonatomic, weak) id<NuoPopoverSheetDelegate> sheetDelegate;
@property (nonatomic, weak, readonly) NSPopover* popover;

- (instancetype)initWithParent:(NSView*)parent;


@end
