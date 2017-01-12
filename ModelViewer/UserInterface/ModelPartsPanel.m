//
//  ModelPartsList.m
//  ModelViewer
//
//  Created by middleware on 1/7/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "ModelPartsPanel.h"
#import "NuoMesh.h"
#import "ModelOptionUpdate.h"





@interface ModelBoolView : NSButton

@end




@interface ModelPartsListTable : NSTableView < NSTableViewDataSource, NSTableViewDelegate >


@property (nonatomic, weak) id<ModelOptionUpdate> updateDelegate;
@property (nonatomic, weak) NSArray<NuoMesh*>* mesh;

- (void)cellEnablingChanged:(id)sender;


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

- (void)mouseDown:(NSEvent *)event
{
    [super mouseDown:event];
    
    ModelPartsListTable* table = (ModelPartsListTable*)self.target;
    [table cellEnablingChanged:self];
}

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
        boolView.objectValue = @(_mesh[row].enabled);
        boolView.target = self;
    }
    else if ([tableColumn.identifier isEqualToString:@"name"])
    {
        NSTableCellView* cell = (NSTableCellView*)result;
        NSTextField* textField = cell.textField;
        textField.stringValue = _mesh[row].modelName;
    }
    else
    {
        NSTableCellView* cell = (NSTableCellView*)result;
        NSTextField* textField = cell.textField;
        textField.stringValue = [NSString stringWithFormat:@"%0.3f", _mesh[row].smoothTolerance];
    }
    
    return result;
}


- (void)cellEnablingChanged:(id)sender
{
    NSInteger row = [self rowForView:sender];
    ModelBoolView* enableButton = (ModelBoolView*)sender;
    _mesh[row].enabled = enableButton.state == NSOnState;
    
    [_updateDelegate modelOptionUpdate:nil];
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


- (void)setOptionUpdateDelegate:(id<ModelOptionUpdate>)optionUpdateDelegate
{
    _partsTable.updateDelegate = optionUpdateDelegate;
}




@end
