//
//  AppPreferences.m
//  ModelViewer
//
//  Created by Dong on 11/27/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "AppPreferences.h"



@implementation AppPreferences
{
    NSTextField* _labelRenderTime;
    NSTextField* _fieldRenderTime;
    NSTextField* _labelPauseTime;
    NSTextField* _fieldPauseTime;
}


- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.title = @"Preferences";
        
        [self setShowsResizeIndicator:NO];
        [self setStyleMask:NSWindowStyleMaskTitled   |
                           NSWindowStyleMaskClosable];
        
        [self setReleasedWhenClosed: NO];
        [self setContentSize:CGSizeMake(250, 120)];
        
        [self addControls];
    }
    
    return self;
}


- (void)locateRelativeTo:(NSWindow*)window
{
    CGRect frame = window.frame;
    frame.origin.x += 100;
    frame.origin.y += window.frame.size.height - self.frame.size.height - 100;
    
    [self setFrameOrigin:frame.origin];
}



- (void)addControls
{
    CGFloat space = 6.0;
    CGFloat lineSpace = 30.0;
    
    CGRect frame = CGRectMake(15, 20, 160, 20);
    frame.origin.y = self.contentView.frame.size.height - frame.size.height - 30;
    
    CGRect fieldFrame = frame;
    fieldFrame.origin.x = frame.origin.x + frame.size.width + space;
    fieldFrame.size.width = 50;
    fieldFrame.origin.y += 2;
    
    _labelRenderTime = [self createLabel:@"Rendering continously for:"];
    _labelRenderTime.frame = frame;
    
    _fieldRenderTime = [self createField];
    _fieldRenderTime.frame = fieldFrame;
    [_fieldRenderTime setAction:@selector(configureChanged:)];
    [_fieldRenderTime setTarget:self];
    
    frame.origin.y -= lineSpace;
    fieldFrame.origin.y -= lineSpace;
    
    _labelPauseTime = [self createLabel:@"Rendering pause for:"];
    _labelPauseTime.frame = frame;
    
    _fieldPauseTime = [self createField];
    _fieldPauseTime.frame = fieldFrame;
    [_fieldPauseTime setAction:@selector(configureChanged:)];
    [_fieldPauseTime setTarget:self];
}


- (void)setConfiguration:(ModelViewConfiguration*)configuration
{
    _configuration = configuration;
    _fieldRenderTime.stringValue = [NSString stringWithFormat:@"%0.2f", _configuration.renderSchedule._duration];
    _fieldPauseTime.stringValue = [NSString stringWithFormat:@"%0.2f", _configuration.renderSchedule._idle];
}



- (NSTextField*)createLabel:(NSString*)text
{
    NSTextField* label = [[NSTextField alloc] init];
    [label setEditable:NO];
    [label setSelectable:NO];
    [label setBordered:NO];
    [label setBackgroundColor:[NSColor colorWithWhite:0.0 alpha:0.0]];
    [label setStringValue:text];
    [label setAlignment:NSTextAlignmentRight];
    [self.contentView addSubview:label];
    return label;
}



- (NSTextField*)createField
{
    NSTextField* field = [[NSTextField alloc] init];
    [field setEditable:YES];
    [field setSelectable:YES];
    [field setFocusRingType:NSFocusRingTypeNone];
    [field setBezelStyle:NSTextFieldSquareBezel];
    [self.contentView addSubview:field];
    return field;
}


- (void)configureChanged:(id)sender
{
    NuoSchedule schedule;
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    
    schedule._duration = [formatter numberFromString:_fieldRenderTime.stringValue].floatValue;
    schedule._idle = [formatter numberFromString:_fieldPauseTime.stringValue].floatValue;
    _configuration.renderSchedule = schedule;
    
    [_configuration save];
}



@end
