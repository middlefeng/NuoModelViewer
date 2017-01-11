//
//  ModelPartsList.m
//  ModelViewer
//
//  Created by middleware on 1/7/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "ModelPartsPanel.h"
#import "NuoMesh.h"





@interface ModelBoolView : NSButton

@end


@implementation ModelBoolView

- (void)setObjectValue:(id)value
{
    bool enabled = [value integerValue] != 0;
    [self setState:enabled ? NSOnState : NSOffState];
}


- (id)objectValue
{
    return @(self.state == NSOnState);
}

@end







@interface ModelPartsListTable : NSTableView < NSTableViewDataSource, NSTableViewDelegate >


@property (nonatomic, weak) NSArray<NuoMesh*>* mesh;


@end


@implementation ModelPartsListTable



- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self setDataSource:self];
        [self setDelegate:self];
    }
    return self;
}



- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _mesh.count;
}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    NSView* result = [self makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    if ([tableColumn.identifier isEqualToString:@"enabled"])
    {
        ModelBoolView* boolView = (ModelBoolView*)result;
        boolView.objectValue = @(true);
    }
    else
    {
        NSTableCellView* cell = (NSTableCellView*)result;
        NSTextField* textField = cell.textField;
        textField.stringValue = _mesh[row].modelName;
    }
    
    return result;
}


@end






@implementation ModelPartsPanel
{
    IBOutlet ModelPartsListTable* _partsTable;
    IBOutlet NSScrollView* _partsList;
}


- (CALayer*)makeBackingLayer
{
    return [CALayer new];
}


- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        [[NSBundle mainBundle] loadNibNamed:@"ModelPartsTableView"
                                      owner:self topLevelObjects:nil];

        [self setWantsLayer:YES];
        [self addSubview:_partsList];
    }
    
    return self;
}



- (void)setFrame:(NSRect)frame
{
    [super setFrame:frame];
    [_partsList setFrame:self.bounds];
}



- (void)viewDidEndLiveResize
{
    [_partsList setFrame:self.bounds];
}



- (void)setMesh:(NSArray<NuoMesh*>*)mesh
{
    [_partsTable setMesh:mesh];
    [_partsTable reloadData];
}



@end
