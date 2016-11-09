//
//  NotationRenderer.m
//  ModelViewer
//
//  Created by dfeng on 11/8/16.
//  Copyright © 2016 middleware. All rights reserved.
//


#import "NotationRenderer.h"

#import "NuoMesh.h"

#include "NuoModelArrow.h"
#include <memory>


@interface NotationRenderer()

@property (nonatomic, strong) NSArray<id<MTLBuffer>>* uniformBuffers;
@property (nonatomic, assign) NSInteger bufferIndex;

@property (nonatomic, strong) NuoMesh* lightVector;

@end



@implementation NotationRenderer


- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    self = [super initWithDevice:device];
    
    if (self)
    {
        PNuoModelArrow arrow = std::make_shared<NuoModelArrow>(2, 0.3, 0.8, 0.5);
        arrow->CreateBuffer();
        
        _lightVector = [[NuoMesh alloc] initWithDevice:self.device
                                    withVerticesBuffer:arrow->Ptr() withLength:arrow->Length()
                                           withIndices:arrow->IndicesPtr() withLength:arrow->IndicesLength()];
    }
    
    return self;
}


@end
