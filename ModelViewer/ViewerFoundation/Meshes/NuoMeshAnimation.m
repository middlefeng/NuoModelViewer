//
//  NuoMeshAnimation.m
//  ModelViewer
//
//  Created by dfeng on 2/2/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoMeshAnimation.h"
#import "NuoMesh.h"
#import "NuoLua.h"


@implementation NuoMeshAnimation



- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _mesh = [[NSMutableArray alloc] init];
        _progress = 0.0;
    }
    
    return self;
}



- (void)importAnimation:(NuoLua*)lua forMesh:(NSArray<NuoMesh*>*)mesh
{
    [lua getField:@"object" fromTable:-1];
    {
        size_t size = [lua getArraySize:-1];
        for (size_t i = 0; i < size; ++i)
        {
            NSString* name = [lua getArrayItemAsString:i + 1 fromTable:-1];
            NuoMesh* item = [self findMeshIn:mesh byName:name];
            if (item)
                [((NSMutableArray*)_mesh) addObject:item];
        }
    }
    [lua removeField];
    
    _animationEndPoint = [[NuoMeshRotation alloc] init];
    
    [lua getField:@"axis" fromTable:-1];
    {
        _animationEndPoint.xAxis = [lua getArrayItemAsNumber:1 fromTable:-1];
        _animationEndPoint.yAxis = [lua getArrayItemAsNumber:2 fromTable:-1];
        _animationEndPoint.zAxis = [lua getArrayItemAsNumber:3 fromTable:-1];
    }
    [lua removeField];
    
    [lua getField:@"anchor" fromTable:-1];
    {
        _animationEndPoint.x = [lua getArrayItemAsNumber:1 fromTable:-1];
        _animationEndPoint.y = [lua getArrayItemAsNumber:2 fromTable:-1];
        _animationEndPoint.z = [lua getArrayItemAsNumber:3 fromTable:-1];
    }
    [lua removeField];
    
    _animationEndPoint.radius = [lua getFieldAsNumber:@"radius" fromTable:-1];
}



- (NuoMesh*)findMeshIn:(NSArray<NuoMesh*>*)mesh byName:(NSString*)name
{
    for (NuoMesh* item in mesh)
    {
        if ([item.modelName isEqualToString:name])
            return item;
    }
    
    return nil;
}



@end
