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
    }
    
    return self;
}



- (void)importAnimation:(NuoLua*)lua forMesh:(NSArray<NuoMesh*>*)mesh
{
    lua->GetField("object", -1);
    {
        size_t size = lua->GetArraySize(-1);
        for (size_t i = 0; i < size; ++i)
        {
            std::string name = lua->GetArrayItemAsString(i + 1, -1);
            NSString* nameStr = [NSString stringWithUTF8String:name.c_str()];
            NSArray<NuoMesh*>* items = [self findMeshIn:mesh byName:nameStr];
            if (items.count > 0)
                [((NSMutableArray*)_mesh) addObjectsFromArray:items];
        }
    }
    lua->RemoveField();
    
    _animationEndPoint = NuoMeshRotation();
    
    lua->GetField("axis", -1);
    {
        _animationEndPoint._axis.x(lua->GetArrayItemAsNumber(1, -1));
        _animationEndPoint._axis.y(lua->GetArrayItemAsNumber(2, -1));
        _animationEndPoint._axis.z(lua->GetArrayItemAsNumber(3, -1));
    }
    lua->RemoveField();
    
    lua->GetField("anchor", -1);
    {
        _animationEndPoint._transformVector.x(lua->GetArrayItemAsNumber(1, -1));
        _animationEndPoint._transformVector.y(lua->GetArrayItemAsNumber(2, -1));
        _animationEndPoint._transformVector.z(lua->GetArrayItemAsNumber(3, -1));
    }
    lua->RemoveField();
    
    _animationEndPoint.SetRadius(lua->GetFieldAsNumber("radius", -1));
}



- (NSArray<NuoMesh*>*)findMeshIn:(NSArray<NuoMesh*>*)mesh byName:(NSString*)name
{
    NSMutableArray* result = [NSMutableArray new];
    
    for (NuoMesh* item in mesh)
    {
        if ([item.modelName isEqualToString:name])
            [result addObject:item];
    }
    
    return result;
}



- (void)setProgress:(float)progress
{
    for (NuoMesh* mesh in _mesh)
    {
        NuoMeshRotation rotation = _animationEndPoint;
        rotation.SetRadius(rotation.Radius() * progress);
        
        [mesh setRotation:rotation];
    }
}



@end
