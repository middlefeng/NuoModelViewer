//
//  ModelPartsList.m
//  ModelViewer
//
//  Created by middleware on 1/7/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "ModelPartsList.h"



@interface ModelPartsListTable : NSTableView

@end


@implementation ModelPartsListTable

@end












@implementation ModelPartsList
{
    ModelPartsListTable* _partsTable;
}


- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _partsTable = [ModelPartsListTable new];
        [self setDocumentView:_partsTable];
    }
    
    return self;
}


@end
